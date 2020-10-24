import 'dart:typed_data';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import '../services/coffer.dart';
import '../models/file.dart';

/// Widget that renders a scrollable carousel of pictures.
class PictureCarousel extends StatefulWidget {
  PictureCarousel({Key key, this.title, this.files, this.selected}) : super(key: key);

  final String title;

  final File selected;

  final List<File> files;

  @override
  _PictureCarouselState createState() => _PictureCarouselState();
}

class _PictureCarouselState extends State<PictureCarousel> {
  Map<String, Future<Uint8List>> fileContents;

  @override
  void initState() {
    super.initState();
    this.fileContents = new Map<String, Future<Uint8List>>();
  }

  Widget _getImageWidget(String fileId) {
    if (!this.fileContents.containsKey(fileId)) {
      this.fileContents[fileId] =
          CofferApi.getFileThumbnail(fileId, ThumbnailSizeLarge);
    }

    Future<Uint8List> contents = this.fileContents[fileId];

    return FutureBuilder<Uint8List>(
        future: contents,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(snapshot.data);
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }
          return CircularProgressIndicator();
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(this.widget.title),
      ),
      body: Center(
          child: CarouselSlider.builder(
        itemCount: this.widget.files.length,
        options: CarouselOptions(
            height: 900.0,
            enableInfiniteScroll: false,
            initialPage: this.widget.files.indexOf(this.widget.selected)),
        itemBuilder: (context, index) =>
            this._getImageWidget(this.widget.files[index].fileId),
      )),
    );
  }
}
