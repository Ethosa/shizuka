# author: Ethosa
import
  ../core/exceptions,
  ../core/enums,
  ../core/consts,
  asyncdispatch,
  httpclient,
  json,
  uri

export
  asyncdispatch,
  json


type
  Vk* = ref object
    client: AsyncHttpClient
    case kind*: VkKind:
    of VkUser:
      discard
    of VkGroup:
      group_id*: uint  ## Group ID. Uses only when auth as a vk group.
    api*: string       ## Api version
    access_token*: string


proc newVk*(access_token: string,
            api_version: string = DEFAULT_VK_API): Vk {.inline.} =
  ## Creates a new Vk user object.
  Vk(kind: VkUser, access_token: access_token,
     api: api_version, client: newAsyncHttpClient())

proc newVk*(access_token: string, group_id: uint,
            api_version: string = DEFAULT_VK_API): Vk {.inline.} =
  ## Creates a new Vk group object.
  Vk(kind: VkGroup, access_token: access_token, group_id: group_id,
     api: api_version, client: newAsyncHttpClient())


proc callVkMethod*(vk: Vk, method_name: string,
                   params: JsonNode = %*{}): Future[JsonNode] {.async.} =
  ## Calls any VK API method by its name.
  var
    url = METHOD_VK_API_URL & method_name & "?"
    args: seq[(string, string)] = @[("access_token", vk.access_token), ("v", vk.api)]
  for key, val in params.pairs():
    args.add((key, val.getStr($val)))
  url &= "&" & encodeQuery(args)

  var response = await vk.client.getContent(url)
  result = parseJson(response)

  if result.hasKey("error"):
    throw(VkError, result["error"]["error_msg"].getStr())
