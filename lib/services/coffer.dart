import 'package:coffer/models/file.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import '../models/folder.dart';

const String BaseUrl = 'https://stage.picsilver.net/api/libraries/1dbe6700-8230-11ea-8979-918be6c276d6';

class CofferApi {
  static Future<Folder> getRootFolder() async {
    try{
      http.Request request = _createRequest('GET', "$BaseUrl/folders?parent=");
      var res = await request.send();
      var res2 = await http.Response.fromStream(res);
      List folderArray = jsonDecode(res2.body);
      List<Folder> folders = folderArray.map((f) => Folder.fromJson(f)).toList();
      return folders[0];
    }
    catch (e) {
      print(e.toString());
      throw e;
    }
  }

  static Future<List<Folder>> getFolders(String parentId) async {
    try{
      http.Request request = _createRequest('GET', "$BaseUrl/folders?parent=$parentId");
      var res = await request.send();
      var res2 = await http.Response.fromStream(res);
      List folderArray = jsonDecode(res2.body);
      List<Folder> folders = folderArray.map((f) => Folder.fromJson(f)).toList();
      return folders;
    }
    catch (e) {
      print(e.toString());
      throw e;
    }
  }

  static Future<String> uploadImage(filename, folderId) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse("$BaseUrl/folders/$folderId/files"));
      request.headers['Authorization'] = 'ApiKey 123456'; 
      request.files.add(await http.MultipartFile.fromPath('files', filename));
      var res = await request.send();
      var res2 = await http.Response.fromStream(res);
      return  res2.reasonPhrase;
    }
    catch(e) {
      print(e.toString());
      throw e;
    }
  }

  static Future<List<File>> getFiles(String folderId) async {
    try{
      var request = _createRequest('GET', "$BaseUrl/folders/$folderId/files");
      request.headers['Authorization'] = 'ApiKey 123456'; 
      var res = await request.send();
      var res2 = await http.Response.fromStream(res);
      List fileArray = jsonDecode(res2.body);
      return fileArray.map((f) => File.fromJson(f)).toList();
    }
    catch (e) {
      print(e.toString());
      throw e;
    }
  }

  static Future<Uint8List> getFileThumbnail(String fileId) async {
    try{
      var request = _createRequest('GET', "$BaseUrl/files/$fileId/thumbnails/sm");
      request.headers['Authorization'] = 'ApiKey 123456'; 
      var res = await request.send();
      var res2 = await http.Response.fromStream(res);
      return res2.bodyBytes;
    }
    catch (e) {
      print(e.toString());
      throw e;
    }
  }

  static Future<Uint8List> getFileContents(String fileId) async {
    try{
      var request = _createRequest('GET', "$BaseUrl/files/$fileId/contents");
      request.headers['Authorization'] = 'ApiKey 123456'; 
      var res = await request.send();
      var res2 = await http.Response.fromStream(res);
      return res2.bodyBytes;
    }
    catch (e) {
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
