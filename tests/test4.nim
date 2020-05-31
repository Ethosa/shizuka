# --- Test 4. autocalling procs --- #
import shizuka

var vk = Vk("...", 123)


proc message_new(event: JsonNode) {.async, eventhandler: vk .} =
  echo "NEW MESSAGE :p"
  echo event

proc message_edit(event: JsonNode) {.async, eventhandler: vk .} =
  echo event

vk.start_listen()
