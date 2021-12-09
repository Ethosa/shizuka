# author: Ethosa
## Provides working with template elements.
import
  ../core/exceptions,
  ../core/enums,
  button,
  json


type
  TElementObj* = object
    case action: TElementAction
    of TElementLink:
      link: string
    of TElementPhoto:
      discard
    title, desc: string
    photo_id: string
    buttons: JsonNode


proc newTElement*(title: string, description: string, photo_id: string,
                  buttons: JsonNode = newJArray(),
                  action: TElementAction = TElementPhoto
                  ): TElementObj =
  ## Creates a new template element.
  result = TElementObj(title: title, desc: description, photo_id: photo_id,
                       buttons: buttons, action: action)
  if action == TElementLink:
    result.link = "https:/vk.com"


proc `title`*(elem: TElementObj): string {.inline.} =
  ## Returns template element `title`.
  ## Maximum 80 characters.
  elem.title
proc `title=`*(elem: var TElementObj, val: string) =
  ## Changes template element `title` to `val`.
  ## val length should be less than 80.
  if val.len() > 80:
    throw(TemplateError, "title length should be less than 81.")
  elem.title = val

proc `description`*(elem: TElementObj): string {.inline.} =
  ## Returns template element `description`.
  ## Subtitle, maximum 80 characters.
  elem.desc
proc `description=`*(elem: var TElementObj, val: string) =
  ## Changes template element `description` to `val`.
  ## val length should be less than 80.
  if val.len() > 80:
    throw(TemplateError, "description length should be less than 81.")
  elem.desc = val

proc `photo_id`*(elem: TElementObj): string {.inline.} =
  ## Returns template element `photo_id`.
  ## ID of an image that needs to be attached.
  elem.photo_id
proc `photo_id=`*(elem: var TElementObj, val: string) =
  ## Changes template element `photo_id` to `val`.
  elem.photo_id = val

proc `link`*(elem: TElementObj): string {.inline.} =
  ## Returns template element `link`.
  elem.link
proc `link=`*(elem: var TElementObj, val: string) =
  ## Changes template element `link` to `val`.
  elem.link = val


proc addButton*(elem: var TElementObj, btn: ButtonObj) =
  ## Adds a new button.
  if elem.buttons.len() > 2:
    throw(TemplateError, "buttons count should be less then ")
  elem.buttons.add(btn.toJson())

proc toJson*(elem: TElementObj): JsonNode =
  ## Translates template element to json.
  result = %*{
    "title": elem.title,
    "description": elem.desc,
    "buttons": elem.buttons,
    "photo_id": elem.photo_id,
    "action": {
      "type": elem.action
    }
  }
  if elem.action == TElementLink:
    result["action"]["link"] = newJString(elem.link)

proc `$`*(t: TElementObj): string {.inline.} =
  $t.toJson()
