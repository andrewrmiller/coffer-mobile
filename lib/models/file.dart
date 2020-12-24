class File {
  final String fileId;
  final String name;

  File({this.fileId, this.name});

  factory File.fromJson(Map<String, dynamic> json) {
    return File(fileId: json['fileId'], name: json['name']);
  }
}
