# author: Ethosa
import
  ../core/consts,
  ../core/exceptions,
  asyncdispatch,
  httpclient,
  json,
  uri


const
  CLIENT_ID: string = "3140623"
  CLIENT_SECRET: string = "VeWdmVclDCtn6ihuP1nt"


proc login*(client: AsyncHttpCLient, login: SomeInteger, password: string,
            version: string = DEFAULT_VK_API, tfcode: string = "",
            scope: string = "all"): Future[string] {.async.} =
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
  var args: seq[(string, string)]

  if tfcode != "":
    authData["code"] = %tfcode
  for key, val in authData:
    args.add((key, val.getStr($val)))

  let
    resp = await client.post("https://oauth.vk.com/token?" & encodeQuery(args))
    response = parseJson(await resp.body)
  if "error" in response:
    throw(VkError, $response)
  return response["access_token"].getStr()
