import 'package:test/test.dart';
import 'package:tiny_db/tiny_db.dart';

void main() {
  group('TinyDb', () {
    late MemoryStorage storage;
    late TinyDb db;

    setUp(() {
      storage = MemoryStorage();
      db = TinyDb(storage);
    });

    tearDown(() async {
      await db.close();
    });

    test('table() returns a Table instance and caches it', () {
      final table1 = db.table('users');
      final table2 = db.table('users');
      final table3 = db.table('posts');

      expect(table1, isA<Table>());
      expect(table1.name, equals('users'));
      expect(table2, same(table1), reason: "Should return cached instance");
      expect(table3, isA<Table>());
      expect(table3.name, equals('posts'));
      expect(table3, isNot(same(table1)));
    });

    test('defaultTable getter returns the default table instance', () {
      final defTable = db.defaultTable;
      expect(defTable, isA<Table>());
      expect(defTable.name, equals(defaultTableName));
      expect(db.table(defaultTableName), same(defTable));
    });

    test(
      'close() closes the storage and prevents further operations',
      () async {
        await db.close();

        expect(() => db.table('new_items'), throwsStateError);
        expect(() => db.insert({'a': 1}), throwsStateError);
        expect(() => db.all(), throwsStateError);
        expect(() => db.tables(), throwsStateError);
        expect(() => db.dropTable('items'), throwsStateError);
        expect(() => db.dropTables(), throwsStateError);
      },
    );

    test('tables() returns set of table names from storage', () async {
      await db.table('table1').insert({'id': 1});
      await db.table('table2').insert({'id': 2});

      final tableNames = await db.tables();
      expect(tableNames, isA<Set<String>>());
      expect(tableNames, containsAll(['table1', 'table2']));
      expect(tableNames.length, 2);

      await db.dropTables();
      expect(await db.tables(), isEmpty);
    });

    test('dropTable() removes a specific table', () async {
      final usersTable = db.table('users');
      await usersTable.insert({'name': 'Alice'});
      db.table('posts');
      await db.table('comments').insert({'text': 'hi'});

      var currentTables = await db.tables();
      expect(currentTables, containsAll(['users', 'comments']));
      expect(currentTables, isNot(contains('posts')));

      var result = await db.dropTable('users');
      expect(result, isTrue);
      currentTables = await db.tables();
      expect(currentTables, isNot(contains('users')));
      expect(currentTables, contains('comments'));

      final newUsersTableInstance = db.table('users');
      expect(
        await newUsersTableInstance.length,
        0,
        reason: "Dropped table should be empty if re-accessed",
      );

      result = await db.dropTable('non_existent');
      expect(result, isFalse);

      await db.insert({'data': 'default_data'});
      expect(await db.tables(), contains(defaultTableName));
      result = await db.dropTable(defaultTableName);
      expect(result, isTrue);
      expect(await db.tables(), isNot(contains(defaultTableName)));
    });

    test('dropTables() removes all tables', () async {
      await db.table('t1').insert({'a': 1});
      await db.table('t2').insert({'b': 2});

      expect((await db.tables()).length, 2);

      await db.dropTables();
      expect(await db.tables(), isEmpty);

      final rawStorage = await storage.read();
      expect(rawStorage, equals({}));

      final t1AfterDrop = db.table('t1');
      expect(await t1AfterDrop.length, 0);
    });

    group('Default Table Proxy Methods', () {
      test('insert() proxies to defaultTable', () async {
        final id = await db.insert({'item': 'proxied_insert'});
        expect(id, 1);
        final doc = await db.defaultTable.getById(id);
        expect(doc, isNotNull);
        expect(doc!['item'], 'proxied_insert');
      });

      test('insertMultiple() proxies to defaultTable', () async {
        final ids = await db.insertMultiple([
          {'item': 'multi1'},
          {'item': 'multi2'},
        ]);
        expect(ids, orderedEquals([1, 2]));
        expect(await db.defaultTable.length, 2);
      });

      test('all() proxies to defaultTable', () async {
        await db.insert({'item': 'item1'});
        final allDocs = await db.all();
        expect(allDocs.length, 1);
        expect(allDocs[0]['item'], 'item1');
      });

      test('getById() proxies to defaultTable', () async {
        final id = await db.insert({'item': 'item_for_id'});
        final doc = await db.getById(id);
        expect(doc, isNotNull);
        expect(doc!['item'], 'item_for_id');
      });

      test('length proxies to defaultTable.length', () async {
        expect(await db.length, 0);
        await db.insert({'a': 1});
        expect(await db.length, 1);
      });

      test('isEmpty proxies to defaultTable.isEmpty', () async {
        expect(await db.isEmpty, isTrue);
        await db.insert({'a': 1});
        expect(await db.isEmpty, isFalse);
      });
      test('isNotEmpty proxies to defaultTable.isNotEmpty', () async {
        expect(await db.isNotEmpty, isFalse);
        await db.insert({'a': 1});
        expect(await db.isNotEmpty, isTrue);
      });

      test('truncate() proxies to defaultTable.truncate()', () async {
        await db.insert({'a': 1});
        expect(await db.length, 1);
        await db.truncate();
        expect(await db.length, 0);
      });
    });

    test('operations throw StateError after close', () async {
      await db.close();
      expect(() => db.table('any'), throwsStateError);
      expect(() => db.tables(), throwsStateError);
      expect(() => db.defaultTable, throwsStateError);
      expect(() => db.insert({}), throwsStateError);
      expect(() => db.insertMultiple([]), throwsStateError);
      expect(() => db.all(), throwsStateError);
      expect(() => db.getById(1), throwsStateError);
      expect(() => db.length, throwsStateError);
      expect(() => db.isEmpty, throwsStateError);
      expect(() => db.isNotEmpty, throwsStateError);
      expect(() => db.truncate(), throwsStateError);
      expect(() => db.dropTable('any'), throwsStateError);
      expect(() => db.dropTables(), throwsStateError);
    });

    test('db.close() calls storage.close()', () async {
      final mockStorage = MockStorage();
      final testDb = TinyDb(mockStorage);
      await testDb.close();
      expect(mockStorage.closeCalled, isTrue);
    });
  });
}

class MockStorage implements Storage {
  Map<String, dynamic>? _memory;
  bool closeCalled = false;
  bool writeCalled = false;
  Map<String, dynamic>? lastWrittenData;

  @override
  Future<void> close() async {
    closeCalled = true;
  }

  @override
  Future<Map<String, dynamic>?> read() async {
    return _memory == null ? null : Map.from(_memory!);
  }

  @override
  Future<void> write(Map<String, dynamic> data) async {
    writeCalled = true;
    lastWrittenData = Map.from(data);
    _memory = lastWrittenData;
  }
}
