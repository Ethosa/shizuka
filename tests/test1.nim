import
  shizuka,
  unittest,
  parsecfg,
  strutils

let
  cfg = loadConfig("secret.cfg")
  user_token = cfg.getSectionValue("vkuser","user_token")
  group_token = cfg.getSectionValue("vkgroup","group_token")
  group_id = cfg.getSectionValue("vkgroup","group_id").parseUint()


proc main {.async.} =
  var
    vk: VkRef
    lp: LongpollRef
  suite "User":
    test "auth":
      vk = newVk(user_token)
  
    test "callVkMethod test":
      discard await vk.callVkMethod("messages.getConversations", %*{"fields": ""})

    test "~ macro test":
      discard await vk~messages.getConversations(fields="")

    test "longpoll test":
      lp = newLongpoll(vk)

    test "handle events":
      vk@message_new(event):
        echo event
        lp.close()
      await lp.run()

  
  suite "Group":
    test "auth":
      vk = newVk(group_token, group_id)
  
    test "callVkMethod test":
      discard await vk.callVkMethod("messages.getConversations", %*{"fields": ""})

    test "~ macro test":
      discard await vk~messages.getConversations(fields="")

    test "longpoll test":
      lp = newLongpoll(vk)

    test "handle events":
      vk@message_new(event):
        echo event
        lp.close()
      await lp.run()
  

when isMainModule:
  waitFor main()
