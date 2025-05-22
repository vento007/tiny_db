class TempDirectory {
  final String path;
  TempDirectory(this.path);
}

Future<TempDirectory> getTemporaryDirectory() async {
  return TempDirectory('web-memory');
}
