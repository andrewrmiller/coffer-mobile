import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'models/folder.dart';
import 'models/file.dart';
import 'services/coffer.dart';
import 'widgets/picture.dart';

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
        primarySwatch: Colors.green,
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
  String state = "Nothing yet!";
  Future<Folder> currentFolder;
  Future<List<Folder>> subFolders;
  Future<List<File>> files;
  

  Widget createFolderWidget(Folder folder) {
    return new Container(
      color: Colors.yellow,
      child: Column(
        children: [
          GestureDetector(
            child: Text(folder.name),
            onTap: () {
              setState(() {
                this.currentFolder = Future<Folder>.sync(() => folder);
                this.currentFolder.then((folder) {
                  setState(() {
                    this.subFolders = CofferApi.getFolders(folder.folderId);
                    this.files = CofferApi.getFiles(folder.folderId);
                  });
                });
              });
          })]
      )
    );
  }

  @override
  void initState() {
    super.initState();
    this.currentFolder = CofferApi.getRootFolder().then((folder) {
      setState(() {
        subFolders = CofferApi.getFolders(folder.folderId);
        files = CofferApi.getFiles(folder.folderId);
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
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title:           
          FutureBuilder<Folder>(
            future: currentFolder, 
            builder:(context, snapshot) {
              if (snapshot.hasData) {
                return Text(snapshot.data.name);
              } else if (snapshot.hasError) {
                return Text("${snapshot.error}");
              }
              return CircularProgressIndicator();
            }
          ),
      ),
      body: Center(
        child:
          Column(children: <Widget>[
            FutureBuilder<List<Folder>>(
              future: subFolders, 
              builder:(context, snapshot) {
                if (snapshot.hasData) {
                  var folders = snapshot.data;
                  return Wrap(
                    spacing: 8.0,
                    children: folders.map((f) => createFolderWidget(f)).toList()
                  );
                } else if (snapshot.hasError) {
                  return Text("${snapshot.error}");
                }
                return CircularProgressIndicator();
              }
            ),

            FutureBuilder<List<File>>(
              future: files, 
              builder:(context, snapshot) {
                if (snapshot.hasData) {
                  var folders = snapshot.data;
                  return Wrap(
                    spacing: 8.0,
                    children: folders.map((f) => new Picture(file: f)).toList()
                  );
                } else if (snapshot.hasError) {
                  return Text("${snapshot.error}");
                }
                return CircularProgressIndicator();
              }
            ),

          ],)
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          var targetFolder = await currentFolder;
          var file = await picker.getImage(source: ImageSource.gallery);
          var res = await CofferApi.uploadImage(file.path, targetFolder.folderId);
          setState(() {
            state = res;
            print(res);
          });
        },
        tooltip: 'Upload',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
