import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/file.dart';
import '../services/coffer.dart';

typedef ColorCallback = void Function(Color color);

/// Fetches a photo from the API and renders a clickable image.
class Picture extends StatefulWidget {
  const Picture({Key key, this.file, this.onTap}) : super(key: key);

  final File file;

  final void Function(File file) onTap;

  @override
  _PictureState createState() => _PictureState();
}

class _PictureState extends State<Picture> {
  Future<Uint8List> contents;

  @override
  void initState() {
    super.initState();
    this.contents = CofferApi.getFileThumbnail(
        this.widget.file.fileId, ThumbnailSizeMedium);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
        future: contents,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return GestureDetector(
                child: Image.memory(snapshot.data),
                onTap: () {
                  this.widget.onTap(this.widget.file);
                });
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }
          return CircularProgressIndicator();
        });
  }
}
