import 'package:test/test.dart';
import 'package:tiny_db/tiny_db.dart';

void main() {
  group('Table Query Utilities (count, contains, containsId)', () {
    late MemoryStorage storage;
    late Table table;
    const tableName = 'query_utils_test_table';

    Future<void> populateTable(Table currentTable) async {
      await currentTable.insertMultiple([
        {
          'id_field': 1,
          'name': 'Alice',
          'type': 'A',
          'value': 10,
          'tags': ['one', 'two'],
        },
        {
          'id_field': 2,
          'name': 'Bob',
          'type': 'B',
          'value': 20,
          'tags': ['two', 'three'],
        },
        {
          'id_field': 3,
          'name': 'Charlie',
          'type': 'A',
          'value': 30,
          'tags': ['three', 'four'],
        },
        {
          'id_field': 4,
          'name': 'David',
          'type': 'C',
          'value': 40,
          'tags': ['four', 'five'],
        },
        {
          'id_field': 5,
          'name': 'Alice',
          'type': 'B',
          'value': 50,
          'tags': ['five', 'one'],
        },
      ]);
    }

    setUp(() async {
      storage = MemoryStorage();
      table = Table(storage, tableName);
      await populateTable(table);
    });

    group('count(QueryCondition)', () {
      test('counts documents matching a simple query', () async {
        expect(await table.count(where('type').equals('A')), 2);
        expect(await table.count(where('name').equals('Alice')), 2);
        expect(await table.count(where('value').greaterThan(25)), 3);
      });

      test(
        'counts documents matching a more complex query (e.g., nested field)',
        () async {
          expect(
            await table.count(
              where('type').equals('B').and(where('value').lessThan(30)),
            ),
            1,
          );
        },
      );

      test('returns 0 if query matches no documents', () async {
        expect(await table.count(where('name').equals('Zoe')), 0);
      });

      test('returns 0 for an empty table', () async {
        final emptyTable = Table(MemoryStorage(), 'empty_count_table');
        expect(await emptyTable.count(where('name').equals('Alice')), 0);
      });

      test('counts all documents if query matches all', () async {
        expect(await table.count(where('name').exists()), 5);

        final QueryCondition matchAllViaTestOnField = where(
          'name',
        ).test((fieldValue) => true);
        expect(await table.count(matchAllViaTestOnField), 5);
      });
    });

    group('containsId(DocumentId)', () {
      test('returns true if ID exists', () async {
        expect(await table.containsId(1), isTrue);
        expect(await table.containsId(5), isTrue);
      });

      test('returns false if ID does not exist', () async {
        expect(await table.containsId(0), isFalse);
        expect(await table.containsId(99), isFalse);
      });

      test('returns false for an empty table', () async {
        final emptyTable = Table(MemoryStorage(), 'empty_contains_id_table');
        expect(await emptyTable.containsId(1), isFalse);
      });
    });

    group('contains(QueryCondition)', () {
      test('returns true if query matches at least one document', () async {
        expect(await table.contains(where('name').equals('Bob')), isTrue);
        expect(await table.contains(where('value').equals(30)), isTrue);
      });

      test('returns false if query matches no documents', () async {
        expect(await table.contains(where('name').equals('Zoe')), isFalse);
        expect(await table.contains(where('value').equals(1000)), isFalse);
      });

      test('returns false for an empty table', () async {
        final emptyTable = Table(MemoryStorage(), 'empty_contains_query_table');
        expect(
          await emptyTable.contains(where('name').equals('Alice')),
          isFalse,
        );
      });

      test('works with complex queries', () async {
        expect(
          await table.contains(
            where('type').equals('B').and(where('name').equals('Alice')),
          ),
          isTrue,
        );
      });
    });
  });
}
