# author: Ethosa
import httpclient
import macros
import asyncdispatch
from strutils import `%`
import json

from Event import to_event

from consts import VK_API_URL


type
  LongPollObj[ClientType] = object
    group_id*: int
    client*: ClientType
    response: JsonNode
    server*, ts*, key*: string
    access_token, v: string
    debug*: bool

  LongPollRef* = ref LongPollObj[HttpClient]
  ALongPollRef* = ref LongPollObj[AsyncHttpClient]


proc LongPoll*(client: HttpClient, group_id: int,
               token, version: string, debug: bool): LongPollRef =
  ## Creates a new Sync LongPoll object
  ##
  ## Arguments:
  ## -   ``client`` -- created HttpClient  
  ## -   ``group_id``
  ##
  ## Async version: `ALongPoll proc <#ALongPoll,AsyncHttpClient,int,string,string,bool>`_
  LongPollRef(client: client, group_id: group_id, server: "", ts: "0", key: "",
    access_token: token, v: version, debug: debug)

proc ALongPoll*(client: AsyncHttpClient, group_id: int,
                token, version: string, debug: bool): ALongPollRef =
  ## Creates a new Async LongPoll object
  ##
  ## Arguments:
  ## -   ``client`` -- created AsyncHttpClient  
  ## -   ``group_id``
  ##
  ## Sync version: `LongPoll proc <#LongPoll,HttpClient,int,string,string,bool>`_
  ALongPollRef(client: client, group_id: group_id, server: "", ts: "0", key: "",
    access_token: token, v: version, debug: debug)


proc update_ts(lp: LongPollRef, mname: string) =
  try:
    var sv = parseJson lp.client.getContent(mname)
    lp.server = sv["response"]["server"].getStr
    if lp.group_id == 0:
      lp.ts = $sv["response"]["ts"]
    else:
      lp.ts = sv["response"]["ts"].getStr
    lp.key = sv["response"]["key"].getStr
  except:
    lp.update_ts mname

proc update_server(lp: LongPollRef, url: string) =
  try:
    lp.response = parseJson lp.client.getContent(
      url % [lp.server, lp.key, lp.ts])
  except:
    lp.update_server url


proc update_ts(lp: ALongPollRef, mname: string) =
  try:
    var sv = parseJson waitFor lp.client.getContent(mname)
    lp.server = sv["response"]["server"].getStr
    if lp.group_id == 0:
      lp.ts = $sv["response"]["ts"]
    else:
      lp.ts = sv["response"]["ts"].getStr
    lp.key = sv["response"]["key"].getStr
  except:
    lp.update_ts mname

proc update_server(lp: ALongPollRef, url: string) =
  try:
    lp.response = parseJson waitFor lp.client.getContent(
      url % [lp.server, lp.key, lp.ts])
  except:
    lp.update_server url


iterator listen*(lp: LongPollRef | ALongPollRef): JsonNode =
  ## Starts server listen.
  ##
  ## .. code-block::Nim
  ##   import shizuka
  ##   
  ##   vk = Vk(...)
  ##   
  ##   for event in vk.longpoll.listen():
  ##     echo event
  var
    mname = ""
    url = ""
    key, server, ts: string
  if lp.group_id != 0:
    mname = "groups.getLongPollServer"
    url = "$#?act=a_check&key=$#&ts=$#&wait=25"
  else:
    mname = "messages.getLongPollServer"
    url = "https://$#?act=a_check&key=$#&ts=$#&wait=25&mode=202&version=3"

  mname = VK_API_URL & mname & "?access_token=" & lp.access_token
  mname &= "&v=" & lp.v
  if lp.group_id != 0:
    mname &= "&group_id=" & $lp.group_id

  lp.update_ts mname

  if lp.debug:
    echo "Longpoll start."

  while true:
    lp.update_server url
    if not lp.response.hasKey("updates"):
      lp.update_ts mname
    if lp.group_id == 0:
      lp.ts = $lp.response["ts"]
    else:
      lp.ts = lp.response["ts"].getStr

    for update in lp.response["updates"].elems:
      yield to_event update
