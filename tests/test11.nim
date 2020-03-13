# author: Ethosa
# convenient event handlers.
import shizuka

var vk = Vk("8123456789", "asdasdasd", debug=true)

vk@message_new(event):
  echo event

vk.start_listen
