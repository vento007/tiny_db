class File {
  final String path;

  File(this.path);

  Future<bool> exists() async => false;
  Future<void> delete() async {}
  Future<String> readAsString() async => '';
}

class Directory {
  final String path;

  Directory(this.path);

  Future<bool> exists() async => false;
  Future<Directory> create({bool recursive = false}) async => this;
}
