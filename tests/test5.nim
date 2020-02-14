# author: Ethosa
# Receiving real-time events
import asyncdispatch
import shizuka

var vk = AVk(access_token="...", group_id=123, debug=true)

for event in vk.longpoll.listen():
  echo event
