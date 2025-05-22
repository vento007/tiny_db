import 'package:flutter/foundation.dart' show kIsWeb;

import 'dart:io' if (dart.library.js) 'web_file_stub.dart';

import 'package:path_provider/path_provider.dart'
    if (dart.library.js) 'web_path_provider_stub.dart';

class FileSystem {
  static Future<String> getTempPath() async {
    if (kIsWeb) {
      return 'web-memory';
    } else {
      final tempDir = await getTemporaryDirectory();
      return tempDir.path;
    }
  }

  static Future<void> createDirectory(String path) async {
    if (!kIsWeb) {
      final dir = Directory(path);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    }
  }

  static Future<bool> fileExists(String path) async {
    if (kIsWeb) {
      return false;
    } else {
      final file = File(path);
      return await file.exists();
    }
  }

  static Future<void> deleteFile(String path) async {
    if (!kIsWeb) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  static Future<String> readFileAsString(String path) async {
    if (kIsWeb) {
      throw UnsupportedError('File reading not supported on web');
    } else {
      final file = File(path);
      return await file.readAsString();
    }
  }
}
