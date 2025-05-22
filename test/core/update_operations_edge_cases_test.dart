import 'package:test/test.dart';
import 'package:tiny_db/tiny_db.dart';

void main() {
  group('Table Update Operations - Edge Cases', () {
    late MemoryStorage storage;
    late TinyDb db;
    late Table table;

    setUp(() async {
      storage = MemoryStorage();
      db = TinyDb(storage);
      table = db.table('edge_cases');
      await table.insertMultiple([
        {
          'id': 1,
          'name': 'Alice',
          'profile': {
            'favorites': [
              [1, 2, 3],
            ],
            'settings': {'theme': 'light'},
          },
          'tags': ['a', 'b'],
          'score': 5,
          'misc': null,
        },
        {
          'id': 2,
          'mixed': [1, null, 'x'],
        },
      ]);
    });

    test('addUnique with list of lists (deep equality)', () async {
      final ops = UpdateOperations().addUnique('profile.favorites', [1, 2, 3]);
      final updatedIds = await table.update(ops, where('id').equals(1));
      expect(
        updatedIds,
        isEmpty,
        reason: 'Deep-equal list should not be added again.',
      );
    });

    test('addUnique with null and primitive values', () async {
      var ops = UpdateOperations().addUnique('tags', null);
      var updatedIds = await table.update(ops, where('id').equals(1));
      expect(updatedIds, [
        1,
      ], reason: 'Should allow adding null as unique value.');
      var doc = await table.getById(1);
      expect(doc?['tags'], contains(null));

      ops = UpdateOperations().addUnique('tags', 42);
      updatedIds = await table.update(ops, where('id').equals(1));
      expect(updatedIds, [
        1,
      ], reason: 'Should allow adding int as unique value.');
      doc = await table.getById(1);
      expect(doc?['tags'], contains(42));
    });

    test('conflicting operations: set and delete', () async {
      final ops = UpdateOperations().set('name', 'Bob').delete('name');
      final updatedIds = await table.update(ops, where('id').equals(1));
      expect(updatedIds, [1]);
      final doc = await table.getById(1);
      expect(doc?.containsKey('name'), isFalse, reason: 'Delete should win.');
    });

    test('deeply nested list push', () async {
      final ops = UpdateOperations().push('profile.favorites', 4);
      final updatedIds = await table.update(ops, where('id').equals(1));
      expect(updatedIds, [1]);
      final doc = await table.getById(1);
      expect(doc?['profile']?['favorites'], contains(4));
    });

    test('increment on a list field', () async {
      final ops = UpdateOperations().increment('tags', 1);
      final updatedIds = await table.update(ops, where('id').equals(1));
      expect(updatedIds, isEmpty, reason: 'Cannot increment a list field.');
    });

    test('delete a field that is a map', () async {
      final ops = UpdateOperations().delete('profile');
      final updatedIds = await table.update(ops, where('id').equals(1));
      expect(updatedIds, [1]);
      final doc = await table.getById(1);
      expect(doc?.containsKey('profile'), isFalse);
    });

    test('pull from empty list', () async {
      final ops = UpdateOperations().pull('tags', 'z');
      final updatedIds = await table.update(ops, where('id').equals(2));
      expect(
        updatedIds,
        isEmpty,
        reason: 'Pull from non-existent list should do nothing.',
      );
    });

    test('multiple updates to same nested field', () async {
      final ops = UpdateOperations()
          .set('profile.settings.theme', 'dark')
          .set('profile.settings.theme', 'blue');
      final updatedIds = await table.update(ops, where('id').equals(1));
      expect(updatedIds, [1]);
      final doc = await table.getById(1);
      expect(doc?['profile']?['settings']?['theme'], 'blue');
    });

    test('case sensitivity in field names', () async {
      final ops = UpdateOperations().set('Name', 'Different');
      final updatedIds = await table.update(ops, where('id').equals(1));
      expect(updatedIds, [1]);
      final doc = await table.getById(1);
      expect(doc?['Name'], 'Different');
      expect(doc?['name'], 'Alice');
    });

    test('addUnique with nested maps/lists', () async {
      final nestedMap = {
        'foo': [
          1,
          2,
          {'bar': 3},
        ],
      };
      final ops = UpdateOperations().addUnique('tags', nestedMap);
      final updatedIds = await table.update(ops, where('id').equals(1));
      expect(updatedIds, [1]);
      final doc = await table.getById(1);
      expect(
        doc?['tags'],
        contains(
          predicate(
            (m) => m is Map && m['foo'] is List && m['foo'][2]['bar'] == 3,
          ),
        ),
      );
    });

    test('addUnique null to a list containing null', () async {
      final ops = UpdateOperations().addUnique('mixed', null);
      final updatedIds = await table.update(ops, where('id').equals(2));
      expect(updatedIds, isEmpty, reason: 'Should not add duplicate null.');
    });
  });
}
