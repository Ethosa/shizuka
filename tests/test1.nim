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
    upl: UploaderRef
    keyboard: KeyboardRef

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

    test "keyboard button test":
      var
        btn_link = newButton(ButtonLink)
        btn_text = newButton(ButtonText, ColorNegative)
      echo btn_link
      echo btn_text

    test "keyboard test":
      var
        btn1 = newButton(ButtonText)
        callback_button = newButton(ButtonCallback, ColorPositive)
      btn1.label = "hi"
      callback_button.label = "callback"
      keyboard = newKeyboard()
      keyboard.addButton(btn1)
      keyboard.addButton(callback_button)
      echo keyboard

    test "uploader test":
      upl = vk.newUploader()
      var resp = await upl.audio(@["assets/drunk and nasty.mp3"], "ethosa", "sososa")
      echo resp

  
  suite "Group":
    test "auth":
      vk = newVk(group_token, group_id)
      upl = vk.newUploader()
  
    test "callVkMethod test":
      discard await vk.callVkMethod("messages.getConversations", %*{"fields": ""})

    test "~ macro test":
      discard await vk~messages.getConversations(fields="")

    test "longpoll test":
      lp = newLongpoll(vk)

    test "handle events":
      vk@message_new(event):
        discard await vk~messages.send(peer_id=event["object"]["message"]["peer_id"],
                         keyboard=keyboard.toJson(), random_id=0, message="hi")
        lp.close()
      await lp.run()

    test "upload pgotos in message test":
      var photos = await upl.photosMessage(@["assets/nimlogo.png", "assets/nimlogo.png"], 556962840)
      discard await vk~messages.send(peer_id=556962840, random_id=0, message="hi", attachment=photos)
  

when isMainModule:
  waitFor main()
