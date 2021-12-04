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

  user_id = 556962840
  album_id = 280374505


proc main {.async.} =
  var
    vk: VkRef
    user: VkRef
    lp: LongpollRef
    upl: UploaderRef
    keyboard: KeyboardRef

  suite "User":
    test "auth":
      user = newVk(user_token)
  
    test "callVkMethod test":
      discard await user.callVkMethod("messages.getConversations", %*{"fields": ""})

    test "~ macro test":
      discard await user~messages.getConversations(fields="")

    test "longpoll test":
      lp = newLongpoll(user)

    test "handle events":
      user@message_new(event):
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

    test "template test":
      upl = user.newUploader()
      var
        tmpl = newTemplate()
        photos = await upl.photoMessage(@["assets/nimlogo.png"], user_id)
        elem = newTElement("title", "description", photos.getAttachId())
        btn1 = newButton(ButtonText)
      btn1.label = "hi"
      elem.addButton(btn1)
      tmpl.addElement(elem)
      echo tmpl

    test "uploader test":
      var resp = await upl.audio(@["assets/drunk and nasty.mp3"], "ethosa", "ethososa")
      echo resp

  
  suite "Group":
    test "auth":
      vk = newVk(group_token, group_id)
      upl = user.newUploader()
  
    test "callVkMethod test":
      discard await vk.callVkMethod("messages.getConversations", %*{"fields": ""})

    test "~ macro test":
      discard await vk~messages.getConversations(fields="")

    test "longpoll test":
      lp = newLongpoll(vk)

    test "handle events":
      vk@message_new(event):
        discard await vk~messages.send(peer_id=user_id,
                         keyboard=keyboard.toJson(), random_id=0, message="hi")
        test "upload photos in message test":
          var photos = await upl.photoMessage(@["assets/nimlogo.png", "assets/nimlogo.png"], user_id)
          echo photos
          discard await vk~messages.send(peer_id=user_id, random_id=0, message="hi", attachment=photos)
        lp.close()
      await lp.run()

    test "upload photo in album test":
      var photos = await upl.photoAlbum(@["assets/nimlogo.png"], album_id, group_id, "nim logo ._.")
      echo photos
  

when isMainModule:
  waitFor main()
