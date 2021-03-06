import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate';
import 'package:device_info/device_info.dart';
import 'package:path/path.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tuple/tuple.dart';
import 'services/coffer.dart';
import 'models/folder.dart';
import 'models/file.dart' as ApiFile;

// This code should eventually be packaged up in an isolate so that it can run
// independent of the UI isolate.  For more information see these articles:
// https://medium.com/dartlang/dart-asynchronous-programming-isolates-and-event-loops-bffc3e296a6a#:~:text=An%20isolate%20is%20what%20all,that%20runs%20an%20event%20loop.
// https://hackernoon.com/an-introduction-to-dart-code-and-isolate-em3j34u1

// Longer term we'll probably want this to run even if the app is not running.
// These articles may help:
// https://flutter.dev/docs/development/packages-and-plugins/background-processes
// https://medium.com/flutter/executing-dart-in-the-background-with-flutter-plugins-and-geofencing-2b3e40a1a124

// Assets are read in PageSize chunks and uploaded to the Coffer service.
const PageSize = 20;

// https://flutter.dev/docs/cookbook/persistence/sqlite

class Synchronizer {
  static void synchronize(SendPort sendPort) async {
    final db = await Synchronizer._openDatabase();

    // Make sure the target folder exists.
    developer.log("Checking target folder.");
    final deviceName = await _getDeviceName();
    final deviceFolder = await _ensureDeviceFolder(deviceName);
    final deviceFolderId = deviceFolder.item1;

    // If we created a new target folder delete any previous synchronization
    // history.  The previous target folder may have been deleted.
    if (deviceFolder.item2) {
      developer.log('Target folder not found--clearing database.');
      await db.delete("files");
      await db.update("sync_status", {"current_page": 0});
    }

    final syncStatusRows = await db.query("sync_status");
    int currentPage = syncStatusRows[0]['current_page'];

    // Are we starting a synchronization pass?  If so, mark all of the files as
    // "not seen".  We'll use this at the end to figure out what files to delete.
    if (currentPage == 0) {
      await db.execute("UPDATE files SET seen = 0");
    }

    // Get the "recent" album which contains all photos and videos on the device.
    developer.log("Getting list of albums.");
    PhotoManager.setIgnorePermissionCheck(true);

    FilterOptionGroup filterOption = FilterOptionGroup(imageOption: FilterOption(needTitle: true));
    filterOption.addOrderOption(OrderOption(type: OrderOptionType.createDate, asc: true));
    List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(onlyAll: true, filterOption: filterOption);

    // Page through the assets in the "recent" album.
    bool uploadedFiles = false;
    developer.log("Fetching asset list page $currentPage.");
    List<AssetEntity> assetList = await albums.first.getAssetListPaged(currentPage, PageSize);
    while (assetList.length > 0) {
      // See if the assets in this page need to be uploaded.
      for (final asset in assetList) {
        developer.log("Processing asset");

        // If the file is already in the databsae then it has already been uploaded.
        // Mark the file as seen and move on.
        final result = await db.query("files", where: "id = ?", whereArgs: [asset.id]);
        if (result.length > 0) {
          developer.log("File ${asset.title} has already been uploaded.");
          Map<String, dynamic> dbFile = Map.from(result[0]);
          dbFile['seen'] = 1;
          db.update("files", dbFile, where: "id = ?", whereArgs: [asset.id]);
          sendPort.send('fileSynced');
          continue;
        }

        // We only upload images currently.
        if (asset.type != AssetType.image) {
          continue;
        }

        // https://github.com/CaiJingLong/flutter_photo_manager/issues/71
        developer.log("Getting file contents.");
        final file = await asset.file;

        try {
          // On iOS we have to use titleAsync to get the file title.
          developer.log("Getting title.");
          String title = asset.title;
          if (title == null || title.isEmpty) {
            title = await asset.titleAsync;
          }

          // If the file is an HEIC file we need to convert the filename.
          // The file we get back from asset.file is JPG not HEIC.
          if (title.endsWith(".HEIC")) {
            title = title.replaceAll(".HEIC", ".JPG");
          }

          await Synchronizer._uploadFile(file, title, deviceFolderId);
          final dbFile = {
            'id': asset.id,
            'seen': 1,
          };
          developer.log("Updating database");
          db.insert("files", dbFile);
          uploadedFiles = true;
        } finally {
          if (Platform.isIOS) {
            developer.log("Deleting file.");
            file.deleteSync();
          }
        }

        developer.log("Sending status");
        sendPort.send('fileSynced');
      }

      if (uploadedFiles) {
        // TODO: We uploaded some files, call back into the parent to see if we should continue.
        // return;
      }

      currentPage++;
      await db.execute("UPDATE sync_status SET current_page = " + currentPage.toString());
      developer.log("Fetching asset list page $currentPage.");
      assetList = await albums.first.getAssetListPaged(currentPage, PageSize);
    }

    // TODO: Update the database to indicate that we have fully processed the asset list.

    // Remove files from the service that are no longer on the device.
    // TODO: Second loop:
    // Loop through all files in the database where seen = false.
    // These files need to be deleted from the service.

    // TODO: Listen for camera events and restart sync if new files exist.
    // https://medium.com/@igaurab/event-channels-in-flutter-2b4d0db0ee4f

    await db.execute("UPDATE sync_status SET current_page = 0");
    developer.log("Terminating synchronization isolate.");
    sendPort.send('syncComplete');
  }

