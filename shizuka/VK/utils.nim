import httpclient
import asyncdispatch
import uri
import json
import strutils
import strformat


const
  CLIENT_ID: string = "3140623"
  CLIENT_SECRET: string = "VeWdmVclDCtn6ihuP1nt"


proc encode*(params: JsonNode): string =
  ## Encodes Json params to url params
  var res: seq[string]

  for key, value in params.pairs:
    if value.kind == JString:
      res.add(encodeUrl(key) & "=" & encodeUrl(value.getStr))
    else:
      res.add(encodeUrl(key) & "=" & encodeUrl(fmt"{value}"))
  res.join "&"


proc log_in*(client: AsyncHttpCLient, login, password: string,
            tfcode="", scope="all", version="5.107"): Future[string] {.async.} =
  ## Gets access token via login and password.
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
    resp = await client.post("https://oauth.vk.com/token?" & encode(authData))
    answer = parseJson(await resp.body)
  if "error" notin answer:
    return answer["access_token"].str
  else:
    echo "Error!"
    echo answer
    echo "Url: https://oauth.vk.com/token?" & encode(authData)
    return ""
