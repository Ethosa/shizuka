# author: Ethosa
import httpclient
import asyncdispatch
import json

from utils import encode


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
    "https://api.vk.com/method/" & method_name & "?" & encode data
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
