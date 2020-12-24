class Album {
  final String albumId;
  final String name;

  Album({this.albumId, this.name});

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(albumId: json['albumId'], name: json['name']);
  }
}
