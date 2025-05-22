import 'package:test/test.dart';
import 'package:tiny_db/tiny_db.dart';

void main() {
  group('MemoryStorage', () {
    late MemoryStorage storage;

    setUp(() {
      storage = MemoryStorage();
    });

    test('initial read returns null', () async {
      expect(await storage.read(), isNull);
    });

    test('write and read data', () async {
      final testData = {
        'table1': {
          '1': {'name': 'Alice'},
        },
        '_default': {
          '10': {'value': 42},
        },
      };

      await storage.write(testData);
      final readData = await storage.read();

      expect(readData, isNotNull);
      expect(readData, equals(testData));

      expect(identical(readData, testData), isFalse);
      if (readData != null) {
        (readData['table1'] as Map)['1'] = {'name': 'Bob'};
        expect((testData['table1'] as Map)['1'], equals({'name': 'Alice'}));
      }
    });

    test('multiple writes overwrite previous data', () async {
      final data1 = {
        'table1': {
          '1': {'name': 'Data 1'},
        },
      };
      final data2 = {
        'table2': {
          '2': {'name': 'Data 2'},
        },
      };

      await storage.write(data1);
      var readData = await storage.read();
      expect(readData, equals(data1));

      await storage.write(data2);
      readData = await storage.read();
      expect(readData, equals(data2));
      expect(readData, isNot(equals(data1)));
    });

    test('close operation completes', () async {
      await storage.close();

      final testData = {'data': 'test'};
      await storage.write(testData);
      await storage.close();
      expect(await storage.read(), equals(testData));
    });

    test('clear operation removes all data', () async {
      final testData = {
        'table1': {
          '1': {'name': 'Alice'},
        },
      };
      await storage.write(testData);
      expect(await storage.read(), isNotNull);

      await storage.clear();
      expect(await storage.read(), isNull);
    });

    test('writing an empty map', () async {
      final emptyData = <String, dynamic>{};
      await storage.write(emptyData);
      final readData = await storage.read();
      expect(readData, equals(emptyData));
      expect(readData, isEmpty);
    });

    test('read returns a copy, not a reference', () async {
      final originalData = {
        'key': 'value',
        'nested': {'nKey': 'nValue'},
      };
      await storage.write(originalData);

      final data1 = await storage.read();
      final data2 = await storage.read();

      expect(data1, isNotNull);
      expect(data2, isNotNull);
      expect(
        identical(data1, data2),
        isFalse,
        reason: "Each read should return a new map instance.",
      );

      if (data1 != null) {
        data1['key'] = 'modified_value';
        (data1['nested'] as Map)['nKey'] = 'modified_nested_value';

        final freshRead = await storage.read();
        expect(freshRead?['key'], equals('value'));
        expect((freshRead?['nested'] as Map?)?['nKey'], equals('nValue'));
      }
    });

    test('write accepts a copy, not a reference', () async {
      final originalData = {
        'key': 'value',
        'nested': {'nKey': 'nValue'},
      };
      await storage.write(originalData);

      originalData['key'] = 'modified_after_write';
      (originalData['nested'] as Map)['nKey'] = 'modified_nested_after_write';

      final readData = await storage.read();
      expect(
        readData?['key'],
        equals('value'),
        reason:
            "Stored data should not be affected by changes to the original map after write.",
      );
      expect((readData?['nested'] as Map?)?['nKey'], equals('nValue'));
    });
  });
}
