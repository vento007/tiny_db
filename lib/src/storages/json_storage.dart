import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mutex/mutex.dart';
import 'package:path/path.dart' as p;

import '../common/exceptions.dart';
import 'storage.dart';

class JsonStorage extends Storage {
  final String path;
  final bool createDirs;
  final Encoding encoding;
  final String? indent;

  final Mutex _mutex = Mutex();

  JsonStorage(
    this.path, {
    this.createDirs = false,
    this.encoding = utf8,
    int? indentAmount,
  }) : indent = indentAmount == null ? null : ' ' * indentAmount;

  Future<void> _ensureDirectoriesExist() async {
    if (createDirs) {
      final dirPath = p.dirname(path);
      final directory = Directory(dirPath);
      if (!await directory.exists()) {
        try {
          await directory.create(recursive: true);
        } on FileSystemException catch (e) {
          throw StorageException(
            'Failed to create directories for $path: ${e.message}',
          );
        }
      }
    }
  }

  @override
  Future<Map<String, dynamic>?> read() async {
    return _mutex.protect<Map<String, dynamic>?>(() async {
      final file = File(path);

      try {
        if (!await file.exists()) {
          return null;
        }

        final content = await file.readAsString(encoding: encoding);
        if (content.isEmpty) {
          return null;
        }

        final decodedData = json.decode(content);
        if (decodedData is Map<String, dynamic>) {
          return decodedData;
        } else {
          throw CorruptStorageException(
            'Invalid data format: Expected a JSON object (Map<String, dynamic>), '
            'but found ${decodedData.runtimeType} in $path',
          );
        }
      } on FileSystemException catch (e) {
        throw StorageException('Failed to read from $path: ${e.message}');
      } on FormatException catch (e) {
        throw CorruptStorageException(
          'Failed to parse JSON from $path: ${e.message}',
        );
      }
    });
  }

  @override
  Future<void> write(Map<String, dynamic> data) async {
    await _mutex.protect(() async {
      await _ensureDirectoriesExist();

      final file = File(path);
      try {
        final encoder =
            indent == null ? JsonEncoder() : JsonEncoder.withIndent(indent);
        final jsonString = encoder.convert(data);
        await file.writeAsString(
          jsonString,
          encoding: encoding,
          flush: true,
          mode: FileMode.write,
        );
      } on FileSystemException catch (e) {
        throw StorageException('Failed to write to $path: ${e.message}');
      } on JsonUnsupportedObjectError catch (e) {
        throw StorageException(
          'Failed to serialize data to JSON for $path: ${e.toString()}',
        );
      }
    });
  }

  @override
  Future<void> close() async {
    await _mutex.protect(() async {});
  }

  Future<void> deleteFile() async {
    await _mutex.protect(() async {
      final file = File(path);
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } on FileSystemException catch (e) {
        throw StorageException('Failed to delete file $path: ${e.message}');
      }
    });
  }
}
