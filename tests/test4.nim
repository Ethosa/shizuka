# author: Ethosa
# Sync user log in.
from asyncdispatch import waitFor
import shizuka

var vk = AVk("88005553535", "qwerty", debug=true)

echo waitFor vk~users.get(user_ids="akihayase")
echo waitFor vk~users.get(user_ids=1)
echo waitFor vk~users.get(user_ids=123123)
