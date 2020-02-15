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
