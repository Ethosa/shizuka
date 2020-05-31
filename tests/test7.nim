# --- Test 7. upload message photo. format proc test. --- #
import asyncdispatch
import shizuka

var vk = Vk("89123456789", "qwertyuiop")

var response = waitFor vk.uploader.message_photo(@["C://Users/Admin/Desktop/nim.png"], 2000000035)
echo response
var photo = vk.uploader.format response
echo photo

discard waitFor vk~messages.send(peer_id=2_000_000_035, attachment=photo, random_id=123)
