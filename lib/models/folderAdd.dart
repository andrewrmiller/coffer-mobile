class FolderAdd {
  final String parentId;
  final String name;

  FolderAdd(String parentId, String name)
      : this.parentId = parentId,
        this.name = name;

  Map<String, dynamic> toJson() {
    return {'parentId': parentId, 'name': name};
  }
}
