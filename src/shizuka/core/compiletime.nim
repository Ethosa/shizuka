# author: Ethosa
import
  macros


macro `~`*(vk, body: untyped): untyped =
  ## Provides convenient calling VK API methods.
  ##
  ## ## Usage with call_method
  ## .. code-block:: nim
  ##
  ##    vk.callVkMethod("method", %*{"param1": "value", "param2": 15, ...})
  ##
  ## ## Usage with this macro
  ## .. code-block:: nim
  ##
  ##    vk~method(param1="value", param2=15, ...)
  if body.kind == nnkCall:
    var params = newNimNode nnkTableConstr
    for arg in body[1..^1]:
      params.add newTree(nnkExprColonExpr, arg[0].toStrLit, arg[1])
    result = newCall("callVkMethod", vk, body[0].toStrLit, newCall("%*", params))
