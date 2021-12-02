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
  suite "User":
  
    var vk: Vk
    
    test "auth":
      vk = newVk(user_token)
  
    test "callVkMethod test":
      discard await vk.callVkMethod("messages.getConversations", %*{"fields": ""})

    test "~ macro test":
      discard await vk~messages.getConversations(fields="")
  
  
  suite "Group":
  
    var vk: Vk
    
    test "auth":
      vk = newVk(group_token, group_id)
  
    test "callVkMethod test":
      discard await vk.callVkMethod("messages.getConversations", %*{"fields": ""})

    test "~ macro test":
      discard await vk~messages.getConversations(fields="")
  

when isMainModule:
  waitFor main()
