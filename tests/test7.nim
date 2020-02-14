# author: Ethosa
# sending keyboard
import asyncdispatch
import shizuka

var vk = Vk(access_token="...",
            group_id=123123, debug=true)

var keyboard = Keyboard(one_time=true)
keyboard.add(create_button(params = %*{"label": "hello :)"}))


proc message_new(e: JsonNode) {. eventhandler: vk .} =
  echo "NEW MESSAGE :p"
  var
    event = e["object"]["message"]  # for API version 5.103 or later.
    text = event["text"].getStr

  if text == "keyboard":
    var response = vk~messages.send(
      message="hello",
      keyboard=keyboard.compile,
      peer_id=event["peer_id"].num,
      random_id=123123
    )
    echo response


vk.start_listen
