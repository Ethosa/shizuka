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
  VkObj[ClientType, LongPollType] = ref object
    access_token: string
    group_id*: int
    client*: ClientType  ## e.g. HttpClient, AsyncHttpClient.
    debug: bool
    version: string
    longpoll*: LongPollType

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
  ##   group_id -- group id, if available.
  ##   debug -- debug log.
  ##   version -- API version.
  var client = newHttpClient()
  SyncVkObj(access_token: access_token, group_id: group_id,
     client: client, debug: debug, version: version,
     longpoll: LongPoll(client, group_id, access_token, version,
                        debug))

proc Vk*(l, p: string, debug=false, version=API_VERSION): SyncVkObj =
  ## Auth in VK, using login and password (only for users).
  ##
  ## Arguments:
  ##   l -- VK login.
  ##   p -- VK password.
  ##
  ## Keyword Arguments:
  ##   debug -- debug log.
  ##   version -- API version.
  var token = log_in(newHttpClient(), l, p, version=version)
  Vk(token, debug=debug, version=version)

proc AVk*(access_token: string, group_id=0,
            debug=false, version=API_VERSION): AsyncVkObj =
  ## Auth in VK API via token (user, service or group)
  ## see ``Vk``
  var client = newAsyncHttpClient()
  AsyncVkObj(access_token: access_token, group_id: group_id,
     client: client, debug: debug, version: version,
     longpoll: ALongPoll(client, group_id, access_token, version,
                         debug))

proc AVk*(l, p: string, debug=false, version=API_VERSION): AsyncVkObj =
  ## Auth in VK, using login and password (only for users).
  ## see ``Vk``
  var token = waitFor log_in(newAsyncHttpClient(), l, p, version=version)
  AVk(token, debug=debug, version=version)

proc call_method*(vk: AsyncVkObj | SyncVkObj, name: string,
                  params: JsonNode = %*{}): Future[JsonNode]
                  {. multisync, discardable .} =
  ## Calls any VK API method.
  ##
  ## Arguments:
  ##   name -- method name, e.g. "messages.send", "users.get"
  ##
  ## Keyword Arguments:
  ##   params -- params for method calling.
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
      params = %*{}
      value: NimNode
    for arg in body[1..^1]:
      if arg[1].kind == nnkNilLit:
        value = newLit("null")
      elif arg[1].kind != nnkStrLit:
        value = arg[1].toStrLit
      else:
        value = arg[1]
      params[$arg[0]] = % $value
    result = newCall(
      "call_method", vk, method_name,
      newCall("parseJson", newLit($params)))
