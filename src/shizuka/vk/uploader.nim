# author: Ethosa
## Provides convenient uploading files to messages, wall, etc.
##
## ## Examples
##
## ### messagePhoto
## ```nim
## # uploads photos to chat
## var attachment = uploader.photoMessage(
##   ["a.png", "b.png"], 2_000_000_001)
## vk~messages.send(attachment=attachment, peer_id=2_000_000_001,
##                  random_id=0)
## ```
import
  ../core/exceptions,
  ../core/enums,
  asyncdispatch,
  httpclient,
  strutils,
  json,
  vk,
  os,
  re


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

proc format*(response: JsonNode, response_type="photo"): string =
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

proc getInfo*(formatted: string): seq[(string, string, string)] =
  result = @[]
  for attachment in formatted.split(','):
    let attach_data = attachment.findAll(re"([a-zA-Z]+)|(\-*\d+)")
    result.add((attach_data[0], attach_data[1], attach_data[2]))

proc getAttachId*(formatted: string): string =
  let fmted = formatted.getInfo()
  var tmp_seq: seq[string] = @[]
  for f in fmted:
    tmp_seq = @[f[1] & "_" & f[2]]
  return tmp_seq.join(",")


proc audio*(upl: UploaderRef, files: seq[string], artist: string = "",
            title: string = ""): Future[string] {.async.} =
  ## Uploads audio file
  ##
  ## Arguments:
  ## - `files` - file paths.
  ## - `artist` - author. The default is taken from ID3 tags.
  ## - `title` - name of the composition. The default is taken from ID3 tags.
  ##
  ## **Warning**: work only with user!
  if upl.vk.kind != VkUser:
    throw(VkError, "upload audio available only for user.")
  let response = await upl.uploadFiles(%*{}, files, "audio.getUploadServer")
  var data = %*{
    "hash": response["hash"],
    "server": response["server"],
    "audio": response["audio"],
    "artist": artist, "title": title
  }
  return format(await upl.vk.callVkMethod("audio.save", data), "audio")


proc doc*(upl: UploaderRef, files: seq[string], group_id: int = 0, title: string = "",
          tags: string = "", return_tags: int = 0, is_wall: bool = false): Future[string] {.async.} =
  ## Uploads document.
  ##
  ## Arguments:
  ## - `files` - file paths.
  ## - `group_id` - community identifier (if you need to upload a document to the list of community documents).
  ## - `title` - document's name.
  ## - `tags` - tags for search.
  ## - `return_tags`
  ## - `is_wall` - upload document in wall.
  if upl.vk.kind != VkUser:
    throw(VkError, "upload audio available only for user.")
  var data = %*{}
  if group_id != 0:
    data["group_id"] = %group_id

  let
    response: JsonNode =
      await upl.uploadFiles(data, files, if is_wall: "docs.getWallUploadServer" else: "docs.getUploadServer")
    enddata = %*{
      "file": response["file"],
      "title": %title,
      "tags": %tags,
      "return_tags": %return_tags
    }
  return format(await upl.vk.callVkMethod("docs.save", enddata), "doc")


proc docMessage*(upl: UploaderRef, files: seq[string],
                       peer_id: int, doc_type="doc", title="",
                       tags="", return_tags=0): Future[string] {.async.} =
  ##Uploads document in message.
  ##
  ## Arguments:
  ## - `files` - file paths.
  ## - `peer_id` - destination identifier.
  ## - `doc_type` - type of document. Possible values: doc, audio_message.
  ## - `title` - document's name.
  ## - `tags` - tags for search.
  ## - `return_tags`
  let
    data = %*{
      "peer_id": %peer_id,
      "type": %doc_type
    }
    response = await upl.uploadFiles(data, files, "docs.getMessagesUploadServer")
    enddata = %*{
      "file": response["file"],
      "title": %title,
      "tags": %tags,
      "return_tags": %return_tags
    }

  return format(await upl.vk.callVkMethod("docs.save", enddata), "doc")

proc photoAlbum*(upl: UploaderRef, files: seq[string], album_id: int,
                  group_id: uint = 0, caption: string = ""): Future[string] {.async.} =
  ## Uploads photos in album
  ## 
  ## Arguments:
  ## - `files` - file paths.
  ## - `album_id` is photo album ID.
  ## - `group_id` is group ID, if needed.
  ## - `caption` - photo caption.
  if upl.vk.kind != VkUser:
    throw(VkError, "upload audio available only for user.")
  var data = %*{
    "album_id": %album_id
  }
  if group_id != 0:
    data["group_id"] = %group_id

  let
    response = await upl.uploadFiles(data, files, "photos.getUploadServer")
  data["caption"] = %caption
  data["server"] = response["server"]
  data["hash"] = response["hash"]
  data["photos_list"] = response["photos_list"]
  return format(await upl.vk.callVkMethod("photos.save", data))

