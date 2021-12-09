# author: Ethosa
## Provides working with Longpoll.
##
## ## Examples
## ### Vk events
## ```nim
## var
##   vk = newVk("myAccessToken")
##   lp = newLongpoll(vk)
## 
## vk@message_new(event):
##   echo event
## ```
##
## ### `listen iterator <#listen.i,LongpollRef>`_
## ```nim
## for event in lp.listen():
##   echo event
## ```
import
  ../core/compiletime,
  ../core/exceptions,
  ../core/consts,
  ../core/enums,
  ../private/user_event,
  httpclient,
  strutils,
  vk


type
  LongpollRef* = ref object
    vk: VkRef
    is_continued: bool
    client: AsyncHttpClient
    url: string
    ts*, key*, server*: string


proc extractTs(ts: JsonNode): string =
  if ts.kind == JInt:
    $ts
  else:
    ts.getStr()

proc updateTs(lp: LongpollRef): Future[JsonNode] {.async.} =
  var response = await lp.client.getContent(lp.url % [lp.server, lp.key, $lp.ts])
  result = parseJson(response)
  lp.ts = extractTs(result["ts"])

  if "updates" in result:
    return result["updates"]

  var failed = result["failed"].getInt()
  case failed
  of 1:
    throw(LongpollError, "the event history is outdated or was partially lost, the application can receive events further using the new `ts` value from the response.")
  of 2:
    throw(LongpollError, "the key has expired, you need to get the key again using the groups.getLongPollServer method.")
  of 3:
    throw(LongpollError, "information has been lost, you need to request new keys and ts using the groups.getLongPollServer method.")
  else:
    throw(LongpollError, "Unknown error: " & $failed)


proc newLongpoll*(vk: VkRef): LongpollRef =
  ## Creates a new Longpoll object.
  result = LongpollRef(vk: vk, client: newAsyncHttpClient(), is_continued: true)
  var response: JsonNode
  case vk.kind
  of VkGroup:
    response = waitFor vk~groups.getLongPollServer(group_id=vk.group_id)
    result.url = BOT_LONGPOLL_URL
  of VkUser:
    response = waitFor vk~messages.getLongPollServer(lp_version=3)
    result.url = USER_LONGPOLL_URL
  result.ts = extractTs(response["response"]["ts"])
  result.key = response["response"]["key"].getStr()
  result.server = response["response"]["server"].getStr()


proc close*(lp: LongpollRef) =
  ## Closes current longpoll.
  lp.is_continued = false


iterator listen*(lp: LongpollRef): JsonNode =
  ## Starts longpoll events handling.
  ##
  ## ```nim
  ## for event in lp.listen():
  ##   echo event
  ## ```
  lp.is_continued = true
  while lp.is_continued:
    let updates = waitFor lp.updateTs()
    for update in updates.items():
      yield if lp.vk.kind == VkUser: parseEvent(update) else: update

proc run*(lp: LongpollRef) {.async.} =
  ## Starts longpoll events handling.
  for event in lp.listen():
    for vkevent in lp.vk.events:
      if vkevent.name == event["type"].getStr():
        await vkevent.action(event)
