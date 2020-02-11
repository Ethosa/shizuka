# author: Ethosa
import httpclient
import macros
import asyncdispatch
import strutils
import Vk


iterator listen*(vk: SyncVkObj | AsyncVkObj): JsonNode =
  var
    mname = ""
    url = ""
    key, server, ts: string
  if vk.group_id != 0:
    mname = "groups.getLongPollServer"
    url = "$#?act=a_check&key=$#&ts=$#&wait=25"
  else:
    mname = "messages.getLongPollServer"
    url = "https://$#?act=a_check&key=$#&ts=$#&wait=25&mode=202&version=3"

  var sv = waitFor vk.call_method(mname)
  server = sv["response"]["server"].getStr
  ts = $sv["response"]["ts"]
  key = sv["response"]["key"].getStr

  while true:
    var response = parseJson waitFor vk.client.getContent(url % [server, key, ts])
    if not response.hasKey("updates"):
      sv = waitFor vk.call_method(mname)
      server = sv["response"]["server"].getStr
      ts = $sv["response"]["ts"]
      key = sv["response"]["key"].getStr
    ts = $response["ts"]

    for update in response["updates"].elems:
      yield update
