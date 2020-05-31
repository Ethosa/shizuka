# --- Test 3. Receiving real-time events --- #
import shizuka

var vk = Vk("...", 123)

for event in vk.longpoll.listen():
  echo event
