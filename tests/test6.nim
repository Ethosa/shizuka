# author: Ethosa
# autocalling procs
import shizuka

var vk = Vk(access_token="...",
            group_id=123123123, debug=true)


proc message_new(event: JsonNode) {. eventhandler: vk .} =
  echo "NEW MESSAGE :p"
  echo event

proc message_edit(event: JsonNode) {. eventhandler: vk .} =
  echo event

vk.start_listen
