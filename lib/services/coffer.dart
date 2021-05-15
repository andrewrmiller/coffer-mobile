import 'package:coffer/models/file.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' as io;
import '../models/album.dart';
import '../models/folder.dart';
import '../models/folderAdd.dart';

const String BaseUrl =
    'https://stage.picsilver.net/api/libraries/1dbe6700-8230-11ea-8979-918be6c276d6';

const ThumbnailSizeSmall = "sm";
const ThumbnailSizeMedium = "md";
const ThumbnailSizeLarge = "lg";

class CofferApi {
  static Future<Folder> getRootFolder() async {
    try {
      http.Request request = _createRequest('GET', "$BaseUrl/folders?parent=");
      var stream = await request.send();
      var response = await http.Response.fromStream(stream);
      List folderArray = jsonDecode(response.body);
      List<Folder> folders = folderArray.map((f) => Folder.fromJson(f)).toList();
      return folders[0];
    } catch (e) {
      print(e.toString());
      throw e;
    }
  }

  static Future<List<Folder>> getFolders(String parentId) async {
    try {
      http.Request request = _createRequest('GET', "$BaseUrl/folders?parent=$parentId");
      var stream = await request.send();
      var response = await http.Response.fromStream(stream);
      List folderArray = jsonDecode(response.body);
      List<Folder> folders = folderArray.map((f) => Folder.fromJson(f)).toList();
      return folders;
    } catch (e) {
      print(e.toString());
      throw e;
    }
  }

  static Future<Folder> createFolder(String parentId, String name) async {
    try {
      http.Request request = _createRequest('POST', "$BaseUrl/folders");
      request.headers['Authorization'] = 'ApiKey 123456';
      request.headers['Content-Type'] = 'application/json';
      final folderAdd = FolderAdd(parentId, name);
      request.body = jsonEncode(folderAdd);
      var stream = await request.send();
      var response = await http.Response.fromStream(stream);
      Folder folder = Folder.fromJson(jsonDecode(response.body));
      return folder;
    } catch (e) {
      print(e.toString());
      throw e;
    }
  }

  static Future<String> uploadImage(String filename, String folderId) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse("$BaseUrl/folders/$folderId/files"));
      request.headers['Authorization'] = 'ApiKey 123456';
      request.files.add(await http.MultipartFile.fromPath('files', filename));
      var stream = await request.send();
      var response = await http.Response.fromStream(stream);
      return response.reasonPhrase;
    } catch (e) {
      print(e.toString());
      throw e;
    }
  }

  static Future<File> uploadFile(io.File file, String filename, String folderId) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse("$BaseUrl/folders/$folderId/files"));
      request.headers['Authorization'] = 'ApiKey 123456';
      final bytes = await file.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('files', bytes, filename: filename));
      final stream = await request.send();
      final response = await http.Response.fromStream(stream);
      List fileArray = jsonDecode(response.body);
      File result = File.fromJson(fileArray[0]);
      return result;
    } catch (e) {
      print(e.toString());
      throw e;
    }
  }

  static Future<List<File>> getFiles(String folderId) async {
    try {
      var request = _createRequest('GET', "$BaseUrl/folders/$folderId/files");
      var stream = await request.send();
      var response = await http.Response.fromStream(stream);
      List fileArray = jsonDecode(response.body);
      return fileArray.map((f) => File.fromJson(f)).toList();
    } catch (e) {
      print(e.toString());
      throw e;
    }
  }

  static Future<List<Album>> getAlbums() async {
    try {
      http.Request request = _createRequest('GET', "$BaseUrl/albums");
      var stream = await request.send();
      var response = await http.Response.fromStream(stream);
      List albumArray = jsonDecode(response.body);
      List<Album> albums = albumArray.map((f) => Album.fromJson(f)).toList();
      return albums;
    } catch (e) {
      print(e.toString());
      throw e;
    }
  }

  static Future<List<File>> getAlbumFiles(String albumName) async {
    try {
      var request = _createRequest('GET', "$BaseUrl/albums/$albumName/files");
      var stream = await request.send();
      var response = await http.Response.fromStream(stream);
      List fileArray = jsonDecode(response.body);
      return fileArray.map((f) => File.fromJson(f)).toList();
    } catch (e) {
      print(e.toString());
      throw e;
    }
  }

  static Future<Uint8List> getFileThumbnail(String fileId, String thumbnailSize) async {
    try {
      var request = _createRequest('GET', "$BaseUrl/files/$fileId/thumbnails/$thumbnailSize");
      var stream = await request.send();
      var response = await http.Response.fromStream(stream);
      return response.bodyBytes;
    } catch (e) {
      print(e.toString());
      throw e;
    }
  }

  static Future<Uint8List> getFileContents(String fileId) async {
    try {
      var request = _createRequest('GET', "$BaseUrl/files/$fileId/contents");
      var stream = await request.send();
      var response = await http.Response.fromStream(stream);
      return response.bodyBytes;
    } catch (e) {
      print(e.toString());
      throw e;
    }
  }

  static http.Request _createRequest(String method, String url) {
    http.Request request = http.Request(method, Uri.parse(url));
    request.headers['Authorization'] = 'ApiKey 123456';
    return request;
  }
}
