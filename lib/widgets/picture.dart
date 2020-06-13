
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/file.dart';
import '../services/coffer.dart';

class Picture extends StatefulWidget {
  const Picture({Key key, this.file}) : super(key: key);

  final File file;

  @override
  _PictureState createState() => _PictureState();
}

class _PictureState extends State<Picture> {

  Future<Uint8List> contents;

  @override
  void initState() {
    super.initState();
    this.contents = CofferApi.getFileThumbnail(this.widget.file.fileId);
  }

  @override
  Widget build(BuildContext context) {
    return 
      FutureBuilder<Uint8List>(
        future: contents, 
        builder:(context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(snapshot.data);
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }
          return CircularProgressIndicator();
        }
      );
  }
}
