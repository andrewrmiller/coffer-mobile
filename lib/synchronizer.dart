import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:photo_manager/photo_manager.dart';
import 'services/coffer.dart';

const PageSize = 20;

// https://flutter.dev/docs/cookbook/persistence/sqlite

class Synchronizer {
  static void synchronize() async {
    final db = await Synchronizer._openDatabase();
    final syncStatusRows = await db.query("sync_status");
    int currentPage = syncStatusRows[0]['current_page'];

    // Are we starting a synchronization pass?  If so, mark all of the files as
    // "not seen".  We'll use this at the end to figure out what files to delete.
    if (currentPage == 0) {
      await db.execute("UPDATE files SET seen = 0");
    }

    // Get the "recent" album which contains all photos and videos on the device.
    List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(onlyAll: true);

    // Page through the assets in the "recent" album.
    bool uploadedFiles = false;
    List<AssetEntity> assetList = await albums.first.getAssetListPaged(currentPage, PageSize);
    while (assetList.length > 0) {
      // See if the assets in this page need to be uploaded.
      for (final asset in assetList) {
        final file = await asset.file;

        // TODO: Check to see if the file is in the database.  If not, mark the
        // file as "seen" and move on.

        final reason = await Synchronizer._uploadFile(file, asset.title);
        uploadedFiles = true;
      }

      // If we uploaded any files for this page, then we are done for now.  We will pick up
      // where we left off the next time synchronize() is called.
      if (uploadedFiles) {
        return;
      }

      currentPage++;
      await db.execute("UPDATE sync_status SET current_page = " + currentPage.toString());
      assetList = await albums.first.getAssetListPaged(currentPage, PageSize);
    }

    // Remove files from the service that are no loner on the device.
    // TODO: Second loop:
    // Loop through all files in the database where seen = false.
    // These files need to be deleted from the service.
  }

  static Future<Database> _openDatabase() async {
    // Open the database and store the reference.
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

  static Future<String> _uploadFile(File file, String filename) {
    // TODO: Pass mimetype up here.
    return CofferApi.uploadFile(file, filename, '01c8e8d2-8d07-4556-abc4-eea4d5173729');

    // TODO: If the file was uploaded successfully udpate the database.
  }
}
