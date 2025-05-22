import 'package:test/test.dart';
import 'package:tiny_db/tiny_db.dart';

void main() {
  group('Table', () {
    late MemoryStorage storage;
    late Table table;
    const tableName = 'test_table';

    setUp(() {
      storage = MemoryStorage();
      table = Table(storage, tableName);
    });

    test('initial table is empty and has length 0', () async {
      expect(await table.length, 0);
      expect(await table.isEmpty, isTrue);
      expect(await table.isNotEmpty, isFalse);
      expect(await table.all(), isEmpty);
    });

    test('insert single document', () async {
      final doc = {'name': 'Alice', 'age': 30};
      final id = await table.insert(doc);

      expect(id, 1);
      expect(await table.length, 1);
      expect(await table.isEmpty, isFalse);

      final retrievedDoc = await table.getById(id);
      expect(retrievedDoc, isNotNull);
      expect(retrievedDoc!['name'], 'Alice');
      expect(retrievedDoc['age'], 30);
      expect(retrievedDoc['doc_id'], id);

      final allDocs = await table.all();
      expect(allDocs.length, 1);
      expect(allDocs[0]['doc_id'], id);
      expect(allDocs[0]['name'], 'Alice');

      final dbData = await storage.read();
      expect(dbData, isNotNull);
      expect(dbData![tableName], isNotNull);
      final storedDoc = dbData[tableName][id.toString()];
      expect(storedDoc, equals(doc));
    });

    test(
      'insert document with invalid type throws TypeError at runtime',
      () async {
        expect(
          () => table.insert('not a map' as dynamic),
          throwsA(isA<TypeError>()),
        );
      },
    );

    test('insert multiple documents', () async {
      final docs = [
        {'name': 'Bob', 'age': 24},
        {'name': 'Charlie', 'age': 35},
      ];
      final ids = await table.insertMultiple(docs);

      expect(ids, orderedEquals([1, 2]));
      expect(await table.length, 2);

      final doc1 = await table.getById(1);
      expect(doc1!['name'], 'Bob');
      expect(doc1['doc_id'], 1);

      final doc2 = await table.getById(2);
      expect(doc2!['name'], 'Charlie');
      expect(doc2['doc_id'], 2);

      final dbData = await storage.read();
      expect(dbData![tableName][1.toString()], equals(docs[0]));
      expect(dbData[tableName][2.toString()], equals(docs[1]));
    });

    test(
      'insertMultiple with empty list does nothing and returns empty list',
      () async {
        final ids = await table.insertMultiple([]);
        expect(ids, isEmpty);
        expect(await table.length, 0);
      },
    );

    test(
      'insertMultiple with list containing non-Map items causes runtime error',
      () async {
        final List<dynamic> docsWithInvalidItem = [
          {'name': 'Valid Document'},
          'not a map',
        ];
        expect(
          () => table.insertMultiple(docsWithInvalidItem as List<Document>),
          throwsA(isA<TypeError>()),
        );
      },
    );

    test('getById returns null for non-existent ID', () async {
      expect(await table.getById(99), isNull);
    });

    test('IDs are sequential and unique', () async {
      final id1 = await table.insert({'val': 1});
      final id2 = await table.insert({'val': 2});
      final id3 = await table.insert({'val': 3});

      expect(id1, 1);
      expect(id2, 2);
      expect(id3, 3);
    });

    test(
      'truncate clears all documents and resets ID counter implicitly',
      () async {
        await table.insert({'name': 'Data 1'});
        await table.insert({'name': 'Data 2'});
        expect(await table.length, 2);

        await table.truncate();
        expect(await table.length, 0);
        expect(await table.isEmpty, isTrue);
        expect(await table.all(), isEmpty);

        final dbData = await storage.read();
        expect(dbData, isNotNull);
        expect(dbData![tableName], isEmpty);

        final newId = await table.insert({'name': 'New Data'});
        expect(newId, 1, reason: "ID should restart after truncate");
        expect(await table.length, 1);
      },
    );

    test('operations on a table that was previously in storage', () async {
      final initialStorageData = {
        tableName: {
          '10': {'data': 'persisted_A', 'id_val': 10},
          '20': {'data': 'persisted_B', 'id_val': 20},
        },
      };
      await storage.write(initialStorageData);

      final newTableInstance = Table(storage, tableName);

      final allDocs = await newTableInstance.all();
      expect(allDocs.length, 2);
      expect(
        allDocs.any((d) => d['data'] == 'persisted_A' && d['doc_id'] == 10),
        isTrue,
      );
      expect(
        allDocs.any((d) => d['data'] == 'persisted_B' && d['doc_id'] == 20),
        isTrue,
      );

      final newId = await newTableInstance.insert({'newData': 'fresh'});
      expect(
        newId,
        21,
        reason: "_lastId should be initialized from max existing ID",
      );

      final newDoc = await newTableInstance.getById(newId);
      expect(newDoc!['newData'], 'fresh');
      expect(await newTableInstance.length, 3);
    });

    test('all() returns copies of documents, not references', () async {
      final doc = {
        'name': 'mutable',
        'details': {'key': 'original'},
      };
      final id = await table.insert(doc);

      final allDocs = await table.all();
      expect(allDocs.length, 1);
      final retrievedDoc = allDocs.first;

      retrievedDoc['name'] = 'mutated_name';
      (retrievedDoc['details'] as Map)['key'] = 'mutated_key';
      retrievedDoc['doc_id'] = 999;

      final freshAllDocs = await table.all();
      expect(freshAllDocs.first['name'], 'mutable');
      expect((freshAllDocs.first['details'] as Map)['key'], 'original');
      expect(freshAllDocs.first['doc_id'], id);

      final freshById = await table.getById(id);
      expect(freshById!['name'], 'mutable');
      expect((freshById['details'] as Map)['key'], 'original');
      expect(freshById['doc_id'], id);
    });

    test('getById() returns a copy of the document, not a reference', () async {
      final doc = {'name': 'isolated', 'value': 100};
      final id = await table.insert(doc);

      final retrievedDoc = await table.getById(id);
      expect(retrievedDoc, isNotNull);

      retrievedDoc!['name'] = 'modified_locally';
      retrievedDoc['value'] = 200;
      retrievedDoc['doc_id'] = 999;

      final freshDoc = await table.getById(id);
      expect(freshDoc, isNotNull);
      expect(freshDoc!['name'], 'isolated');
      expect(freshDoc['value'], 100);
      expect(freshDoc['doc_id'], id);
    });

    test(
      'insert stores a copy, not a reference to original input document',
      () async {
        final originalDoc = {
          'name': 'original_state',
          'nested': {'val': 1},
        };
        final id = await table.insert(originalDoc);

        originalDoc['name'] = 'modified_externally';
        (originalDoc['nested'] as Map)['val'] = 2;

        final retrievedDoc = await table.getById(id);
        expect(retrievedDoc, isNotNull);
        expect(retrievedDoc!['name'], 'original_state');
        expect((retrievedDoc['nested'] as Map)['val'], 1);
      },
    );

    test(
      'insert correctly handles documents with existing doc_id field',
      () async {
        final doc = {'name': 'Alice', 'age': 30, 'doc_id': 12345};
        final id = await table.insert(doc);

        expect(id, 1);

        final retrievedDoc = await table.getById(id);
        expect(retrievedDoc, isNotNull);
        expect(retrievedDoc!['name'], 'Alice');
        expect(retrievedDoc['age'], 30);
        expect(retrievedDoc['doc_id'], id);
        expect(retrievedDoc['doc_id'], isNot(12345));

        final dbData = await storage.read();
        final storedDocData =
            dbData![tableName][id.toString()] as Map<String, dynamic>;
        expect(
          storedDocData['doc_id'],
          12345,
          reason:
              "Original doc_id field in data should be preserved in storage",
        );
      },
    );
  });
}
