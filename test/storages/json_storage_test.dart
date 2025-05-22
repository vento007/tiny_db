import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tiny_db/tiny_db.dart';

void main() {
  group('JsonStorage', () {
    late String testDirPath;
    late String testFilePath;
    late JsonStorage storage;

    setUp(() async {
      testDirPath = p.join(Directory.current.path, 'build', 'test_temp_dir');
      await Directory(testDirPath).create(recursive: true);
      testFilePath = p.join(testDirPath, 'test_db.json');
      storage = JsonStorage(testFilePath, createDirs: true, indentAmount: 2);
    });

    tearDown(() async {
      if (await Directory(testDirPath).exists()) {
        await Directory(testDirPath).delete(recursive: true);
      }
    });

    test('initial read from non-existent file returns null', () async {
      expect(await storage.read(), isNull);
    });

    test('write and read data successfully', () async {
      final data = {
        'table1': {
          'id1': {'name': 'Test User', 'age': 30},
        },
      };
      await storage.write(data);

      final file = File(testFilePath);
      expect(await file.exists(), isTrue);

      final readData = await storage.read();
      expect(readData, equals(data));
    });

    test('write with indentation', () async {
      final data = {'name': 'Indented JSON'};
      final indentedStorage = JsonStorage(testFilePath, indentAmount: 2);
      await indentedStorage.write(data);

      final fileContent = await File(testFilePath).readAsString();

      expect(fileContent, contains('{\n  "name": "Indented JSON"\n}'));
    });

    test('write without indentation', () async {
      final data = {'name': 'Flat JSON'};
      final flatStorage = JsonStorage(testFilePath);
      await flatStorage.write(data);

      final fileContent = await File(testFilePath).readAsString();
      expect(fileContent, equals('{"name":"Flat JSON"}'));
    });

    test('read from empty file returns null', () async {
      await File(testFilePath).writeAsString('');
      expect(await storage.read(), isNull);
    });

    test('read from malformed JSON throws CorruptStorageException', () async {
      await File(testFilePath).writeAsString('{"key": "value"');
      expect(() => storage.read(), throwsA(isA<CorruptStorageException>()));
    });

    test('read from non-map JSON throws CorruptStorageException', () async {
      await File(testFilePath).writeAsString('["list_item"]');
      expect(() => storage.read(), throwsA(isA<CorruptStorageException>()));
    });

    test('write overwrites existing file', () async {
      final initialData = {'version': 1};
      await storage.write(initialData);
      expect(await storage.read(), equals(initialData));

      final newData = {'version': 2, 'feature': 'new'};
      await storage.write(newData);
      expect(await storage.read(), equals(newData));
    });

    test('createDirs = true creates directories', () async {
      final deepDirPath = p.join(testDirPath, 'deep', 'dir');
      final deepFilePath = p.join(deepDirPath, 'deep_db.json');
      final deepStorage = JsonStorage(deepFilePath, createDirs: true);
      final data = {'message': 'hello from deep'};

      await deepStorage.write(data);
      expect(await File(deepFilePath).exists(), isTrue);
      expect(await deepStorage.read(), equals(data));
    });

    test('createDirs = false throws if directory does not exist', () async {
      final nonExistentDirPath = p.join(testDirPath, 'non_existent_dir');
      final filePath = p.join(nonExistentDirPath, 'db.json');
      final noCreateStorage = JsonStorage(filePath, createDirs: false);
      final data = {'message': 'wont write'};

      expect(
        () => noCreateStorage.write(data),
        throwsA(isA<StorageException>()),
      );
    });

    test('close operation completes without error', () async {
      await storage.write({'data': 'test'});
      await storage.close();

      expect(await storage.read(), isNotNull);
    });

    test('deleteFile removes the file', () async {
      await storage.write({'data': 'to be deleted'});
      expect(await File(testFilePath).exists(), isTrue);
      await (storage).deleteFile();
      expect(await File(testFilePath).exists(), isFalse);
    });

    test(
      'concurrent writes are serialized and data is consistent',
      () async {
        final List<Future<void>> writes = [];
        final int numWrites = 5;
        final Map<String, dynamic> finalExpectedData = {};

        for (int i = 0; i < numWrites; i++) {
          final data = {'key$i': 'value$i', 'common_key': 'final_value_$i'};

          if (i == numWrites - 1) {
            finalExpectedData.addAll(data);
          }

          writes.add(
            storage.write(
              data.map((key, value) => MapEntry(key, '$value write $i')),
            ),
          );
        }

        await Future.wait(writes);

        final readData = await storage.read();

        final lastDataWritten = {
          'key${numWrites - 1}': 'value${numWrites - 1} write ${numWrites - 1}',
          'common_key': 'final_value_${numWrites - 1} write ${numWrites - 1}',
        };
        expect(readData, equals(lastDataWritten));
      },
      timeout: Timeout(Duration(seconds: 10)),
    );

    test(
      'write with non-JSON serializable object throws StorageException',
      () async {
        final data = {'unsupported': NonJsonSerializable()};
        expect(
          () => storage.write(data),
          throwsA(
            isA<StorageException>().having(
              (e) => e.message,
              'message',
              contains('Failed to serialize data to JSON'),
            ),
          ),
        );
      },
    );
  });
}

class NonJsonSerializable {
  final String data = "This can't be auto-serialized to JSON";
}
