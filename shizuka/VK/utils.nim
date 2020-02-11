from uri import encodeUrl
import json
from strutils import join
from strformat import fmt


proc encode*(params: JsonNode): string =
  var res: seq[string] = @[]
  for key, value in params.pairs():
    if value.kind == JString:
      res.add(encodeUrl(key) & "=" & encodeUrl(value.getStr))
    else:
      res.add(encodeUrl(key) & "=" & encodeUrl(fmt"{value}"))
  res.join("&")
