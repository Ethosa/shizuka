# author: Ethosa
import httpclient
import macros
import asyncdispatch
import strutils
import json


type
  LongPollObj[ClientType] = object
    group_id*: int
    client*: ClientType
    server*, ts*, key*: string
    access_token, v: string
    debug*: bool

  LongPollRef* = ref LongPollObj[HttpClient]
  ALongPollRef* = ref LongPollObj[AsyncHttpClient]


proc LongPoll*(client: HttpClient, group_id: int,
               token, version: string, debug: bool): LongPollRef =
  ## Creates a new Sync LongPoll object
  ##
  ## Arguments:
  ##   client -- created HttpClient
  ##   group_id
  LongPollRef(client: client, group_id: group_id, server: "", ts: "", key: "",
    access_token: token, v: version, debug: debug)

proc ALongPoll*(client: AsyncHttpClient, group_id: int,
                token, version: string, debug: bool): ALongPollRef =
  ## Creates a new Async LongPoll object
  ##
  ## Arguments:
  ##   client -- created AsyncHttpClient
  ##   group_id
  ALongPollRef(client: client, group_id: group_id, server: "", ts: "", key: "",
    access_token: token, v: version, debug: debug)

proc update_ts*(lp: LongPollRef | ALongPollRef, mname: string) =
  try:
    var sv = parseJson waitFor lp.client.getContent(mname)
    lp.server = sv["response"]["server"].getStr
    lp.ts = $sv["response"]["ts"]
    lp.key = sv["response"]["key"].getStr
  except:
    lp.update_ts mname

proc update_server*(lp: LongPollRef | ALongPollRef, url: string): JsonNode =
  try:
    result = parseJson waitFor lp.client.getContent(
      url % [lp.server, lp.key, lp.ts])
  except:
    result = lp.update_server url


iterator listen*(lp: LongPollRef | ALongPollRef): JsonNode =
  var
    mname = ""
    url = ""
    key, server, ts: string
  if lp.group_id != 0:
    mname = "groups.getLongPollServer"
    url = "$#?act=a_check&key=$#&ts=$#&wait=25"
  else:
    mname = "messages.getLongPollServer"
    url = "https://$#?act=a_check&key=$#&ts=$#&wait=25&mode=202&version=3"

  mname = "https://api.vk.com/method/" & mname & "?access_token=" & lp.access_token
  mname &= "&v=" & lp.v
  if lp.group_id != 0:
    mname &= "&group_id=" & $lp.group_id

  lp.update_ts mname

  if lp.debug:
    echo "Longpoll start."

  while true:
    var response = lp.update_server url
    if not response.hasKey("updates"):
      lp.update_ts mname
    lp.ts = $response["ts"]

    for update in response["updates"].elems:
      yield update
