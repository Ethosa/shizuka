# author: Ethosa
## Provides working with VK keyboards.
import
  ../core/exceptions,
  button,
  json


type
  KeyboardRef* = ref object
    btn_count: int
    inline, one_time: bool
    max_size*: tuple[w, h, count: int]
    btns*: JsonNode


proc newKeyboard*(inline: bool = true, one_time: bool = false): KeyboardRef =
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
  let last = kb.btns.len() - 1
  if kb.btns[last].len() < kb.max_size[0]:
    kb.btns[last].add(btn.toJson())
  elif kb.btns.len() < kb.max_size[1]:
    kb.btns.add(newJArray())
  else:
    throw(KeyboardError, "Buttons maximum length is 10")


proc `inline`*(kb: KeyboardRef): bool {.inline.} =
  ## Shows the keyboard inside the message.
  kb.inline
proc `inline=`*(kb: KeyboardRef, val: bool) =
  if not kb.one_time:
    kb.inline = val
  else:
    throw(KeyboardError, "inline param isn't available for one_time button.")

proc `one_time`*(kb: KeyboardRef): bool {.inline.} =
  ## Hides the keyboard after the initial use.
  ## This parameter only works for buttons that send a message (type field – text, location).
  ## For open_app and vk_pay type, this parameter is ignored.
  kb.one_time
proc `one_time=`*(kb: KeyboardRef, val: bool) =
  if not kb.inline:
    kb.one_time = val
  else:
    throw(KeyboardError, "one_time param isn't available for inline button.")


proc toJson*(kb: KeyboardRef): JsonNode =
  result = %*{
    "one_time": kb.one_time,
    "inline": kb.inline,
    "buttons": kb.btns
  }

proc `$`*(kb: KeyboardRef): string =
  $kb.toJson()
