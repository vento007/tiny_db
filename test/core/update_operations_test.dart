import 'package:test/test.dart';
import 'package:tiny_db/tiny_db.dart';

void main() {
  group('Table Update Operations', () {
    late MemoryStorage storage;
    late TinyDb db;
    late Table table;

    setUp(() async {
      storage = MemoryStorage();
      db = TinyDb(storage);
      table = db.table('updates_test');
      await table.insertMultiple([
        {
          'id': 1,
          'name': 'Alice',
          'age': 30,
          'score': 100,
          'address': {'city': 'New York'},
          'counters': {'views': 50},
        },

        {
          'id': 2,
          'name': 'Bob',
          'age': 24,
          'score': 150,
          'data': {'value': 10},
        },
        {'id': 3, 'name': 'Charlie', 'age': 30, 'score': 120, 'misc': null},
        {
          'id': 4,
          'name': 'Alice',
          'age': 35,
          'score': 200,
          'tags': ['dev'],
        },
      ]);
    });

    test('set: update existing top-level field', () async {
      final ops = UpdateOperations().set('age', 31);
      final updatedIds = await table.update(ops, where('id').equals(1));

      expect(updatedIds, [1]);
      final doc = await table.getById(1);
      expect(doc?['age'], 31);
      expect(doc?['name'], 'Alice');
    });

    test('set: add new top-level field', () async {
      final ops = UpdateOperations().set('status', 'active');
      final updatedIds = await table.update(ops, where('id').equals(2));

      expect(updatedIds, [2]);
      final doc = await table.getById(2);
      expect(doc?['status'], 'active');
    });

    test('set: update nested field', () async {
      final ops = UpdateOperations().set('address.city', 'London');
      final updatedIds = await table.update(ops, where('id').equals(1));

      expect(updatedIds, [1]);
      final doc = await table.getById(1);
      expect(doc?['address']?['city'], 'London');
    });

    test('set: create nested path and field', () async {
      final ops = UpdateOperations().set('profile.settings.theme', 'dark');
      final updatedIds = await table.update(ops, where('id').equals(2));

      expect(updatedIds, [2]);
      final doc = await table.getById(2);
      expect(doc?['profile']?['settings']?['theme'], 'dark');
      expect(doc?['data']?['value'], 10);
    });

    test('set: no change if value is the same', () async {
      final ops = UpdateOperations().set('name', 'Alice');
      final updatedIds = await table.update(ops, where('id').equals(1));
      expect(
        updatedIds,
        isEmpty,
        reason: "No actual change, so no ID should be returned",
      );
      final doc = await table.getById(1);
      expect(doc?['age'], 30);
    });

    test('delete: remove existing top-level field', () async {
      final ops = UpdateOperations().delete('score');
      final updatedIds = await table.update(ops, where('id').equals(1));

      expect(updatedIds, [1]);
      final doc = await table.getById(1);
      expect(doc?.containsKey('score'), isFalse);
      expect(doc?['age'], 30);
    });

    test('delete: remove nested field', () async {
      final ops = UpdateOperations().delete('address.city');
      final updatedIds = await table.update(ops, where('id').equals(1));

      expect(updatedIds, [1]);
      final doc = await table.getById(1);
      expect(doc?['address']?.containsKey('city'), isFalse);
      expect(doc?['address'], isEmpty);
    });

    test(
      'delete: non-existent field does nothing and reports no update',
      () async {
        final ops = UpdateOperations().delete('nonexistent');
        final updatedIds = await table.update(ops, where('id').equals(1));
        expect(updatedIds, isEmpty);
      },
    );

    test('delete: non-existent nested path does nothing', () async {
      final ops = UpdateOperations().delete('profile.settings.theme');
      final updatedIds = await table.update(ops, where('id').equals(2));
      expect(updatedIds, isEmpty);
      final doc = await table.getById(2);
      expect(doc?.containsKey('profile'), isFalse);
    });

    test('increment: existing numeric field', () async {
      final ops = UpdateOperations().increment('score', 10);
      final updatedIds = await table.update(ops, where('id').equals(1));

      expect(updatedIds, [1]);
      final doc = await table.getById(1);
      expect(doc?['score'], 110);
    });

    test('increment: non-existent field creates and sets to amount', () async {
      final ops = UpdateOperations().increment('new_counter', 5);
      final updatedIds = await table.update(ops, where('id').equals(1));

      expect(updatedIds, [1]);
      final doc = await table.getById(1);
      expect(doc?['new_counter'], 5);
    });

    test(
      'increment: field is not a number (skips increment, logs warning)',
      () async {
        final ops = UpdateOperations().increment('name', 5);
        final updatedIds = await table.update(ops, where('id').equals(1));

        expect(
          updatedIds,
          isEmpty,
          reason:
              "Name field is not numeric, should not be changed or reported as updated",
        );
        final doc = await table.getById(1);
        expect(doc?['name'], 'Alice');
        expect(doc?['score'], 100);
      },
    );

    test('increment: nested field', () async {
      final ops = UpdateOperations().increment('data.value', 3);
      final updatedIds = await table.update(ops, where('id').equals(2));

      expect(updatedIds, [2]);

      final doc = await table.getById(2);
      expect(doc?['data']?['value'], 13);
    });

    test('multiple operations: set and increment', () async {
      final ops = UpdateOperations()
          .set('status', 'VIP')
          .increment('score', 50);
      final updatedIds = await table.update(ops, where('id').equals(2));

      expect(updatedIds, [2]);

      final doc = await table.getById(2);
      expect(doc?['status'], 'VIP');
      expect(doc?['score'], 200);
    });

    test('update multiple documents matching query', () async {
      final ops = UpdateOperations().set('age', 31).increment('score', 5);
      final updatedIds = await table.update(ops, where('age').equals(30));

      expect(updatedIds, hasLength(2));
      expect(updatedIds, containsAll([1, 3]));

      final doc1 = await table.getById(1);
      expect(doc1?['age'], 31);
      expect(doc1?['score'], 105);

      final doc3 = await table.getById(3);
      expect(doc3?['age'], 31);
      expect(doc3?['score'], 125);

      final doc2 = await table.getById(2);
      expect(doc2?['age'], 24);
    });

    test(
      'update operation on path that becomes invalid mid-traversal',
      () async {
        await table.insert({'id': 5, 'name': 'Eve', 'address': '123 Main St'});

        final ops = UpdateOperations().set('address.city', 'NewTown');
        final updatedIds = await table.update(ops, where('id').equals(5));

        expect(
          updatedIds,
          isEmpty,
          reason:
              "Path 'address.city' is invalid because 'address' is not a map.",
        );
        final doc = await table.getById(5);
        expect(doc?['address'], '123 Main St');
      },
    );

    group('decrement', () {
      test('decrement: existing numeric field', () async {
        final ops = UpdateOperations().decrement('score', 10);
        final updatedIds = await table.update(ops, where('id').equals(1));

        expect(updatedIds, [1]);
        final doc = await table.getById(1);
        expect(doc?['score'], 90);
      });

      test(
        'decrement: non-existent field creates and sets to -amount',
        () async {
          final ops = UpdateOperations().decrement('new_gauge', 5);
          final updatedIds = await table.update(ops, where('id').equals(1));

          expect(updatedIds, [1]);
          final doc = await table.getById(1);
          expect(doc?['new_gauge'], -5);
        },
      );

      test(
        'decrement: field is not a number (skips decrement, logs warning)',
        () async {
          final ops = UpdateOperations().decrement('name', 5);
          final updatedIds = await table.update(ops, where('id').equals(1));

          expect(
            updatedIds,
            isEmpty,
            reason:
                "Name field is not numeric, should not be changed or reported as updated",
          );
          final doc = await table.getById(1);
          expect(doc?['name'], 'Alice');
          expect(doc?['score'], 100);
        },
      );

      test('decrement: nested field', () async {
        final ops = UpdateOperations().decrement('counters.views', 3);

        final updatedIds = await table.update(ops, where('id').equals(1));

        expect(updatedIds, [1]);
        final doc = await table.getById(1);
        expect(doc?['counters']?['views'], 47);
      });
      test('decrement: by a negative number (effectively increases)', () async {
        final ops = UpdateOperations().decrement('score', -10);
        final updatedIds = await table.update(ops, where('id').equals(1));

        expect(updatedIds, [1]);
        final doc = await table.getById(1);
        expect(doc?['score'], 110);
      });

      test('decrement: results in negative value', () async {
        final ops = UpdateOperations().decrement('score', 120);
        final updatedIds = await table.update(ops, where('id').equals(1));

        expect(updatedIds, [1]);
        final doc = await table.getById(1);
        expect(doc?['score'], -20);
      });

      test(
        'decrement: target field is explicitly null (behaves like non-existent)',
        () async {
          final ops = UpdateOperations().decrement('misc', 5);
          final updatedIds = await table.update(ops, where('id').equals(3));

          expect(
            updatedIds,
            isEmpty,
            reason: "misc field is explicitly null, should not be decremented",
          );
          final doc = await table.getById(3);
          expect(doc?['misc'], null);
        },
      );
    });

    test('multiple operations: set, increment, and decrement', () async {
      final ops = UpdateOperations()
          .set('status', 'Premium')
          .increment('score', 50)
          .decrement('data.value', 2);

      final updatedIds = await table.update(ops, where('id').equals(2));

      expect(updatedIds, [2]);
      final doc = await table.getById(2);
      expect(doc?['status'], 'Premium');
      expect(doc?['score'], 200);
      expect(doc?['data']?['value'], 8);
    });

    group('push (list operation)', () {
      test('push: add item to existing list field', () async {
        final ops = UpdateOperations().push('tags', 'dart');
        final updatedIds = await table.update(ops, where('id').equals(4));

        expect(updatedIds, [4]);
        final doc = await table.getById(4);
        expect(doc?['tags'], orderedEquals(['dev', 'dart']));
      });

      test('push: create new list field if it does not exist', () async {
        final ops = UpdateOperations().push('categories', 'tech');
        final updatedIds = await table.update(ops, where('id').equals(1));

        expect(updatedIds, [1]);
        final doc = await table.getById(1);
        expect(doc?['categories'], orderedEquals(['tech']));
      });

      test('push: create new nested list field', () async {
        final ops = UpdateOperations().push('meta.labels', 'urgent');
        final updatedIds = await table.update(ops, where('id').equals(1));

        expect(updatedIds, [1]);
        final doc = await table.getById(1);
        expect(doc?['meta']?['labels'], orderedEquals(['urgent']));
      });

      test(
        'push: attempt to push to a non-list field (e.g., string)',
        () async {
          final ops = UpdateOperations().push('name', 'Smith');
          final updatedIds = await table.update(ops, where('id').equals(1));

          expect(
            updatedIds,
            isEmpty,
            reason: "Should not modify if field is not a list",
          );
          final doc = await table.getById(1);
          expect(doc?['name'], 'Alice');
        },
      );

      test('push: duplicate items are allowed', () async {
        await table.update(
          UpdateOperations().set('tags', ['A']),
          where('id').equals(1),
        );

        final ops = UpdateOperations().push('tags', 'A');
        final updatedIds = await table.update(ops, where('id').equals(1));

        expect(updatedIds, [1]);
        final doc = await table.getById(1);
        expect(doc?['tags'], orderedEquals(['A', 'A']));
      });
    });

    group('pull (list operation)', () {
      test('pull: remove item from existing list field', () async {
        await table.update(
          UpdateOperations().set('tags', ['dev', 'dart', 'flutter', 'dart']),
          where('id').equals(4),
        );

        final ops = UpdateOperations().pull('tags', 'dart');
        final updatedIds = await table.update(ops, where('id').equals(4));

        expect(updatedIds, [4]);
        final doc = await table.getById(4);
        expect(doc?['tags'], orderedEquals(['dev', 'flutter']));
      });

      test('pull: item not in list does nothing, reports no change', () async {
        await table.update(
          UpdateOperations().set('tags', ['dev', 'flutter']),
          where('id').equals(4),
        );

        final ops = UpdateOperations().pull('tags', 'java');
        final updatedIds = await table.update(ops, where('id').equals(4));

        expect(updatedIds, isEmpty);
        final doc = await table.getById(4);
        expect(doc?['tags'], orderedEquals(['dev', 'flutter']));
      });

      test('pull: from a non-existent list field does nothing', () async {
        final ops = UpdateOperations().pull('non_existent_tags', 'java');
        final updatedIds = await table.update(ops, where('id').equals(1));
        expect(updatedIds, isEmpty);
      });

      test('pull: from a field that is not a list (e.g., string)', () async {
        final ops = UpdateOperations().pull('name', 'A');
        final updatedIds = await table.update(ops, where('id').equals(1));

        expect(updatedIds, isEmpty);
        final doc = await table.getById(1);
        expect(doc?['name'], 'Alice');
      });

      test('pull: from an empty list does nothing', () async {
        await table.update(
          UpdateOperations().set('tags', []),
          where('id').equals(1),
        );
        final ops = UpdateOperations().pull('tags', 'A');
        final updatedIds = await table.update(ops, where('id').equals(1));

        expect(updatedIds, isEmpty);
        final doc = await table.getById(1);
        expect(doc?['tags'], isEmpty);
      });

      test(
        'pull: from list with multiple occurrences of the item removes all',
        () async {
          const testDocUserDefinedId = 8;
          await table.insert({
            'id': testDocUserDefinedId,
            'items': ['a', 'b', 'a', 'c', 'a', 'd'],
          });

          const expectedInternalDocId = 5;

          final ops = UpdateOperations().pull('items', 'a');
          final updatedIds = await table.update(
            ops,
            where('id').equals(testDocUserDefinedId),
          );

          expect(
            updatedIds,
            [expectedInternalDocId],
            reason:
                "Update should return the internal ID of the modified document.",
          );

          final matchingDocs = await table.search(
            where('id').equals(testDocUserDefinedId),
          );
          expect(
            matchingDocs.length,
            1,
            reason: "Should find one document by its user-defined id.",
          );
          final doc = matchingDocs.first;

          expect(doc['items'], orderedEquals(['b', 'c', 'd']));
        },
      );
    });

    group('pop (list operation - removes last)', () {
      setUp(() async {
        storage = MemoryStorage();
        db = TinyDb(storage);
        table = db.table('updates_test_pop');
        await table.insertMultiple([
          {
            'doc_id_internal': 1,
            'id': 1,
            'name': 'Alice',
            'tags': ['A', 'B', 'C'],
            'misc': {
              'items': ['X', 'Y'],
            },
          },
          {
            'doc_id_internal': 2,
            'id': 2,
            'name': 'Bob',
            'tags': ['D'],
          },
          {'doc_id_internal': 3, 'id': 3, 'name': 'Charlie', 'tags': []},
          {'doc_id_internal': 4, 'id': 4, 'name': 'David'},
          {'doc_id_internal': 5, 'id': 5, 'name': 'Eve', 'tags': 'not_a_list'},
        ]);
      });

      test('pop: remove last item from existing list', () async {
        final ops = UpdateOperations().pop('tags');
        final updatedIds = await table.update(ops, where('id').equals(1));

        expect(updatedIds, [1]);
        final doc = await table.getById(1);
        expect(doc?['tags'], orderedEquals(['A', 'B']));
      });

      test('pop: remove last item from single-item list', () async {
        final ops = UpdateOperations().pop('tags');
        final updatedIds = await table.update(ops, where('id').equals(2));

        expect(updatedIds, [2]);
        final doc = await table.getById(2);
        expect(doc?['tags'], isEmpty);
      });

      test('pop: from empty list does nothing, reports no change', () async {
        final ops = UpdateOperations().pop('tags');
        final updatedIds = await table.update(ops, where('id').equals(3));

        expect(updatedIds, isEmpty);
        final doc = await table.getById(3);
        expect(doc?['tags'], isEmpty);
      });

      test(
        'pop: from non-existent field does nothing, reports no change',
        () async {
          final ops = UpdateOperations().pop('tags');
          final updatedIds = await table.update(ops, where('id').equals(4));

          expect(updatedIds, isEmpty);
          final doc = await table.getById(4);
          expect(doc?.containsKey('tags'), isFalse);
        },
      );

      test(
        'pop: from field that is not a list does nothing, reports no change (logs warning)',
        () async {
          final ops = UpdateOperations().pop('tags');
          final updatedIds = await table.update(ops, where('id').equals(5));

          expect(updatedIds, isEmpty);
          final doc = await table.getById(5);
          expect(doc?['tags'], 'not_a_list');
        },
      );

      test('pop: from nested list', () async {
        final ops = UpdateOperations().pop('misc.items');
        final updatedIds = await table.update(ops, where('id').equals(1));

        expect(updatedIds, [1]);
        final doc = await table.getById(1);
        expect(doc?['misc']?['items'], orderedEquals(['X']));
      });

      test('pop: from non-existent nested path does nothing', () async {
        final ops = UpdateOperations().pop('nonexistent.path.list');
        final updatedIds = await table.update(ops, where('id').equals(1));
        expect(updatedIds, isEmpty);
      });

      test('pop: from path where intermediate is not a map', () async {
        await table.insert({'id': 6, 'name': 'Frank', 'config': 123});
        final ops = UpdateOperations().pop('config.settings.list');
        final updatedIds = await table.update(ops, where('id').equals(6));

        expect(updatedIds, isEmpty);
        final doc = await table.getById(6);
        expect(doc?['config'], 123);
      });
    });

    group('addUnique (list operation)', () {
      setUp(() async {
        storage = MemoryStorage();
        db = TinyDb(storage);
        table = db.table('updates_test_addunique');
        await table.insertMultiple([
          {
            'id_field': 1,
            'name': 'Alice',
            'tags': ['A', 'B'],
            'misc': {
              'items': ['X'],
            },
          },
          {
            'id_field': 2,
            'name': 'Bob',
            'tags': ['C'],
          },
          {'id_field': 3, 'name': 'Charlie', 'tags': []},
          {'id_field': 4, 'name': 'David'},
          {'id_field': 5, 'name': 'Eve', 'tags': 'not_a_list'},
          {'id_field': 6, 'name': 'Fiona', 'data': <String, dynamic>{}},
        ]);
      });

      test('addUnique: add new item to existing list', () async {
        final ops = UpdateOperations().addUnique('tags', 'C');
        final updatedIds = await table.update(ops, where('id_field').equals(1));

        expect(updatedIds, hasLength(1));
        final doc = await table.getById(updatedIds.first);
        expect(doc?['tags'], orderedEquals(['A', 'B', 'C']));
      });

      test(
        'addUnique: add existing item to list does nothing, reports no change',
        () async {
          final ops = UpdateOperations().addUnique('tags', 'A');
          final updatedIds = await table.update(
            ops,
            where('id_field').equals(1),
          );

          expect(updatedIds, isEmpty);

          final List<Document> docs = await table.search(
            where('id_field').equals(1),
          );
          expect(docs.first['tags'], orderedEquals(['A', 'B']));
        },
      );

      test('addUnique: to non-existent field creates list with item', () async {
        final ops = UpdateOperations().addUnique('categories', 'tech');
        final updatedIds = await table.update(ops, where('id_field').equals(4));

        expect(updatedIds, hasLength(1));
        final doc = await table.getById(updatedIds.first);
        expect(doc?['categories'], orderedEquals(['tech']));
      });

      test('addUnique: to empty list adds item', () async {
        final ops = UpdateOperations().addUnique('tags', 'NewTag');
        final updatedIds = await table.update(ops, where('id_field').equals(3));

        expect(updatedIds, hasLength(1));
        final doc = await table.getById(updatedIds.first);
        expect(doc?['tags'], orderedEquals(['NewTag']));
      });

      test(
        'addUnique: to field that is not a list does nothing, reports no change (logs warning)',
        () async {
          final ops = UpdateOperations().addUnique('tags', 'New');
          final updatedIds = await table.update(
            ops,
            where('id_field').equals(5),
          );

          expect(updatedIds, isEmpty);
          final List<Document> docs = await table.search(
            where('id_field').equals(5),
          );
          expect(docs.first['tags'], 'not_a_list');
        },
      );

      test('addUnique: to nested list (item not present)', () async {
        final ops = UpdateOperations().addUnique('misc.items', 'Y');
        final updatedIds = await table.update(ops, where('id_field').equals(1));

        expect(updatedIds, hasLength(1));
        final doc = await table.getById(updatedIds.first);
        expect(doc?['misc']?['items'], orderedEquals(['X', 'Y']));
      });

      test('addUnique: to nested list (item already present)', () async {
        final ops = UpdateOperations().addUnique('misc.items', 'X');
        final updatedIds = await table.update(ops, where('id_field').equals(1));

        expect(updatedIds, isEmpty);
        final List<Document> docs = await table.search(
          where('id_field').equals(1),
        );
        expect(docs.first['misc']?['items'], orderedEquals(['X']));
      });

      test(
        'addUnique: creates nested path if intermediate maps do not exist',
        () async {
          final ops = UpdateOperations().addUnique(
            'profile.settings.interests',
            'coding',
          );
          final updatedIds = await table.update(
            ops,
            where('id_field').equals(4),
          );

          expect(updatedIds, hasLength(1));
          final doc = await table.getById(updatedIds.first);
          expect(
            doc?['profile']?['settings']?['interests'],
            orderedEquals(['coding']),
          );
        },
      );

      test('addUnique: creates list in existing nested map', () async {
        final ops = UpdateOperations().addUnique('data.hobbies', 'reading');
        final updatedIds = await table.update(ops, where('id_field').equals(6));

        expect(updatedIds, hasLength(1));
        final doc = await table.getById(updatedIds.first);
        expect(doc?['data']?['hobbies'], orderedEquals(['reading']));
      });

      test(
        'addUnique: to path where intermediate is not a map (logs warning)',
        () async {
          await table.insert({'id_field': 7, 'name': 'George', 'config': 123});

          final ops = UpdateOperations().addUnique(
            'config.settings.options',
            'enable',
          );
          final updatedIds = await table.update(
            ops,
            where('id_field').equals(7),
          );

          expect(updatedIds, isEmpty);
          final georgeDocs = await table.search(where('id_field').equals(7));
          expect(georgeDocs.first['config'], 123);
        },
      );

      test(
        'addUnique: with Map objects (checks identity, not deep equality by default)',
        () async {
          // 1. Insert the document and capture its internal ID
          final insertedDocInternalId = await table.insert({
            'user_id': 10,
            'attributes': <dynamic>[],
          });
          // Using 'user_id' to avoid confusion with internal '_id'

          // 2. Verify insertion using the captured internal ID
          var docAfterInsert = await table.getById(insertedDocInternalId);
          expect(
            docAfterInsert,
            isNotNull,
            reason:
                "Document with internal id $insertedDocInternalId should exist after insert.",
          );
          expect(
            docAfterInsert?['user_id'],
            equals(10),
            reason: "Document user_id should be 10.",
          );
          expect(
            docAfterInsert?['attributes'],
            isA<List>(),
            reason: "Attributes should be a list after insert.",
          );
          expect(
            docAfterInsert?['attributes'],
            isEmpty,
            reason: "Attributes should be an empty list initially.",
          );

          // 3. Prepare and execute the push operation, targeting by internal ID
          final map1 = {'key': 'value', 'id': 1};
          var ops = UpdateOperations().push('attributes', map1);
          // Querying by the internal ID for the update
          final updatedIdsPush = await table.update(
            ops,
            where('user_id').equals(docAfterInsert?['user_id'] as int),
          );

          expect(
            updatedIdsPush,
            isNotEmpty,
            reason:
                "Push operation should have identified an updated document.",
          );
          expect(
            updatedIdsPush,
            hasLength(1),
            reason: "Push operation should have updated one document.",
          );
          expect(
            updatedIdsPush.first,
            equals(insertedDocInternalId),
            reason: "The updated ID should match the internal ID.",
          );

          // 5. Verify document state after push, fetching by internal ID
          var docAfterPush = await table.getById(insertedDocInternalId);
          expect(
            docAfterPush,
            isNotNull,
            reason:
                "Document with internal id $insertedDocInternalId should still exist after push.",
          );
          expect(
            docAfterPush?['attributes'],
            isA<List>(),
            reason: "'attributes' field should be a List after push.",
          );
          expect(
            docAfterPush?['attributes'],
            hasLength(1),
            reason: "'attributes' list should have 1 item after push.",
          );
          expect(
            docAfterPush?['attributes']?[0],
            equals(map1),
            reason: "The first item in 'attributes' should be map1.",
          );

          // 6. Try to addUnique another Map instance with the same content, targeting by internal ID
          final map2 = {
            'key': 'value',
            'id': 1,
          }; // Same content, different instance
          ops = UpdateOperations().addUnique('attributes', map2);
          final updatedIdsAddUniqueMap2 = await table.update(
            ops,
            where('user_id').equals(docAfterInsert?['user_id'] as int),
          );
          expect(
            updatedIdsAddUniqueMap2,
            isEmpty,
            reason:
                "addUnique for map2 (deep equal to map1) should not report an update.",
          );

          var docAfterAddUniqueMap2 = await table.getById(
            insertedDocInternalId,
          );
          expect(
            docAfterAddUniqueMap2,
            isNotNull,
            reason: "Doc should exist after addUnique map2.",
          );
          expect(
            docAfterAddUniqueMap2?['attributes'],
            isA<List>(),
            reason: "Attributes should be a list.",
          );
          expect(
            docAfterAddUniqueMap2?['attributes'],
            hasLength(1),
            reason:
                "Attributes should have 1 item after deep-equal map addUnique.",
          );
          expect(
            docAfterAddUniqueMap2?['attributes'],
            [
              {'key': 'value', 'id': 1},
            ],
            reason:
                "Attributes should contain only one map with key:value and id:1.",
          );

          // 7. Try to addUnique the exact same instance (map1) again, targeting by internal ID
          ops = UpdateOperations().addUnique('attributes', map1);
          final updatedIdsAddUniqueMap1Again = await table.update(
            ops,
            where('user_id').equals(docAfterInsert?['user_id'] as int),
          );
          expect(
            updatedIdsAddUniqueMap1Again,
            isEmpty,
            reason:
                "addUnique for map1 again (same instance) should not report an update.",
          );

          var docAfterAddUniqueMap1Again = await table.getById(
            insertedDocInternalId,
          );
          expect(
            docAfterAddUniqueMap1Again,
            isNotNull,
            reason: "Doc should exist after attempting to re-add map1.",
          );
          expect(
            docAfterAddUniqueMap1Again?['attributes'],
            isA<List>(),
            reason: "Attributes should still be a list.",
          );
          expect(
            docAfterAddUniqueMap1Again?['attributes'],
            hasLength(1),
            reason:
                "Attributes should still have 1 item since deep-equal maps are not duplicated.",
          );
        },
      );
    }); // End of addUnique group

    group('Combined Update Operations', () {
      test('set one field and increment another in one go', () async {
        final ops = UpdateOperations()
            .set('name', 'Updated Alice')
            .increment('score', 1);

        final updatedIds = await table.update(ops, where('id').equals(1));
        expect(updatedIds, [1]);

        final doc = await table.getById(1);
        expect(doc?['name'], 'Updated Alice');
        expect(doc?['score'], 101);
        expect(doc?['age'], 30);
      });

      test(
        'set a field and then delete it in the same operation chain',
        () async {
          final ops = UpdateOperations()
              .set('status', 'temporary')
              .delete('status');

          final updatedIds = await table.update(ops, where('id').equals(2));
          expect(updatedIds, [2]);

          final doc = await table.getById(2);
          expect(doc?.containsKey('status'), isFalse);
          expect(doc?['name'], 'Bob');
        },
      );

      test('create a new field (map) and then set a value within it', () async {
        final ops = UpdateOperations()
            .set('metadata', <String, dynamic>{})
            .set('metadata.source', 'test_case');

        final updatedIds = await table.update(ops, where('id').equals(3));
        expect(updatedIds, [3]);

        final doc = await table.getById(3);
        expect(doc?['metadata'], isA<Map>());
        expect(doc?['metadata']?['source'], 'test_case');
        expect(doc?['name'], 'Charlie');
      });

      test('set the same field twice, last one wins', () async {
        final ops = UpdateOperations().set('age', 50).set('age', 55);

        final updatedIds = await table.update(ops, where('id').equals(1));
        expect(updatedIds, [1]);

        final doc = await table.getById(1);
        expect(doc?['age'], 55);
      });

      test('increment a field multiple times in the same chain', () async {
        final ops = UpdateOperations()
            .increment('score', 1)
            .increment('score', 1)
            .increment('score', 1);

        final updatedIds = await table.update(ops, where('id').equals(4));
        expect(updatedIds, [4]);

        final doc = await table.getById(4);
        expect(doc?['score'], 203);
      });

      test('chain addToList and addUnique on the same field', () async {
        final ops = UpdateOperations()
            .push('tags', 'backend')
            .addUnique('tags', 'dev')
            .addUnique('tags', 'frontend');

        final updatedIds = await table.update(ops, where('id').equals(4));
        expect(updatedIds, [4]);

        final doc = await table.getById(4);
        expect(doc?['tags'], orderedEquals(['dev', 'backend', 'frontend']));
      });
    });
  });
}
