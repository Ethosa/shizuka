# author: Ethosa
import httpclient
import asyncdispatch
import strutils
import json

import Event

when defined(debug):
  import logging


type
  LongPollObj = object
    group_id*: int
    server*, ts*, key*: string
    access_token, v: string
    client*: AsyncHttpClient
    response: JsonNode

  LongPollRef* = ref LongPollObj


proc LongPoll*(client: AsyncHttpClient, group_id: int, token, version: string): LongPollRef =
  ## Creates a new LongPoll object
  ##
  ## Arguments:
  ## - `client` - created AsyncHttpClient  
  ## - `group_id` is an your group ID.
  ## - `token` is an your VK access token.
  ## - `version` is a longpoll version.
  LongPollRef(
    client: client, group_id: group_id, server: "", ts: "0", key: "",
    access_token: token, v: version)


proc update_ts(lp: LongPollRef, mname: string) {.async.} =
  try:
    var sv = parseJson(await lp.client.getContent(mname))
    lp.server = sv["response"]["server"].getStr
    if lp.group_id == 0:
      lp.ts = $sv["response"]["ts"]
    else:
      lp.ts = sv["response"]["ts"].getStr
    lp.key = sv["response"]["key"].getStr
  except:
    await lp.update_ts mname

proc update_server(lp: LongPollRef, url: string) {.async.} =
  try:
    lp.response = parseJson(await lp.client.getContent(url % [lp.server, lp.key, lp.ts]))
  except:
    await lp.update_server url


iterator listen*(lp: LongPollRef): JsonNode =
  ## Starts server listen.
  ##
  ## .. code-block:: nim
  ##
  ##    import shizuka
  ## 
  ##    vk = Vk(...)
  ## 
  ##    for event in vk.longpoll.listen():
  ##      echo event
  var
    mname: string
    url: string
  if lp.group_id != 0:
    mname = "groups.getLongPollServer"
    url = "$#?act=a_check&key=$#&ts=$#&wait=25"
  else:
    mname = "messages.getLongPollServer"
    url = "https://$#?act=a_check&key=$#&ts=$#&wait=25&mode=202&version=3"

  mname = "https://api.vk.com/method/" & mname & "?access_token=" & lp.access_token
  mname &= "&v=" & lp.v
  if lp.group_id != 0:
    mname &= "&group_id=" & $lp.group_id

  waitFor(lp.update_ts(mname))

  when defined(debug):
    info("Longpoll start.")

  while true:
    waitFor(lp.update_server(url))
    if not lp.response.hasKey("updates"):
      waitFor(lp.update_ts(mname))
    if lp.group_id == 0:
      lp.ts = $lp.response["ts"]
    else:
      lp.ts = lp.response["ts"].getStr

    for update in lp.response["updates"].elems:
      yield to_event update
