# author: Ethosa
import json

import TemplateElement


type
  TemplateObj = object
    elements: JsonNode
    template_type: string
  TemplateRef* = ref TemplateObj

proc Template*(ttype="carousel"): TemplateRef =
  ## Creates a new Template object.
  ##
  ## Arguments:
  ## -   ``ttype`` -- template type.
  TemplateRef(elements: %*[], template_type: ttype)

proc add*(t: TemplateRef, elem: JsonNode) =
  ## Adds a new element in the template.
  if t.elements.len < 10:
    t.elements.add elem

proc compile*(t: TemplateRef): JsonNode =
  ## Converts template object to the JSON.
  %*{"type": %t.template_type, "elements": %t.elements}
