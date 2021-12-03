# author: Ethosa
## Provides working with VK keyboards.
import
  ../core/exceptions,
  ../core/enums,
  keyboard_button,
  asyncdispatch,
  json


type
  KeyboardRef* = ref object
    btn_count: int
    inline*, one_time*: bool
    max_size*: tuple[w, h, count: int]
    btns*: JsonNode


proc newKeyboard*(inline: bool = true, one_time: bool = true): KeyboardRef =
  result = KeyboardRef(one_time: one_time, inline: inline, btns: %*[[]])
  if inline:
    result.max_size = (5, 6, 10)
  else:
    result.max_size = (5, 10, 40)


proc addLine*(kb: KeyboardRef) =
  if kb.btns.len() < kb.max_size[1]:
    kb.btns.add(newJArray())
  else:
    throw(KeyboardError, "Buttons maximum length is 10")


proc addButton*(kb: KeyboardRef, btn: ButtonObj) =
  if kb.btn_count >= kb.max_size[2]:
    throw(KeyboardError, "Maximum buttons count is " & $kb.max_size[2])
  if kb.btns.getElems[^1].len() < kb.max_size[0]:
    kb.btns.getElems[^1].add(btn.toJson())
  elif kb.btns.len() < kb.max_size[1]:
    kb.btns.add(newJArray())
  else:
    throw(KeyboardError, "Buttons maximum length is 10")


proc toJson*(kb: KeyboardRef): JsonNode =
  result = %*{
    "one_time": kb.one_time,
    "inline": kb.inline,
    "buttons": kb.btns
  }

proc `$`*(kb: KeyboardRef): string =
  $kb.toJson()
