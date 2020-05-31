# author: Ethosa
import json


type
  TemplateObj = object
    template_type: string
    elements: JsonNode
  TemplateRef* = ref TemplateObj

proc Template*(`type`: string = "carousel"): TemplateRef =
  ## Creates a new Template object.
  ##
  ## Arguments:
  ## -  `type` - template type.
  TemplateRef(elements: %*[], template_type: `type`)

proc add*(t: TemplateRef, elem: JsonNode) =
  ## Adds a new element in the template.
  if t.elements.len < 10:
    t.elements.add elem

proc add*(t: TemplateRef, elems: varargs[JsonNode]) =
  for element in elems:
    t.add element

proc compile*(t: TemplateRef): JsonNode =
  ## Converts template object to the JSON.
  %*{"type": %t.template_type, "elements": %t.elements}
