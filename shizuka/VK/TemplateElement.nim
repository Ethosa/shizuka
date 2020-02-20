# author: Ethosa
import json


type
  TemplateElementObj = object
    title, description: string
    photo_id: string
    action: string
    link: string
    buttons: JsonNode
  TemplateElementRef* = ref TemplateElementObj


proc TemplateElement*(title="", description="", photo_id="",
                     action="open_link", link="https://vk.com",
                     buttons = %*[]): TemplateElementRef =
  ## Creates a new TemlateElement.
  ##
  ## Arguments:
  ## -   ``title`` -- title, maximum 80 characters.
  ## -   ``description`` -- subtitle, maximum 80 characters.
  ## -   ``photo_id`` -- id of the image to attach.
  ## -   ``action`` -- An object that describes the action
  ##                   that must be performed when you click on the carousel element.
  TemplateElementRef(title: title, description: description, photo_id: photo_id,
                     action: action, link: link, buttons: buttons)

proc add*(te: TemplateElementRef, button: JsonNode) =
  ## Adds a new button in template element.
  if te.buttons.len < 3:
    te.buttons.add button

proc add*(t: TemplateElementRef, buttons: varargs[JsonNode]) =
  for button in buttons:
    t.add button

proc to_json*(te: TemplateElementRef): JsonNode =
  ## Converts a template element to place it in a template object.
  result = %*{
    "title": %te.title,
    "description": %te.description,
    "photo_id": %te.photo_id,
    "buttons": %te.buttons,
    "action": %te.action
  }
  if te.action == "open_link":
    result["link"] = %te.link
