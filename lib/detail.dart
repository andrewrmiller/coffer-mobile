import 'dart:typed_data';
import 'package:flutter/material.dart';
import './services/coffer.dart';

class PictureDetail extends StatefulWidget {
  PictureDetail({Key key, this.fileId}) : super(key: key);

  final String fileId;

  @override 
  _PictureDetailState createState() => _PictureDetailState();
}

class _PictureDetailState extends State<PictureDetail> {

  Future<Uint8List> contents;

  @override
  void initState() {
    super.initState();
    this.contents = CofferApi.getFileThumbnail(this.widget.fileId, ThumbnailSizeLarge);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Photo Detail"),
      ),
      body: Center(
        child: 
          FutureBuilder<Uint8List>(
            future: contents, 
            builder:(context, snapshot) {
              if (snapshot.hasData) {
                return GestureDetector(
                  child: Image.memory(snapshot.data),
                  onPanUpdate: (details) {
                    if (details.delta.dx > 0) {
                      // swiping right
                    } else if (details.delta.dx < 0) {
                      // swiping left
                    }
                  }
                );
              } else if (snapshot.hasError) {
                return Text("${snapshot.error}");
              }
              return CircularProgressIndicator();
            }
          ),
      ),
    );
  }
}
