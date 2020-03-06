# author: Ethosa
# autocalling procs
import asyncdispatch
import shizuka

var vk = Vk(access_token="...",
            group_id=123123123, debug=true)


proc message_new(event: JsonNode) {. async, eventhandler: vk .} =
  echo "NEW MESSAGE :p"
  echo event

proc message_edit(event: JsonNode) {. async, eventhandler: vk .} =
  echo event

vk.start_listen
