import httpclient
import asyncdispatch
from uri import encodeUrl
import json
from strutils import join
from strformat import fmt


const
  CLIENT_ID: string = "3140623"
  CLIENT_SECRET: string = "VeWdmVclDCtn6ihuP1nt"


proc encode*(params: JsonNode): string =
  var res: seq[string] = @[]
  for key, value in params.pairs():
    if value.kind == JString:
      res.add(encodeUrl(key) & "=" & encodeUrl(value.getStr))
    else:
      res.add(encodeUrl(key) & "=" & encodeUrl(fmt"{value}"))
  res.join("&")

proc log_in*(client: HttpClient | AsyncHttpCLient, login, password: string,
            tfcode="", scope="all", version="5.103"): Future[string] {.multisync.} =
  let authData = %*{
    "client_id": CLIENT_ID,
    "client_secret": CLIENT_SECRET,
    "grant_type": "password",
    "username": login,
    "password": password,
    "scope": scope,
    "v": version,
    "2fa-supported": "1"
  }
  if tfcode != "":
    authData["code"] = %tfcode

  let
    resp = await client.post("https://oauth.vk.com/token?" & encode authData)
    answer = parseJson(await resp.body)
  if "error" notin answer:
    return answer["access_token"].str
  else:
    return ""
