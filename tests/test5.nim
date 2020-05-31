# --- Test 5. Sending keyboard --- #
import shizuka

var vk = Vk("...", 123)

var keyboard = Keyboard(one_time=true)
keyboard.add(create_button(params = %*{"label": "hello :)"}))


proc message_new(e: JsonNode) {. async, eventhandler: vk .} =
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


vk.start_listen()
