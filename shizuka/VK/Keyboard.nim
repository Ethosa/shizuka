# author: Ethosa
import json


type
  KeyboardObj = object
    inline*, one_time*: bool
    max_h*, max_w*: int
    buttons*: JsonNode
  KeyboardRef* = ref KeyboardObj


proc `$`*(keyboard: KeyboardRef): string =
  "keyboard " & $keyboard.buttons

proc Keyboard*(one_time=false, inline=false): KeyboardRef =
  ## Creates a new KeyboardRef object.
  ##
  ## Keyword Arguments:
  ## -   ``one_time`` - hide keyboard one new message or when any button clicked.
  ## -   ``inline`` - show keyboard in message
  KeyboardRef(
    inline: inline, one_time: one_time, buttons: %*[[]],
    max_w: if inline: 3 else: 4, max_h: if inline: 3 else: 10)

proc add_line*(keyboard: KeyboardRef) =
  ## Adds a new line in keyboard, if available.
  if keyboard.buttons.len < keyboard.max_h:
    keyboard.buttons.add(%*[])

proc add*(keyboard: KeyboardRef, button: JsonNode) =
  ## Adds a new button in keyboard.
  ##
  ## Arguments:
  ## -   ``button`` - created button.
  if keyboard.buttons.len < keyboard.max_h:
    var last_index = keyboard.buttons.len - 1
    if keyboard.buttons[last_index].len < keyboard.max_w:
      if button["action"]["type"].getStr == "text":
        keyboard.buttons[last_index].add button
      else:
        if keyboard.buttons[last_index].len > 0:
          keyboard.add_line
        keyboard.buttons[last_index].add button
        keyboard.add_line
    else:
      keyboard.add_line
      keyboard.add button

proc add*(keyboard: KeyboardRef, buttons: varargs[JsonNode]) =
  for button in buttons:
    keyboard.add button

proc compile*(keyboard: KeyboardRef): JsonNode =
  ## Compiles keyboard for send to the message.
  result = %*{"buttons" : keyboard.buttons}
  if keyboard.inline:
    result["inline"] = %true
  else:
    result["one_time"] = %keyboard.one_time
