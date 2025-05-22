import 'package:test/test.dart';
import 'package:tiny_db/tiny_db.dart';

void main() {
  group('Table Remove Operations', () {
    late MemoryStorage storage;
    late Table table;
    const tableName = 'test_remove_table';

    Future<void> populateTableForRemoveTests(Table currentTable) async {
      await currentTable.insertMultiple([
        {'id_field': 1, 'name': 'Alice', 'type': 'A', 'value': 10},
        {'id_field': 2, 'name': 'Bob', 'type': 'B', 'value': 20},
        {'id_field': 3, 'name': 'Charlie', 'type': 'A', 'value': 30},
        {'id_field': 4, 'name': 'David', 'type': 'C', 'value': 40},
        {'id_field': 5, 'name': 'Alice', 'type': 'B', 'value': 50},
      ]);
    }

    group('remove(QueryCondition)', () {
      setUp(() async {
        storage = MemoryStorage();
        table = Table(storage, tableName);
        await populateTableForRemoveTests(table);
      });

      test('removes a single document matching a query', () async {
        final removedIds = await table.remove(where('name').equals('Bob'));

        expect(removedIds, hasLength(1));
        expect(removedIds, contains(2));

        expect(await table.length, 4);
        expect(await table.getById(2), isNull);
        final allDocs = await table.all();
        expect(allDocs.any((doc) => doc['name'] == 'Bob'), isFalse);

        final dbData = await storage.read();
        expect(dbData?[tableName]?.containsKey('2'), isFalse);
      });

      test('removes multiple documents matching a query', () async {
        final removedIds = await table.remove(where('type').equals('A'));

        expect(removedIds, hasLength(2));
        expect(removedIds, containsAll([1, 3]));

        expect(await table.length, 3);
        expect(await table.getById(1), isNull);
        expect(await table.getById(3), isNull);
        final allDocs = await table.all();
        expect(allDocs.where((doc) => doc['type'] == 'A').toList(), isEmpty);

        final dbData = await storage.read();
        expect(dbData?[tableName]?.containsKey('1'), isFalse);
        expect(dbData?[tableName]?.containsKey('3'), isFalse);
      });

      test('returns empty list if query matches no documents', () async {
        final removedIds = await table.remove(where('name').equals('Zoe'));
        expect(removedIds, isEmpty);
        expect(await table.length, 5);
      });

      test('operates correctly on an empty table', () async {
        final emptyTable = Table(MemoryStorage(), 'empty_remove_test_table');
        final removedIds = await emptyTable.remove(
          where('name').equals('Alice'),
        );
        expect(removedIds, isEmpty);
        expect(await emptyTable.length, 0);
      });
    });

    group('removeByIds(List<DocumentId>)', () {
      setUp(() async {
        storage = MemoryStorage();
        table = Table(storage, tableName);
        await populateTableForRemoveTests(table);
      });

      test('removes a single document by ID', () async {
        final removedIds = await table.removeByIds([1]);
        expect(removedIds, [1]);
        expect(await table.length, 4);
        expect(await table.getById(1), isNull);

        final dbData = await storage.read();
        expect(dbData?[tableName]?.containsKey('1'), isFalse);
      });

      test('removes multiple documents by IDs', () async {
        final removedIds = await table.removeByIds([2, 4]);
        expect(removedIds, hasLength(2));
        expect(removedIds, containsAll([2, 4]));

        expect(await table.length, 3);
        expect(await table.getById(2), isNull);
        expect(await table.getById(4), isNull);

        final dbData = await storage.read();
        expect(dbData?[tableName]?.containsKey('2'), isFalse);
        expect(dbData?[tableName]?.containsKey('4'), isFalse);
      });

      test('ignores non-existent IDs and removes existing ones', () async {
        final removedIds = await table.removeByIds([1, 99, 3, 100]);
        expect(removedIds, hasLength(2));
        expect(removedIds, containsAll([1, 3]));

        expect(await table.length, 3);
        expect(await table.getById(1), isNull);
        expect(await table.getById(3), isNull);
        expect(await table.getById(99), isNull);
      });

      test('returns empty list if all provided IDs are non-existent', () async {
        final removedIds = await table.removeByIds([99, 100]);
        expect(removedIds, isEmpty);
        expect(await table.length, 5);
      });

      test('returns empty list if an empty list of IDs is provided', () async {
        final removedIds = await table.removeByIds([]);
        expect(removedIds, isEmpty);
        expect(await table.length, 5);
      });

      test(
        'operates correctly on an empty table when removing by IDs',
        () async {
          final emptyTable = Table(
            MemoryStorage(),
            'empty_remove_by_id_test_table',
          );
          final removedIds = await emptyTable.removeByIds([1, 2]);
          expect(removedIds, isEmpty);
          expect(await emptyTable.length, 0);
        },
      );
    });
  });
}
