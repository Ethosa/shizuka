# author: Ethosa
## Provides working with templates.
## Bots can send special messages using templates.
## Such messages differ from regular ones both visually and functionally.
## Currently, the carousel is the only template available.
import
  ../core/compiletime,
  ../core/exceptions,
  template_elem,
  json


type
  TemplateRef = ref object
    `type`: string
    elements: JsonNode


proc newTemplate*(`type`: string = "carousel",
                  elements: JsonNode = newJArray()): TemplateRef =
  TemplateRef(`type`: `type`, elements: elements)


proc addElement*(t: TemplateRef, elem: TElementObj) =
  ## Adds a new element to template.
  ##
  ## Max amount of elements in a carousel – 10, minimum – 1.
  if t.elements.len > 9:
    throw(TemplateError, "0 < template elements count < 11")
  t.elements.add(elem.toJson())

proc toJson*(t: TemplateRef): JsonNode {.inline.} =
  ## Translates template to json representation.
  %*{
    "type": t.`type`,
    "elements": t.elements
  }

proc `$`*(t: TemplateRef): string {.inline.} =
  $t.toJson()
