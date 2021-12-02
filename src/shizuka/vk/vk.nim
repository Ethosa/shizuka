# author: Ethosa
import
  httpclient,
  ../core/exceptions,
  ../core/enums,
  ../core/consts


type
  Vk* = ref object
    client: AsyncHttpClient
    case kind*: VkKind:
    of VkUser:
      discard
    of VkGroup:
      group_id*: uint  ## Group ID. Uses only when auth as a vk group.
    api*: string      ## Api version
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
