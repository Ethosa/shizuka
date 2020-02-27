# author: Ethosa
import httpclient
import asyncdispatch
import json
from strutils import join

from utils import encode
from consts import VK_API_URL


type
  UploaderObj* = ref object
    client: AsyncHttpClient
    access_token, v: string


proc Uploader*(client: AsyncHttpClient, access_token, v: string): UploaderObj =
  ## Creates a new Sync Uploader object.
  UploaderObj(client: client, access_token: access_token, v: v)


proc callAPI(upl: UploaderObj, method_name: string, data: JsonNode): Future[JsonNode] {.async.} =
  data["access_token"] = %upl.access_token
  data["v"] = %upl.v
  result = parseJson await upl.client.postContent(
    VK_API_URL & method_name & "?" & encode data
  )


proc upload_files(upl: UploaderObj, data: JsonNode,
                  files: seq[string], method_name: string): Future[JsonNode]
                 {.async.} =
  var
    upload_url = await upl.callAPI(method_name, data)
    uploaded_files = newMultipartData()
  if files.len > 1:
    var i = 1
    for file in files:
      uploaded_files.addFiles({"file" & $(i): file})
      inc i
  else:
    uploaded_files.addFiles({"file": files[0]})

  result = parseJson await upl.client.postContent(
    upload_url["response"]["upload_url"].getStr,
    multipart=uploaded_files)


proc get(node: JsonNode, key: string): JsonNode =
  if node.hasKey(key):
    return node[key]
  else:
    return node


proc format*(upl: UploaderObj, response: JsonNode,
             response_type="photo"): string =
  ## response formatting
  ##
  ## Arguments:
  ## -   ``response`` -- response after object saved
  ##
  ## Keyword Arguments:
  ## -   ``formtype`` -- "photo", "video", "audio" etc.
  var resp = response
  if resp.kind == JObject:
    resp = resp.get "response"
  if resp.kind == JObject:
    resp = resp.get "type"

  if resp.kind == JObject:
    if resp.hasKey("owner_id") and resp.hasKey("id"):
      return response_type & $(resp["owner_id"]) & "_" & $(resp["id"])
  elif resp.kind == JArray:
    var output: seq[string]
    for obj in resp.items:
      if obj.hasKey("owner_id") and obj.hasKey("id"):
        output.add(response_type & $(obj["owner_id"]) & "_" & $(obj["id"]))
    return output.join ","


proc album_photo*(upl: UploaderObj, files: seq[string], album_id: int,
                  group_id=0, caption=""): Future[JsonNode] {.async.} =
  ## Uploads photo in album
  ## 
  ## Arguments:
  ## -   ``files`` -- file paths.
  ## -   ``album_id``
  ## 
  ## Keyword Arguments:
  ## -   ``group_id``
  ## -   ``caption`` -- photo caption.
  var data = %*{
    "album_id": %album_id
  }
  if group_id != 0:
    data["group_id"] = %group_id

  var response = await upl.upload_files(data, files, "photos.getUploadServer")
  var enddata = %*{
    "album_id": %album_id,
    "caption": %caption,
    "server": response["server"],
    "hash": response["hash"],
    "photos_list": response["photos_list"]
  }
  result = await upl.callAPI("photos.save", enddata)


proc audio*(upl: UploaderObj, files: seq[string], artist="",
            title=""): Future[JsonNode] {.async.} =
  ## Uploads audio file
  ##
  ## Arguments:
  ## -   ``files`` -- file paths.
  ##
  ## Keyword Arguments:
  ## -   ``artist`` -- songwriter. The default is taken from ID3 tags.
  ## -   ``title`` -- name of the composition. The default is taken from ID3 tags.
  var response = await upl.upload_files(%*{}, files, "audio.getUploadServer")
  var data = %*{
    "hash": response["hash"],
    "server": response["server"],
    "audio": response["audio"]
  }
  result = await upl.callAPI("audio.save", data)


proc chat_photo*(upl: UploaderObj, files: seq[string], chat_id: int,
                 crop_x=0, crop_y=0, crop_width=0): Future[JsonNode] {.async.} =
  ## Uploads chat cover.
  ##
  ## Aguments:
  ## -   ``files`` -- file paths.
  ## -   ``chat_id`` -- id of the conversation for which you want to upload a photo.
  ##
  ## Keyword Arguments:
  ## -   ``crop_x`` -- x coordinate for cropping the photo (upper right corner).
  ## -   ``crop_y`` -- y coordinate for cropping the photo (upper right corner).
  ## -   ``crop_width`` -- Width of the photo after cropping in px.
  var data = %*{"caht_id": %chat_id}
  if crop_x != 0:
    data["crop_x"] = %crop_x
  if crop_y != 0:
    data["crop_y"] = %crop_y
  if crop_width != 0:
    data["crop_width"] = %crop_width

  var response = await upl.upload_files(data, files, "photos.getChatUploadServer")
  var enddata = %*{"file": response["response"]}

  result = await upl.callAPI("messages.setChatPhoto", enddata)


