# author: Ethosa
import json

type
  ButtonColor* {.pure.} = enum
    PRIMARY = "primary"
    SECONDARY = "secondary"
    NEGATIVE = "negative"
    POSITIVE = "positive"


proc create_button*(button_type="text", color="primary",
                   params = %*{}): JsonNode =
  ## Creates a new button.
  result = %*{}
  if button_type == "text":
      result["color"] = %color
  result["action"] = params
  result["action"]["type"] = %button_type
