
class Folder {
  final String folderId;
  final String name;


  Folder({this.folderId, this.name});

  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      folderId: json['folderId'],
      name: json['name']
    );
  }
}