  static Future<Database> _openDatabase() async {
    // Open the database and store the reference.
    developer.log("Opening database.");
    return openDatabase(
      join(await getDatabasesPath(), 'coffer_sync_status.db'),
      onCreate: (db, version) async {
        await db.execute("CREATE TABLE files(id TEXT, seen INTEGER)");
        await db.execute('CREATE TABLE sync_status(current_page INTEGER)');
        return db.execute('INSERT INTO sync_status(current_page) VALUES(0)');
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 1,
    );
  }

  static Future<String> _getDeviceName() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      // https://developer.amazon.com/docs/fire-tablets/ft-identifying-tablet-devices.html
      if (androidInfo.manufacturer == "Amazon") {
        switch (androidInfo.model) {
          case 'T76N2B (3GB)':
          case 'T76N2P (4GB)':
          case 'KFMAWI':
          case 'KFSUWI':
          case 'KFTBWI':
            return "Amazon Fire HD 10 (${androidInfo.id})";

          case 'KFONWI':
          case 'KFKAWI':
          case 'KFDOWI':
          case 'KFGIWI':
          case 'KFMEWI':
            return "Amazon Fire HD 8 (${androidInfo.id})";
          default:
          // Fall through.
        }
      }
      return "${androidInfo.manufacturer} ${androidInfo.model} (${androidInfo.id})";
    } else {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.name;
    }
  }

  static Future<Tuple2<String, bool>> _ensureDeviceFolder(String deviceName) async {
    final rootFolder = await CofferApi.getRootFolder();
    final devicesFolder = await _ensureSubFolder(rootFolder.folderId, "Devices");
    final deviceFolder = await _ensureSubFolder(devicesFolder.item1.folderId, deviceName);
    return Tuple2(deviceFolder.item1.folderId, deviceFolder.item2);
  }

  static Future<Tuple2<Folder, bool>> _ensureSubFolder(String parentId, String name) async {
    final subFolders = await CofferApi.getFolders(parentId);
    bool created = false;
    Folder subFolder = subFolders.firstWhere((f) => f.name == name, orElse: () => null);
    if (subFolder == null) {
      subFolder = await CofferApi.createFolder(parentId, name);
      created = true;
    }
    return Tuple2(subFolder, created);
  }

  static Future<ApiFile.File> _uploadFile(File file, String filename, String folderId) {
    developer.log("Uploading file $filename...");
    // TODO: Pass mimetype up here.
    return CofferApi.uploadFile(file, filename, folderId);
  }
}
