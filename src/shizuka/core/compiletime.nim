# author: Ethosa
import
  macros,
  ../vk/vk


macro `~`*(vk, body: untyped): untyped =
  ## Provides convenient calling VK API methods.
  ##
  ## ## Usage with callVkMethod
  ## ```
  ## vk.callVkMethod("method", %*{"param1": "value", "param2": 15, ...})
  ## ```
  ##
  ## ## Usage with this macro
  ## ```
  ## vk~method(param1="value", param2=15, ...)
  ## ```
  if body.kind == nnkCall:
    var params = newNimNode nnkTableConstr
    for arg in body[1..^1]:
      params.add newTree(nnkExprColonExpr, arg[0].toStrLit, arg[1])
    result = newCall("callVkMethod", vk, body[0].toStrLit, newCall("%*", params))

macro `@`*(vk: VkRef, event, body: untyped): untyped =
  ## Provides convenient handling longpoll events.
  ##
  ## ## Usage with lambda
  ## ```
  ## vk.events[event_name] =
  ##   proc(eent: JsonNode) =
  ##     body
  ## ```
  ##
  ## ## Usage with this macro
  ## ```
  ## vk@message_new(event):
  ##   echo event
  ## ```
  if event.kind == nnkCall:
    let
      arg = event[1]
      event_name = $event[0]
    result = quote do:
      var vkevent = VkEvent(
        name: `event_name`,
        action: proc(`arg`: JsonNode) {.async.} = `body`)
      if vkevent notin `vk`.events:
        `vk`.events.add(vkevent)
