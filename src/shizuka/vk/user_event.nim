# author: Ethosa
import
  json

let
  event_types = %*{
    "1": ["flags_change", "message_id", "flags"],
    "2": ["flags_set", "message_id", "mask"],
    "3": ["flags_reset", "message_id", "mask"],
    "4": ["message_new", "message_id", "flags", "peer_id", "timestamp", "text", "attachments"],
    "5": ["message_edit", "message_id", "mask", "peer_id", "timestamp", "new_text", "attachments"],
    "6": ["read_all_in", "peer_id", "local_id"],
    "7": ["read_all_out", "peer_id", "local_id"],
    "8": ["friend_online", "user_id", "extra", "timestamp"],
    "9": ["friend_offline", "user_id", "extra", "timestamp"]
  }

proc parseEvent*(arr: JsonNode): JsonNode =
  result = newJObject()
  let key = $arr[0]
  if event_types.hasKey(key):
    result["type"] = event_types[key][0]
    for i in 1..event_types[key].len()-1:
      result[event_types[key][i].getStr()] = arr[i]
