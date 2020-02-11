# author: Ethosa
import httpclient
import macros
import asyncdispatch
import json
export json
from strutils import `%`

from utils import encode, log_in


const API_URL: string = "https://api.vk.com/method/"


type
  VkObj[ClientType] = ref object
    access_token: string
    group_id: int
    client: ClientType  ## e.g. HttpClient, AsyncHttpClient.
    debug: bool
    version: string

  SyncVkObj* = VkObj[HttpClient]
  AsyncVkObj* = VkObj[AsyncHttpClient]


proc Vk*(access_token: string, group_id=0,
         debug=false, version="5.103"): SyncVkObj =
  ## Auth in VK API via token (user, service or group)
  ##
  ## Arguments:
  ##   access_token -- token for calling VK API methods.
  ##
  ## Keyword Arguments:
  ##   group_id -- group id, if available.
  ##   debug -- debug log.
  ##   version -- API version.
  SyncVkObj(access_token: access_token, group_id: group_id,
     client: newHttpClient(), debug: debug, version: version)

proc Vk*(l, p: string, debug=false, version="5.103"): SyncVkObj =
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
            debug=false, version="5.103"): AsyncVkObj =
  ## Auth in VK API via token (user, service or group)
  ## see ``Vk``
  AsyncVkObj(access_token: access_token, group_id: group_id,
     client: newAsyncHttpClient(), debug: debug, version: version)

proc AVk*(l, p: string, debug=false, version="5.103"): AsyncVkObj =
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
  ##   vk.call_method("method", {"param1": "value", ...})
  ##
  ## Usage with this macro:
  ##   vk~method(param1="value", ...)
  if body.kind == nnkCall:
    var
      vk = vk
      method_name = body[0].toStrLit
      params = %*{}
      i = 0
    for arg in body.children:
      if i == 0:
        inc i
        continue
      params[$arg[0]] = % $arg[1]
    result = newCall(
      "call_method", vk, method_name,
      newCall("parseJson", newLit($params)))
