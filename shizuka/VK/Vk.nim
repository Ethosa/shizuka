# author: Ethosa
import httpclient
import asyncdispatch
import macros
import json
import strutils

import consts
import utils
import LongPoll
import Uploader


when defined(debug):
  import logging


type
  AVkEvent* = object  ## Object for async eventhandler pragma.
    name*: string
    prc*: proc(event: JsonNode): Future[void]

  VkObj = ref object
    group_id*: int
    access_token: string
    version: string
    client*: AsyncHttpClient  ## e.g. HttpClient, AsyncHttpClient.
    longpoll*: LongPollRef  ## LongPollRef or ALongPollRef.
    uploader*: UploaderObj
    events*: seq[AVkEvent]


proc Vk*(access_token: string, group_id=0, version=VK_API_DEFAULT_VERSION): VkObj =
  ## Auth in VK API via token (user, service or group)
  ##
  ## see also `Vk <#Vk,string,int>`_
  var client = newAsyncHttpClient()
  VkObj(access_token: access_token, group_id: group_id,
     client: client, version: version,
     longpoll: LongPoll(client, group_id, access_token, version),
     events: @[], uploader: Uploader(client, access_token, version))

proc Vk*(l, p: string, version=VK_API_DEFAULT_VERSION): VkObj =
  ## Auth in VK, using login and password (only for users).
  ##
  ## see also `Vk <#Vk,string,string>`_
  var token = waitFor log_in(newAsyncHttpClient(), l, p, version=version)
  Vk(token, version=version)


proc call_method*(vk: VkObj, name: string, params: JsonNode = %*{}): Future[JsonNode] {.async.} =
  ## Calls any VK API method.
  ##
  ## Arguments:
  ## - `name` - method name, e.g. "messages.send", "users.get"
  ## - `params` - params for method calling.
  params["v"] = %vk.version
  params["access_token"] = %vk.access_token
  result = parseJson(await vk.client.postContent(VK_API_URL & name, params.encode()))

  when defined(debug):
    if result.hasKey "response":
      debug("Successfully called method \"$#\"" % [name])
    else:
      let
        msg = result["error"]["error_msg"].getStr()
        code = result["error"]["error_code"].getStr()
      debug("Error " & code & " in called method \"" & name & "\": " & msg)
      debug(result)


# ------------------------ MACROS ------------------------ #

macro `~`*(vk: VkObj, body: untyped): untyped =
  ## Provides convenient calling VK API methods.
  ##
  ## ## Usage with call_method
  ## .. code-block:: nim
  ##
  ##    vk.call_method("method", %*{"param1": "value", "param2": 15, ...})
  ##
  ## ## Usage with this macro
  ## .. code-block:: nim
  ##
  ##    vk~method(param1="value", param2=15, ...)
  if body.kind == nnkCall:
    var params = newNimNode nnkTableConstr
    for arg in body[1..^1]:
      params.add newTree(nnkExprColonExpr, arg[0].toStrLit, arg[1])
    result = newCall("call_method", vk, body[0].toStrLit, newCall("%*", params))


macro eventhandler*(vk: VkObj, prc: untyped): untyped =
  ## This pragma will add the transferred function to the list of functions.
  ##
  ## With a new event, the type of which will be equal to the name of the passed function,
  ## the passed function will be called.
  ##
  ## .. code-block:: nim
  ##
  ##    var vk = Vk(...)
  ##    proc message_new(event: JsonNode) {.async, eventhadler: vk.} =
  ##      echo event
  ##    vk.start_listen
  if prc.kind == nnkProcDef:
    result = prc.copy
    let
      proc_name = $prc[0].toStrLit
      proc_ident = newIdentNode proc_name
    result = quote do:
      `prc`
      var event = AVkEvent(name: `proc_name`, prc: `proc_ident`)
      if event notin `vk`.events:
        `vk`.events.add(event)


macro `@`*(vk: VkObj, prc, body: untyped): untyped =
  ## This pragma provides convenient async eventhandler pragma usage.
  ##
  ## .. code-block:: nim
  ##
  ##    var vk = Vk(...)
  ##    vk@message_new(event):
  ##      echo event
  if prc.kind == nnkCall:
    let
      proc_name = prc[0]
      arg = prc[1]
      string_name = $proc_name
    result = quote do:
      var event = AVkEvent(
        name: `string_name`,
        prc: proc(`arg`: JsonNode) {.async.} =
          `body`)
      if event notin `vk`.events:
        `vk`.events.add(event)


macro start_listen*(vk: VkObj): untyped =
  ## Starts longpoll listen.
  ##
  ## calls methods with async `eventhandler` pragma, if available.
  ##
  ## ## Usage
  ## .. code-block:: nim
  ##
  ##    vk.start_listen()
  result = quote do:
    proc vk_start_listen_proc() {.async.} =
      for event in `vk`.longpoll.listen:
        for e in `vk`.events:
          if event["type"].getStr == e.name:
            await e.prc(event)
            break
    waitFor vk_start_listen_proc()
