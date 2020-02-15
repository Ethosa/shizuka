# author: Ethosa
# upload message photo
import asyncdispatch
import shizuka

var vk = AVk("89123456789", "qwertyuiop", debug=true)

var response = waitFor vk.uploader.message_photo(@["C://Users/Admin/Desktop/nim.png"], 2000000035)
echo response
var photo = "photo" & $response["response"][0]["owner_id"] & "_" & $response["response"][0]["id"]
echo photo

discard waitFor vk~messages.send(peer_id=2_000_000_035, attachment=photo, random_id=123)
