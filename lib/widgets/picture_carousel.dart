import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:wakelock/wakelock.dart';
import '../services/coffer.dart';
import '../models/file.dart';

/// Widget that renders a scrollable carousel of pictures.
class PictureCarousel extends StatefulWidget {
  PictureCarousel({Key key, this.title, this.files, this.selected})
      : super(key: key);

  final String title;

  final File selected;

  final List<File> files;

  @override
  _PictureCarouselState createState() => _PictureCarouselState();
}

class _PictureCarouselState extends State<PictureCarousel> {
  Map<String, Future<Uint8List>> fileContents;

  bool autoPlay;

  @override
  void initState() {
    super.initState();
    setState(() {
      autoPlay = false;
    });
    this.fileContents = new Map<String, Future<Uint8List>>();
  }

  void _toggleSlideShow() async {
    setState(() {
      autoPlay = !this.autoPlay;
    });
    if (this.autoPlay) {
      SystemChrome.setEnabledSystemUIOverlays([]);
      Wakelock.enable();
    } else {
      SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
      Wakelock.disable();
    }
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
      appBar: this.autoPlay
          ? null
          : AppBar(
              title: Text(this.widget.title),
              actions: <Widget>[
                Padding(
                    padding: EdgeInsets.only(right: 20.0),
                    child: GestureDetector(
                      onTap: _toggleSlideShow,
                      child: Icon(
                        this.autoPlay ? Icons.stop : Icons.slideshow,
                        size: 26.0,
                      ),
                    )),
              ],
            ),
      body: GestureDetector(
          onTap: _toggleSlideShow,
          child: Center(
              child: CarouselSlider.builder(
            itemCount: this.widget.files.length,
            options: CarouselOptions(
                height: 900.0,
                enableInfiniteScroll: false,
                autoPlay: this.autoPlay,
                enlargeCenterPage: true,
                initialPage: this.widget.files.indexOf(this.widget.selected)),
            itemBuilder: (context, index) =>
                this._getImageWidget(this.widget.files[index].fileId),
          ))),
    );
  }
}
