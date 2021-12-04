# author: Ethosa
## Provides convenient uploading files to messages, wall, etc.
##
## ## Examples
##
## ### messagePhoto
## ```nim
## # uploads photos to chat
## var attachment = uploader.photosMessage(
##   ["a.png", "b.png"], 2_000_000_001)
## vk~messages.send(attachment=attachment, peer_id=2_000_000_001,
##                  random_id=0)
## ```
import
  ../core/compiletime,
  ../core/exceptions,
  ../core/consts,
  ../core/enums,
  asyncdispatch,
  httpclient,
  strutils,
  json,
  vk,
  os


type
  UploaderRef* = ref object
    client: AsyncHttpClient
    vk: VkRef


proc newUploader*(vk: VkRef): UploaderRef =
  ## Creates a new UploaderRef object.
  UploaderRef(vk: vk, client: newAsyncHttpClient())


proc uploadFiles(upl: UploaderRef, data: JsonNode, files: seq[string],
                 method_name: string): Future[JsonNode] {.async.} =
  var
    upload_url = await upl.vk.callVkMethod(method_name, data)
    uploaded_files = newMultipartData()
  if files.len() > 1:
    for i, val in files.pairs():
      if not fileExists(val):
        throw(OSError, "file '" & val & "' doesn't exists.")
      uploaded_files.addFiles({"file" & $(i): val})
  else:
    if not fileExists(files[0]):
      throw(OSError, "file '" & files[0] & "' doesn't exists.")
    uploaded_files.addFiles({"file": files[0]})

  let response = await upl.client.postContent(
    upload_url["response"]["upload_url"].getStr,
    multipart=uploaded_files)
  return parseJson(response)


proc getOrNot(node: JsonNode, key: string): JsonNode =
  if node.hasKey(key):
    return node[key]
  return node

proc format*(upl: UploaderRef, response: JsonNode,
             response_type="photo"): string =
  ## response formatting
  ##
  ## Arguments:
  ## - `response` - response after object saved
  ##
  ## Keyword Arguments:
  ## - `formtype` - "photo", "video", "audio" etc.
  var resp = response
  if resp.kind == JObject:
    resp = resp.getOrNot("response")
  if resp.kind == JObject and resp.hasKey("type"):
    let tp = resp.getOrNot("type").getStr()
    resp = resp.getOrNot(tp)

  if resp.kind == JObject:
    if resp.hasKey("owner_id") and resp.hasKey("id"):
      return "$1$2_$3" % [response_type, $(resp["owner_id"]), $(resp["id"])]
  elif resp.kind == JArray:
    var output: seq[string]
    for obj in resp.items:
      if obj.hasKey("owner_id") and obj.hasKey("id"):
        output.add("$1$2_$3" % [response_type, $(obj["owner_id"]), $(obj["id"])])
    return output.join(",")


proc audio*(upl: UploaderRef, files: seq[string], artist: string = "",
            title: string = ""): Future[string] {.async.} =
  ## Uploads audio file
  ##
  ## Arguments:
  ## - `files` - file paths.
  ## - `artist` - author. The default is taken from ID3 tags.
  ## - `title` - name of the composition. The default is taken from ID3 tags.
  let response = await upl.uploadFiles(%*{}, files, "audio.getUploadServer")
  var data = %*{
    "hash": response["hash"],
    "server": response["server"],
    "audio": response["audio"],
    "artist": artist, "title": title
  }
  return upl.format(await upl.vk.callVkMethod("audio.save", data), "audio")


proc photosMessage*(upl: UploaderRef, files: seq[string],
                   peer_id: int): Future[string] {.async.} =
  ## Uploads the photo in message.
  ##
  ## Arguments:
  ## - `files` - sequence of file paths.
  ## - `peer_id` - destination identifier.
  let
    data = %*{"peer_id": %peer_id}
    response = await upl.uploadFiles(data, files, "photos.getMessagesUploadServer")
  var enddata = %*{
      "peer_id": %peer_id,
      "server": response["server"],
      "hash": response["hash"],
      "photo": response["photo"],
      "v": %upl.vk.api,
      "access_token": %upl.vk.access_token
    }
  return upl.format(await upl.vk.callVkMethod("photos.saveMessagesPhoto", enddata))
