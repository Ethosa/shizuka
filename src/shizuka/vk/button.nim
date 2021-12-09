# author: Ethosa
## Provides working with keyboard buttons.
import
  ../core/exceptions,
  ../core/enums,
  json


type
  ButtonObj* = object
    case btn_type*: ButtonAction
    of ButtonText, ButtonCallback:
      text_label: string
    of ButtonLink:
      link_label: string
      link*: string
    of ButtonPay:
      pay_hash: string
    of ButtonApp:
      app_label: string
      app_hash: string
      app_id*, owner_id*: int
    of ButtonLocation:
      discard
    payload*: string  ## additional information. It is returned in the messages_new event inside the payload property
    color*: ButtonColor  ## Button color. This parameter is used only for buttons with the text type. 


proc newButton*(action: ButtonAction = ButtonText,
                color: ButtonColor = ColorPrimary): ButtonObj =
  case action
  of ButtonText, ButtonCallback:
    ButtonObj(btn_type: action, text_label: "", payload: "", color: color)
  of ButtonLink:
    ButtonObj(btn_type: action, link: "", link_label: "",
              payload: "", color: color)
  of ButtonPay:
    ButtonObj(btn_type: action, pay_hash: "", payload: "", color: color)
  of ButtonApp:
    ButtonObj(btn_type: action, app_id: 0, owner_id: 0,
              app_label: "", app_hash: "", payload: "", color: color)
  of ButtonLocation:
    ButtonObj(btn_type: action, payload: "", color: color)



proc `label`*(btn: ButtonObj): string =
  ## button text. It is sent by the user to the chat after pressing
  case btn.btn_type
  of ButtonText, ButtonCallback:
    btn.text_label
  of ButtonLink:
    btn.link_label
  of ButtonApp:
    btn.app_label
  else:
    throw(KeyboardError, "Button " & $btn.btn_type & " haven't contains label.")

proc `label=`*(btn: var ButtonObj, value: string) =
  case btn.btn_type
  of ButtonText, ButtonCallback:
    btn.text_label = value
  of ButtonLink:
    btn.link_label = value
  of ButtonApp:
    btn.app_label = value
  else:
    throw(KeyboardError, "Button " & $btn.btn_type & " haven't contains label.")

proc `hash`*(btn: ButtonObj): string =
  ## if btn type ...
  ##   is App:
  ##     hash for navigation inside the app;
  ##     is sent inside the launch parameters string after the # symbol
  ##   is Pay:
  ##     a string containing VK Pay payment parameters and the id of the app
  ##     in the aid parameter, separated by &.
  ##     Example: ``action=transfer-to-group&group_id=1&aid=10``
  case btn.btn_type
  of ButtonPay:
    btn.pay_hash
  of ButtonApp:
    btn.app_hash
  else:
    throw(KeyboardError, "Button " & $btn.btn_type & " haven't contains hash.")

proc `hash=`*(btn: var ButtonObj, value: string) =
  case btn.btn_type
  of ButtonPay:
    btn.pay_hash = value
  of ButtonApp:
    btn.app_hash = value
  else:
    throw(KeyboardError, "Button " & $btn.btn_type & " haven't contains hash.")


proc `type`*(btn: ButtonObj): string =
  $btn.btn_type

proc toJson*(btn: ButtonObj): JsonNode =
  result = %*{
    "action": {"type": $btn.btn_type, "payload": btn.payload}
  }
  case btn.btn_type
  of ButtonText, ButtonCallback:
    result["action"]["label"] = newJString(btn.text_label)
    result["color"] = newJString($btn.color)
  of ButtonLink:
    result["action"]["label"] = newJString(btn.link_label)
    result["action"]["link"] = newJString(btn.link)
  of ButtonPay:
    result["action"]["hash"] = newJString(btn.pay_hash)
  of ButtonApp:
    result["action"]["label"] = newJString(btn.app_label)
    result["action"]["hash"] = newJString(btn.app_hash)
    result["action"]["app_id"] = newJInt(btn.app_id)
    result["action"]["owner_id"] = newJInt(btn.owner_id)
  of ButtonLocation:
    discard

proc `$`*(btn: ButtonObj): string =
  $btn.toJson()
