import 'package:test/test.dart';
import 'package:tiny_db/tiny_db.dart';

void main() {
  group('Query System - List/Iterable Operations', () {
    late MemoryStorage storage;
    late TinyDb db;
    late Table table;

    setUp(() async {
      storage = MemoryStorage();
      db = TinyDb(storage);
      table = db.table('list_test_table');

      await table.insertMultiple([
        {
          'id': 'doc1',
          'tags': ['A', 'B', 'C'],
          'scores': [10, 20, 30],
          'mixedList': [
            1,
            'apple',
            true,
            {'type': 'fruit'},
          ],
          'emptyList': [],
          'items': [
            {'name': 'itemA', 'price': 100},
            {'name': 'itemB', 'price': 150},
          ],
        },
        {
          'id': 'doc2',
          'tags': ['B', 'D'],
          'scores': [40, 50],
          'mixedList': [2, 'banana', false],
          'items': [
            {'name': 'itemC', 'price': 200},
            {'name': 'itemD', 'price': 50},
          ],
        },
        {
          'id': 'doc3',
          'tags': ['E'],
          'scores': [5, 15, 25],
          'items': [
            {'name': 'itemE', 'price': 75},
          ],
        },
        {
          'id': 'doc4',
          'scores': [100, 200],
        },
        {'id': 'doc5', 'tags': [], 'scores': []},
      ]);
    });

    group('Query.anyInList()', () {
      test('finds doc if tags list contains any of ["A", "X"]', () async {
        final results = await table.search(where('tags').anyInList(['A', 'X']));
        expect(results.length, 1);
        expect(results[0]['id'], 'doc1');
      });

      test('finds doc if tags list contains any of ["D"]', () async {
        final results = await table.search(where('tags').anyInList(['D']));
        expect(results.length, 1);
        expect(results[0]['id'], 'doc2');
      });

      test('finds multiple docs if tags list contains any of ["B"]', () async {
        final results = await table.search(where('tags').anyInList(['B']));
        expect(results.length, 2);
        expect(results.map((d) => d['id']), containsAll(['doc1', 'doc2']));
      });

      test('does not find if tags list shares no common elements', () async {
        final results = await table.search(where('tags').anyInList(['X', 'Y']));
        expect(results, isEmpty);
      });

      test('querying with empty list returns no results', () async {
        final results = await table.search(where('tags').anyInList([]));
        expect(results, isEmpty);
      });

      test('field is not a list', () async {
        final results = await table.search(where('id').anyInList(['A']));
        expect(results, isEmpty);
      });

      test('field does not exist', () async {
        final results = await table.search(
          where('non_existent_list').anyInList(['A']),
        );
        expect(results, isEmpty);
      });

      test('field is an empty list in document', () async {
        final results = await table.search(where('tags').anyInList(['A']));
        expect(results.where((d) => d['id'] == 'doc5').toList(), isEmpty);
      });
    });

    group('Query.allInList()', () {
      test('finds doc if tags list contains all of ["A", "B"]', () async {
        final results = await table.search(where('tags').allInList(['A', 'B']));
        expect(results.length, 1);
        expect(results[0]['id'], 'doc1');
      });

      test(
        'does not find if tags list does not contain all elements',
        () async {
          final results = await table.search(
            where('tags').allInList(['A', 'D']),
          );
          expect(results, isEmpty);
        },
      );

      test('finds doc if tags list contains all (and more)', () async {
        final results = await table.search(where('tags').allInList(['B']));
        expect(results.length, 2);
        expect(results.map((d) => d['id']), containsAll(['doc1', 'doc2']));
      });

      test(
        'querying with empty list returns all docs with the list field',
        () async {
          final results = await table.search(where('tags').allInList([]));

          expect(results.length, 4);
          expect(
            results.map((d) => d['id']),
            containsAll(['doc1', 'doc2', 'doc3', 'doc5']),
          );
        },
      );

      test('field is not a list for allInList', () async {
        final results = await table.search(where('id').allInList(['A']));
        expect(results, isEmpty);
      });

      test('field does not exist for allInList', () async {
        final results = await table.search(
          where('non_existent_list').allInList(['A']),
        );
        expect(results, isEmpty);
      });

      test(
        'field is an empty list in document, query for non-empty list',
        () async {
          final results = await table.search(where('tags').allInList(['A']));
          expect(results.where((d) => d['id'] == 'doc5').toList(), isEmpty);
        },
      );

      test(
        'field is an empty list in document, query for empty list',
        () async {
          final results = await table.search(where('tags').allInList([]));
          expect(results.any((d) => d['id'] == 'doc5'), isTrue);
        },
      );
    });

    group('Query.anyElementSatisfies()', () {
      test('finds doc if any score > 25', () async {
        final results = await table.search(
          where('scores').anyElementSatisfies(where('value').greaterThan(25)),
        );
        expect(results.length, 3);
        expect(
          results.map((d) => d['id']),
          containsAll(['doc1', 'doc2', 'doc4']),
        );
      });

      test('does not find if no score > 1000', () async {
        final results = await table.search(
          where('scores').anyElementSatisfies(where('value').greaterThan(1000)),
        );
        expect(results, isEmpty);
      });

      test('works with complex element condition on list of maps', () async {
        final results = await table.search(
          where('items').anyElementSatisfies(
            where(
              'price',
            ).greaterThan(160).and(where('name').matches(r'^itemC$')),
          ),
        );
        expect(results.length, 1);
        expect(results[0]['id'], 'doc2');
      });

      test('field is not a list for anyElementSatisfies', () async {
        final results = await table.search(
          where('id').anyElementSatisfies(where('value').equals('A')),
        );
        expect(results, isEmpty);
      });

      test(
        'field is an empty list in document for anyElementSatisfies',
        () async {
          final results = await table.search(
            where('emptyList').anyElementSatisfies(where('value').exists()),
          );
          expect(results.where((d) => d['id'] == 'doc1').toList(), isEmpty);
        },
      );
    });

    group('Query.allElementsSatisfy()', () {
      test('finds doc if all scores > 5', () async {
        final results = await table.search(
          where('scores').allElementsSatisfy(where('value').greaterThan(5)),
        );

        expect(results.length, 4);
        expect(
          results.map((d) => d['id']),
          containsAll(['doc1', 'doc2', 'doc4', 'doc5']),
        );
      });

      test('does not find if not all scores > 20', () async {
        final results = await table.search(
          where('scores').allElementsSatisfy(where('value').greaterThan(20)),
        );

        expect(results.length, 3);
        expect(
          results.map((d) => d['id']),
          containsAll(['doc2', 'doc4', 'doc5']),
        );
      });

      test(
        'works with complex element condition on list of maps (all items price > 40)',
        () async {
          final results = await table.search(
            where('items').allElementsSatisfy(where('price').greaterThan(40)),
          );

          expect(results.length, 3);
          expect(
            results.map((d) => d['id']),
            containsAll(['doc1', 'doc2', 'doc3']),
          );
        },
      );
      test(
        'works with complex element condition on list of maps (all items price > 100)',
        () async {
          final results = await table.search(
            where('items').allElementsSatisfy(where('price').greaterThan(100)),
          );

          expect(results, isEmpty);
        },
      );

      test('field is not a list for allElementsSatisfy', () async {
        final results = await table.search(
          where('id').allElementsSatisfy(where('value').equals('A')),
        );
        expect(results, isEmpty);
      });

      test(
        'field is an empty list in document for allElementsSatisfy (vacuously true)',
        () async {
          final resultsEmptyList = await table.search(
            where(
              'emptyList',
            ).allElementsSatisfy(where('value').greaterThan(0)),
          );
          expect(resultsEmptyList.any((d) => d['id'] == 'doc1'), isTrue);

          final resultsScores = await table.search(
            where(
              'scores',
            ).allElementsSatisfy(where('value').greaterThan(1000)),
          );
          expect(resultsScores.any((d) => d['id'] == 'doc5'), isTrue);
        },
      );
    });

    group('List Query Condition Equality and Hashing', () {
      test('_ListContainsAnyQueryCondition equality', () {
        final q1 = where('tags').anyInList(['A', 'B']);
        final q2 = where('tags').anyInList(['A', 'B']);
        final q3 = where('tags').anyInList(['A', 'C']);
        final q4 = where('names').anyInList(['A', 'B']);

        expect(q1 == q2, isTrue);
        expect(q1.hashCode == q2.hashCode, isTrue);
        expect(q1 == q3, isFalse);
        expect(q1 == q4, isFalse);
      });

      test('_ListContainsAllQueryCondition equality', () {
        final q1 = where('tags').allInList(['A', 'B']);
        final q2 = where('tags').allInList(['A', 'B']);
        final q3 = where('tags').allInList(['A', 'C']);
        final q4 = where('names').allInList(['A', 'B']);

        expect(q1 == q2, isTrue);
        expect(q1.hashCode == q2.hashCode, isTrue);
        expect(q1 == q3, isFalse);
        expect(q1 == q4, isFalse);
      });

      test('_ListElementTestQueryCondition equality', () {
        final ec1 = where('value').greaterThan(10);
        final ec2 = where('value').greaterThan(10);
        final ec3 = where('value').lessThan(10);

        final q1 = where('scores').anyElementSatisfies(ec1);
        final q2 = where('scores').anyElementSatisfies(ec2);
        final q3 = where('scores').allElementsSatisfy(ec1);
        final q4 = where('scores').anyElementSatisfies(ec3);
        final q5 = where('numbers').anyElementSatisfies(ec1);

        expect(q1 == q2, isTrue);
        expect(q1.hashCode == q2.hashCode, isTrue);
        expect(q1 == q3, isFalse, reason: "Different testAllElements flag");
        expect(q1 == q4, isFalse, reason: "Different elementCondition");
        expect(q1 == q5, isFalse, reason: "Different path");
      });
    });
  });
}