proc cover_photo*(upl: UploaderObj, files: seq[string], group_id: int,
                  crop_x=0, crop_y=0, crop_x2=795, crop_y2=200): Future[JsonNode]
                  {.async.} =
  ## Updates group cover photo.
  ##
  ## Arguments:
  ## -   ``files`` -- file paths.
  ## -   ``group_id`` -- community id.
  ##
  ## Keyword Arguments:
  ## -   ``crop_x`` -- X coordinate of the upper left corner to crop the image.
  ## -   ``crop_y`` --Y coordinate of the upper left corner to crop the image .
  ## -   ``crop_x2`` -- X coordinate of the lower right corner to crop the image.
  ## -   ``crop_y2`` -- Y coordinate of the lower right corner to crop the image.
  var data = %*{
    "group_id": %group_id,
    "crop_x": %crop_x,
    "crop_y": %crop_y,
    "crop_x2": %crop_x2,
    "crop_y2": %crop_y2
  }
  var response = await upl.upload_files(data, files, "photos.getOwnerCoverPhotoUploadServer")
  var enddata = %*{
    "hash": response["hash"],
    "photo": response["photo"]
  }
  result = await upl.callAPI("photos.saveOwnerCoverPhoto", enddata)


proc document*(upl: UploaderObj, files: seq[string],
               group_id=0, title="", tags="", return_tags=0,
               is_wall=false): Future[JsonNode] {.async.} =
  ## Uploads document.
  ##
  ## Arguments:
  ##     ``files`` -- file paths.
  ##     ``group_id`` -- community identifier
  ##                     (if you need to upload a document to
  ##                      the list of community documents).
  ##
  ## Keyword Arguments:
  ##     ``title`` -- document's name.
  ##     ``tags`` -- tags for search.
  ##     ``return_tags``
  ##     ``is_wall`` -- upload document in wall.
  var data = %*{}
  var response: JsonNode
  if group_id != 0:
    data["group_id"] = %group_id

  if is_wall:
    response = await upl.upload_files(data, files, "docs.getWallUploadServer")
  else:
    response = await upl.upload_files(data, files, "docs.getUploadServer")

  var enddata = %*{
    "file": response["file"],
    "title": %title,
    "tags": %tags,
    "return_tags": %return_tags
  }
  result = await upl.callAPI("docs.save", enddata)


proc document_message*(upl: UploaderObj, files: seq[string],
                       peer_id: int, doc_type="doc", title="",
                       tags="", return_tags=0): Future[JsonNode] {.async.} =
  ##Uploads document in message.
  ##
  ## Arguments:
  ## -   ``files`` -- file paths.
  ## -   ``peer_id`` -- destination identifier.
  ##
  ## Keyword Arguments:
  ## -   ``doc_type`` -- type of document.
  ##                     Possible values: doc, audio_message.
  ## -   ``title`` -- document's name.
  ## -   ``tags`` -- tags for search.
  ## -   ``return_tags``
  var data = %*{
   "peer_id": %peer_id,
   "type": %doc_type
  }

  var response = await upl.upload_files(data, files, "docs.getMessagesUploadServer")
  var enddata = %*{
    "file": response["file"],
    "title": %title,
    "tags": %tags,
    "return_tags": %return_tags
  }

  return await upl.callAPI("docs.save", enddata)



proc message_photo*(upl: UploaderObj, files: seq[string],
                    peer_id: int): Future[JsonNode] {.async.} =
  ## Uploads the photo in message.
  ##
  ## Arguments:
  ## -   ``files`` -- sequence of file paths.
  ## -   ``peer_id`` -- destination identifier.
  var
    data = %*{"peer_id": %peer_id}
    response = await upl.upload_files(data, files, "photos.getMessagesUploadServer")
    enddata = %*{
      "peer_id": %peer_id,
      "server": response["server"],
      "hash": response["hash"],
      "photo": response["photo"],
      "v": %upl.v,
      "access_token": %upl.access_token
    }
  result = await upl.callAPI("photos.saveMessagesPhoto", enddata)


proc profile_photo*(upl: UploaderObj, file: string, owner_id=0): Future[JsonNode] {.async.} =
  ## Updates profile photo
  ##
  ## Arguments:
  ## -   ``file`` -- file path.
  ##
  ## Keyword Arguments:
  ## -   ``owner_id`` -- id of the community or current user.
  var data = %*{}
  if owner_id != 0:
    data["owner_id"] = %owner_id
  var response = await upl.upload_files(data, @[file], "photos.getOwnerPhotoUploadServer")
  var enddata = %*{
    "hash": response["hash"],
    "server": response["server"],
    "photo": response["photo"]
  }
  result = await upl.callAPI("photos.saveOwnerPhoto", enddata)


proc wall_photo*(upl: UploaderObj, files: seq[string], group_id=0, user_id=0,
                 caption=""): Future[JsonNode] {.async.} =
  ## Uploads photo in wall post.
  ##
  ## Arguments:
  ## -   ``files`` -- file paths.
  ##
  ## Keyword Arguments:
  ## -   ``group_id`` -- id of the community on whose wall you want to upload the photo (without a minus sign).
  ## -   ``user_id`` -- id of the user whose wall you want to save the photo on.
  ## -   ``caption`` -- photo description text (maximum 2048 characters).
  var data = %*{}
  if group_id != 0:
    data["group_id"] = %group_id
  var response = await upl.upload_files(data, files, "photos.getWallUploadServer")

  var enddata = %*{
    "caption": %caption,
    "server": response["server"],
    "hash": response["hash"],
    "photo": response["photo"]
  }
  if user_id != 0:
    enddata["user_id"] = %user_id

  return await upl.callAPI("photos.saveWallPhoto", enddata)
