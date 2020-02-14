# author: Ethosa
import httpclient
import macros
import asyncdispatch
import json
export json
from strutils import `%`

from utils import encode, log_in
import LongPoll


const
  API_URL: string = "https://api.vk.com/method/"
  API_VERSION: string = "5.103"


type
  VkEvent* = object
    name*: string
    prc*: proc(event: JsonNode)
  VkObj[ClientType, LongPollType] = ref object
    access_token: string
    group_id*: int
    client*: ClientType  ## e.g. HttpClient, AsyncHttpClient.
    debug: bool
    version: string
    longpoll*: LongPollType
    events*: seq[VkEvent]

  SyncVkObj* = VkObj[HttpClient, LongPollRef]
  AsyncVkObj* = VkObj[AsyncHttpClient, ALongPollRef]


proc Vk*(access_token: string, group_id=0,
         debug=false, version=API_VERSION): SyncVkObj =
  ## Auth in VK API via token (user, service or group)
  ##
  ## Arguments:
  ##   access_token -- token for calling VK API methods.
  ##
  ## Keyword Arguments:
  ## -   ``group_id`` -- group id, if available.
  ## -   ``debug`` -- debug log.
  ## -   ``version`` -- API version.
  var client = newHttpClient()
  SyncVkObj(access_token: access_token, group_id: group_id,
     client: client, debug: debug, version: version,
     longpoll: LongPoll(client, group_id, access_token, version, debug),
     events: @[])

proc Vk*(l, p: string, debug=false, version=API_VERSION): SyncVkObj =
  ## Auth in VK, using login and password (only for users).
  ##
  ## Arguments:
  ## -   ``l`` -- VK login.
  ## -   ``p`` -- VK password.
  ##
  ## Keyword Arguments:
  ## -   ``debug`` -- debug log.
  ## -   ``version`` -- API version.
  var token = log_in(newHttpClient(), l, p, version=version)
  Vk(token, debug=debug, version=version)

proc AVk*(access_token: string, group_id=0,
            debug=false, version=API_VERSION): AsyncVkObj =
  ## Auth in VK API via token (user, service or group)
  ##
  ## see also `Vk <#Vk,string,int>`_
  var client = newAsyncHttpClient()
  AsyncVkObj(access_token: access_token, group_id: group_id,
     client: client, debug: debug, version: version,
     longpoll: ALongPoll(client, group_id, access_token, version, debug),
     events: @[])

proc AVk*(l, p: string, debug=false, version=API_VERSION): AsyncVkObj =
  ## Auth in VK, using login and password (only for users).
  ##
  ## see also `Vk <#Vk,string,string>`_
  var token = waitFor log_in(newAsyncHttpClient(), l, p, version=version)
  AVk(token, debug=debug, version=version)

proc call_method*(vk: AsyncVkObj | SyncVkObj, name: string,
                  params: JsonNode = %*{}): Future[JsonNode]
                  {. multisync, discardable .} =
  ## Calls any VK API method.
  ##
  ## Arguments:
  ##   ``name`` -- method name, e.g. "messages.send", "users.get"
  ##
  ## Keyword Arguments:
  ##   ``params`` -- params for method calling.
  params["v"] = %vk.version
  params["access_token"] = %vk.access_token
  result = parseJson await vk.client.postContent(
      API_URL & name & "?" & encode params)

  if vk.debug:
    if result.hasKey("response"):
      echo "[DEBUG]: Successfully called method \"$#\"" % [name]
    else:
      echo:
        "[ERROR]: Error [$#] in called method \"$#\": $#" %
          [result["error"]["error_code"].getStr,
           name, result["error"]["error_msg"].getStr]


macro `~`*(vk: AsyncVkObj | SyncVkObj, body: untyped): untyped =
  ## Provides convenient calling VK API methods.
  ##
  ## Usage with call_method:
  ##   vk.call_method("method", %*{"param1": "value", "param2": 15, ...})
  ##
  ## Usage with this macro:
  ##   vk~method(param1="value", param2=15, ...)
  if body.kind == nnkCall:
    var
      method_name = body[0].toStrLit
      params = newNimNode nnkTableConstr
      value: NimNode
    for arg in body[1..^1]:
      params.add newTree(nnkExprColonExpr, arg[0].toStrLit, arg[1])
    result = newCall(
      "call_method", vk, method_name,
      newCall("%*", params))

macro eventhandler*(vk: AsyncVkObj | SyncVkObj, prc: untyped): untyped =
  ## This pragma will add the transferred function to the list of functions.
  ##
  ## With a new event, the type of which will be equal to the name of the passed function,
  ## the passed function will be called.
  ##
  ## ..code-block::Nim
  ##   vk = Vk(...)
  ##   proc message_new(event: JsonNode) {.eventhadler: vk.} =
  ##     echo event
  ##   vk.start_listen
  if prc.kind == nnkProcDef:
    result = prc.copy()
    let proc_name = $prc[0].toStrLit
    let proc_ident = newIdentNode proc_name
    result = quote do:
      `prc`
      var event = VkEvent(name: `proc_name`, prc: `proc_ident`)
      if event notin `vk`.events:
        `vk`.events.add(event)

macro start_listen*(vk: AsyncVkObj | SyncVkObj): untyped =
  ## Starts longpoll listen.
  ##
  ## calls methods with ``eventhandler`` pragma, if available.
  ##
  ## Usage:
  ##   vk.start_listen
  result = quote do:
    for event in `vk`.longpoll.listen:
      var etype = event["type"].getStr
      for e in `vk`.events:
        if etype == e.name:
          e.prc(event)
          break
