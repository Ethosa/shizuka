# --- Test 8. add 2 and more buttons. --- #
import shizuka

var keyboard = Keyboard(one_time=true)

var button = createButton(params = %*{
  "label": "Hello from Nim"
})

keyboard.add(button, button, button, button)

echo keyboard
