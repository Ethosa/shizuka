# author: Ethosa
## Provides working with VK API.
##
## ## Auth Examples:
## ### As user:
## ```nim
## var vk = newVk(88005553535, "accaount password")
## ```
##
## ```nim
## var vk = newVk("myAccessToken")
## ```
##
## ### As Group
## ```nim
## var vk = newVk("groupAccessToken", 1919822)
## ```
##
## ## Calling Any VK API Method:
## ### via `callVkMethod <#callVkMethod,VkRef,string,JsonNode>`_ proc
## ```nim
## vk.callVkMethod("messages.send",
##                 %*{"message": "hello!",
##                    "random_id": 123,
##                    "peer_id": 123
## })
## ```
##
## ### via `~` macro
## ```nim
## vk~messages.send(message="hello!", random_id=123, peer_id=123)
## ```
import
  ../core/exceptions,
  ../core/enums,
  ../core/consts,
  ../private/tools,
  asyncdispatch,
  httpclient,
  json,
  uri

export
  asyncdispatch,
  json


type
  VkEvent* = object
    name*: string
    action*: proc(event: JsonNode): Future[void]
  VkRef* = ref object
    client: AsyncHttpClient
    case kind*: VkKind:
    of VkUser:
      discard
    of VkGroup:
      group_id*: uint  ## Group ID. Uses only when auth as a vk group.
    api*: string       ## Api version
    access_token*: string
    events*: seq[VkEvent]


proc newVk*(access_token: string,
            api_version: string = DEFAULT_VK_API): VkRef {.inline.} =
  ## Creates a new Vk user object.
  ##
  ## See also:
  ## - `newVk proc <#newVk,SomeInteger,string,string>`_
  ## - `newVk proc <#newVk,string,uint,string>`_
  VkRef(kind: VkUser, access_token: access_token,
     api: api_version, client: newAsyncHttpClient())

proc newVk*(userlogin: int, password: string,
            api_version: string = DEFAULT_VK_API): VkRef {.inline.} =
  ## Creates a new Vk user object.
  ##
  ## See also:
  ## - `newVk proc <#newVk,string,string>`_
  ## - `newVk proc <#newVk,string,uint,string>`_
  result = VkRef(kind: VkUser, api: api_version, client: newAsyncHttpClient())
  result.access_token = waitFor login(result.client, userlogin, password, api_version)

proc newVk*(access_token: string, group_id: uint,
            api_version: string = DEFAULT_VK_API): VkRef {.inline.} =
  ## Creates a new Vk group object.
  ##
  ## See also:
  ## - `newVk proc <#newVk,string,string>`_
  ## - `newVk proc <#newVk,SomeInteger,string,string>`_
  VkRef(kind: VkGroup, access_token: access_token, group_id: group_id,
     api: api_version, client: newAsyncHttpClient())


proc newUserVk*(userlogin: int, password: string,
                api_version: string = DEFAULT_VK_API): VkRef {.inline.} =
  ## Creates a new Vk user object.
  ##
  ## See also:
  ## - `newVk proc <#newVk,string,string>`_
  ## - `newVk proc <#newVk,string,uint,string>`_
  result = VkRef(kind: VkUser, api: api_version, client: newAsyncHttpClient())
  result.access_token = waitFor login(result.client, userlogin, password, api_version)

proc newGroupVk*(access_token: string, group_id: uint,
                 api_version: string = DEFAULT_VK_API): VkRef {.inline.} =
  ## Creates a new Vk group object.
  ##
  ## See also:
  ## - `newVk proc <#newVk,string,string>`_
  ## - `newVk proc <#newVk,SomeInteger,string,string>`_
  VkRef(kind: VkGroup, access_token: access_token, group_id: group_id,
     api: api_version, client: newAsyncHttpClient())


proc callVkMethod*(vk: VkRef, method_name: string,
                   params: JsonNode = %*{}): Future[JsonNode] {.async.} =
  ## Calls any VK API method by its name.
  var
    url = METHOD_VK_API_URL & method_name & "?"
    args: seq[(string, string)] = @[("access_token", vk.access_token), ("v", vk.api)]
  for key, val in params.pairs():
    args.add((key, val.getStr($val)))
  url &= "&" & encodeQuery(args)

  let response = await vk.client.getContent(url)
  result = parseJson(response)

  if result.hasKey("error"):
    throw(VkError, result["error"]["error_msg"].getStr())
