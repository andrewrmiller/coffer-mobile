import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stack/stack.dart' as StackClass;
import 'models/album.dart';
import 'models/folder.dart';
import 'models/file.dart';
import 'services/coffer.dart';
import 'widgets/picture.dart';
import 'widgets/picture_carousel.dart';
import 'synchronizer.dart';

enum View { Folder, Album }

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coffer Photos',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blueGrey,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Coffer Photos'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final picker = ImagePicker();
  View view = View.Folder;
  StackClass.Stack<Folder> navStack = StackClass.Stack();
  Future<List<Folder>> subFolders;
  Future<Folder> currentFolder;
  Future<List<Album>> albums;
  Future<Album> currentAlbum;
  Future<List<File>> files;

  void _handleAllPhotosTap() async {
    var folder = await this.currentFolder;
    setState(() {
      this.view = View.Folder;
      this.subFolders = CofferApi.getFolders(folder.folderId);
      this.files = CofferApi.getFiles(folder.folderId);
      this.albums = Future<List<Album>>.value([]);
    });
    Navigator.of(context).pop();
  }

  void _handleAlbumsTap() async {
    setState(() {
      this.view = View.Album;
      this.albums = CofferApi.getAlbums();
      this.files = Future<List<File>>.value([]);
      this.subFolders = Future<List<Folder>>.value([]);
    });
    Navigator.of(context).pop();
  }

  void _handleSyncTap() async {
    Synchronizer.synchronize();
  }

  void _handleBackTap() async {
    this.setState(() {
      if (view == View.Folder) {
        Folder lastFolder = this.navStack.pop();
        this.currentFolder = Future<Folder>.sync(() => lastFolder);
        this.currentFolder.then((folder) {
          this.subFolders = CofferApi.getFolders(folder.folderId);
          this.files = CofferApi.getFiles(folder.folderId);
        });
      } else {
        this.albums = CofferApi.getAlbums();
        this.currentAlbum = Future<Album>.value(null);
        this.files = Future<List<File>>.value([]);
      }
    });
  }

  void _handlePictureTap(File file) async {
    var folder = await this.currentFolder;
    var fileList = await this.files;
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => PictureCarousel(title: folder.name, files: fileList, selected: file)));
  }

  Widget _createScrollableWidget() {
    return FutureBuilder(
      future: Future.wait([subFolders, files, albums]),
      builder: (context, snapshot) {
        List<Widget> slivers = new List<Widget>();
        if (snapshot.hasData) {
          List<Folder> folders = snapshot.data[0];
          List<File> files = snapshot.data[1];
          List<Album> albums = snapshot.data[2];

          slivers.add(SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 3),
              delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
                return _createFolderWidget(folders[index]);
              }, childCount: folders.length)));

          slivers.add(SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 3),
              delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
                return _createAlbumWidget(albums[index]);
              }, childCount: albums.length)));

          slivers.add(SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4, childAspectRatio: 1),
              delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
                return new Picture(file: files[index], onTap: _handlePictureTap);
              }, childCount: files.length)));
        } else if (snapshot.hasError) {
          print(snapshot.error);
          return Text("${snapshot.error}");
        } else {
          slivers.add(SliverToBoxAdapter(
            child: Container(),
          ));
        }

        return CustomScrollView(
          slivers: slivers,
        );
      },
    );
  }

  Widget _createFolderWidget(Folder folder) {
    return new GestureDetector(
        child: Container(color: Colors.yellow, child: Column(children: [Text(folder.name)])),
        onTap: () async {
          Folder oldFolder = await currentFolder;
          Future<List<Folder>> subFolders = CofferApi.getFolders(folder.folderId);
          Future<List<File>> files = CofferApi.getFiles(folder.folderId);

          setState(() {
            this.navStack.push(oldFolder);
            this.currentFolder = Future<Folder>.sync(() => folder);
            this.subFolders = subFolders;
            this.files = files;
          });
        });
  }

  Widget _createAlbumWidget(Album album) {
    return new GestureDetector(
        child: Container(color: Colors.orangeAccent, child: Column(children: [Text(album.name)])),
        onTap: () async {
          Future<List<File>> files = CofferApi.getAlbumFiles(album.albumId);

          setState(() {
            this.currentAlbum = Future<Album>.sync(() => album);
            this.albums = Future<List<Album>>.value([]);
            this.files = files;
          });
        });
  }

  @override
  void initState() {
    super.initState();
    this.currentFolder = CofferApi.getRootFolder().then((folder) {
      setState(() {
        subFolders = CofferApi.getFolders(folder.folderId);
        files = CofferApi.getFiles(folder.folderId);
        albums = Future<List<Album>>.value([]);
        currentAlbum = Future<Album>.value(null);
      });
      return folder;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: FutureBuilder(
            future: currentAlbum,
            builder: (context, snapshot) {
              return Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                if (this.navStack.isEmpty && snapshot.data == null)
                  GestureDetector(
                      child: Icon(Icons.menu),
                      onTap: () {
                        Scaffold.of(context).openDrawer();
                      }),
                if (this.navStack.isNotEmpty || snapshot.data != null)
                  GestureDetector(child: Icon(Icons.arrow_back), onTap: _handleBackTap),
              ]);
            }),
        title: FutureBuilder(
            future: Future.wait([currentFolder, currentAlbum]),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                if (view == View.Folder) {
                  return Text(snapshot.data[0].name);
                } else {
                  var album = snapshot.data[1];
                  if (album == null) {
                    return Text('Albums');
                  } else {
                    return Text(snapshot.data[1].name);
                  }
                }
              } else if (snapshot.hasError) {
                return Text("${snapshot.error}");
              }
              return Container();
            }),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Container(
                height: 90.0,
                child: DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.grey,
                  ),
                  child: Text(
                    'Coffer Photos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                )),
            ListTile(
              leading: Icon(Icons.photo),
              title: Text('All Photos'),
              onTap: _handleAllPhotosTap,
            ),
            ListTile(
              leading: Icon(Icons.photo_album),
              title: Text('Albums'),
              onTap: _handleAlbumsTap,
            ),
            ListTile(
              leading: Icon(Icons.sync),
              title: Text('Synchronize'),
              onTap: _handleSyncTap,
            ),
          ],
        ),
      ),
      body: Center(
        child: FutureBuilder<Folder>(
            future: currentFolder,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return _createScrollableWidget();
              } else if (snapshot.hasError) {
                return Text("${snapshot.error}");
              }
              return Container();
            }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          var targetFolder = await currentFolder;
          var file = await picker.getImage(source: ImageSource.gallery);
          var res = await CofferApi.uploadImage(file.path, targetFolder.folderId);
          setState(() {
            print(res);
          });
        },
        tooltip: 'Upload',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