proc photoChat*(upl: UploaderRef, files: seq[string], chat_id: int, crop_x: int = 0,
                crop_y: int = 0, crop_width: int = 0): Future[string] {.async.} =
  ## Uploads chat cover.
  ##
  ## Aguments:
  ## - `files` - file paths.
  ## - `chat_id` - id of the conversation for which you want to upload a photo.
  ## - `crop_x` - x coordinate for cropping the photo (upper right corner).
  ## - `crop_y` - y coordinate for cropping the photo (upper right corner).
  ## - `crop_width` - Width of the photo after cropping in px.
  var data = %*{"caht_id": %chat_id}
  if crop_x != 0:
    data["crop_x"] = %crop_x
  if crop_y != 0:
    data["crop_y"] = %crop_y
  if crop_width != 0:
    data["crop_width"] = %crop_width

  let
    response = await upl.uploadFiles(data, files, "photos.getChatUploadServer")
    enddata = %*{"file": response["response"]}

  return format(await upl.vk.callVkMethod("messages.setChatPhoto", enddata))


proc photoCover*(upl: UploaderRef, files: seq[string], group_id: int, crop_x: int = 0,
                 crop_y: int = 0, crop_x2: int = 795, crop_y2: int = 200): Future[string]
                 {.async.} =
  ## Updates group cover photo.
  ##
  ## Arguments:
  ## - `files` - file paths.
  ## - `group_id` - community id.
  ## - `crop_x`- X coordinate of the upper left corner to crop the image.
  ## - `crop_y`-Y coordinate of the upper left corner to crop the image .
  ## - `crop_x2` - X coordinate of the lower right corner to crop the image.
  ## - `crop_y2` - Y coordinate of the lower right corner to crop the image.
  let
    data = %*{
      "group_id": %group_id,
      "crop_x": %crop_x,
      "crop_y": %crop_y,
      "crop_x2": %crop_x2,
      "crop_y2": %crop_y2
    }
    response = await upl.uploadFiles(data, files, "photos.getOwnerCoverPhotoUploadServer")
    enddata = %*{
      "hash": response["hash"],
      "photo": response["photo"]
    }
  return format(await upl.vk.callVkMethod("photos.saveOwnerCoverPhoto", enddata))


proc photoMessage*(upl: UploaderRef, files: seq[string],
                   peer_id: int): Future[string] {.async.} =
  ## Uploads the photos in message.
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
  return format(await upl.vk.callVkMethod("photos.saveMessagesPhoto", enddata))


proc photoProfile*(upl: UploaderRef, file: string,
                   owner_id: int = 0): Future[string] {.async.} =
  ## Updates profile photo
  ##
  ## Arguments:
  ## - `file` - file path.
  ## - `owner_id` - id of the community or current user.
  var data = %*{}
  if owner_id != 0:
    data["owner_id"] = %owner_id
  let
    response = await upl.uploadFiles(data, @[file], "photos.getOwnerPhotoUploadServer")
    enddata = %*{
      "hash": response["hash"],
      "server": response["server"],
      "photo": response["photo"]
    }
  return format(await upl.vk.callVkMethod("photos.saveOwnerPhoto", enddata))


proc photoWall*(upl: UploaderRef, files: seq[string], group_id: int = 0,
                user_id: int = 0, caption: string = ""): Future[string] {.async.} =
  ## Uploads photo in wall post.
  ##
  ## Arguments:
  ## - `files` - file paths.
  ## - `group_id` - id of the community on whose wall you want to upload the photo (without a minus sign).
  ## - `user_id` - id of the user whose wall you want to save the photo on.
  ## - `caption` - photo description text (maximum 2048 characters).
  var data = %*{}
  if group_id != 0:
    data["group_id"] = %group_id
  let response = await upl.uploadFiles(data, files, "photos.getWallUploadServer")

  var enddata = %*{
    "caption": %caption,
    "server": response["server"],
    "hash": response["hash"],
    "photo": response["photo"]
  }
  if user_id != 0:
    enddata["user_id"] = %user_id

  return format(await upl.vk.callVkMethod("photos.saveWallPhoto", enddata))
