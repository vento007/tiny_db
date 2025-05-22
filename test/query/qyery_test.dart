// ignore_for_file: unnecessary_null_comparison

import 'package:test/test.dart';
import 'package:tiny_db/tiny_db.dart';

void main() {
  group('Query System', () {
    late MemoryStorage storage;
    late TinyDb db;
    late Table table;

    setUp(() async {
      storage = MemoryStorage();
      db = TinyDb(storage);
      table = db.table('test');
      await table.insertMultiple([
        {
          'id': 1,
          'name': 'Alice',
          'age': 30,
          'address': {'city': 'New York', 'zip': '10001'},
          'tags': ['A', 'B'],
          'description': 'A kind person from NY.',
        },
        {
          'id': 2,
          'name': 'Bob',
          'age': 24,
          'address': {'city': 'London'},
          'misc': null,
          'tags': ['B', 'C'],
          'description': 'Bob is a Software Developer.',
        },
        {
          'id': 3,
          'name': 'Charlie',
          'age': 30,
          'address': null,
          'tags': ['A', 'D'],
          'description': 'Charlie loves a good Book.',
        },
        {
          'id': 4,
          'name': 'David',
          'misc': {'valid': true},
          'description': 'DAVID IS TESTING.',
        },
        {
          'id': 5,
          'name': 'Eve',
          'age': null,
          'description': 'Eve eats apples.',
        },
      ]);
    });

    group('Query.equals()', () {
      test('finds document with matching top-level field', () async {
        final results = await table.search(where('name').equals('Alice'));
        expect(results.length, 1);
        expect(results[0]['id'], 1);
      });

      test('finds document with matching nested field', () async {
        final results = await table.search(
          where('address.city').equals('New York'),
        );
        expect(results.length, 1);
        expect(results[0]['id'], 1);
      });

      test('returns empty list if no match', () async {
        final results = await table.search(where('name').equals('NonExistent'));
        expect(results, isEmpty);
      });

      test('returns empty list if path does not exist', () async {
        final results = await table.search(
          where('non.existent.path').equals('anyValue'),
        );
        expect(results, isEmpty);
      });

      test('matches explicitly null value', () async {
        final results = await table.search(where('misc').equals(null));
        expect(results.length, 1);
        expect(results[0]['id'], 2);
      });

      test(
        'does not match non-existent field when querying for null',
        () async {
          final results = await table.search(where('address.zip').equals(null));

          expect(
            results,
            isEmpty,
            reason:
                "A non-existent path should not equal null via .equals(null)",
          );
        },
      );

      test('matches field that exists and is null (e.g. age: null)', () async {
        final results = await table.search(where('age').equals(null));
        expect(results.length, 1);
        expect(results[0]['id'], 5);
      });
    });

    group('Query.notEquals()', () {
      test(
        'notEquals(null) includes docs where field DNE or (exists AND is not null)',
        () async {
          final results = await table.search(where('misc').notEquals(null));

          expect(
            results.length,
            4,
            reason: "Should include Alice, Charlie, David, Eve",
          );

          final resultIds = results.map((doc) => doc['id']).toList();
          expect(resultIds, containsAll([1, 3, 4, 5]));
          expect(resultIds, isNot(contains(2)));
        },
      );
    });

    group('Query.exists()', () {
      test('finds document if top-level field exists (with value)', () async {
        final results = await table.search(where('name').exists());
        expect(
          results.length,
          5,
          reason: "All test documents have a 'name' field",
        );
      });

      test(
        'finds document if top-level field exists (with null value)',
        () async {
          final results = await table.search(where('misc').exists());

          expect(results.length, 2);
          expect(results.any((d) => d['id'] == 2), isTrue);
          expect(results.any((d) => d['id'] == 4), isTrue);
        },
      );

      test(
        'does not find document if top-level field does not exist',
        () async {
          final results = await table.search(
            where('non_existent_field').exists(),
          );
          expect(results, isEmpty);
        },
      );

      test('finds document if nested field exists (with value)', () async {
        final results = await table.search(where('address.city').exists());

        expect(results.length, 2);
        expect(results.any((d) => d['id'] == 1), isTrue);
        expect(results.any((d) => d['id'] == 2), isTrue);
      });

      test(
        'finds document if nested field exists (even if parent is null, path to parent must exist)',
        () async {
          final results = await table.search(where('address.city').exists());
          expect(results.length, 2);
        },
      );

      test(
        'does not find document if intermediate path segment does not exist for nested field',
        () async {
          final resultsForDavid = await table.search(
            where('address.city').exists(),
          );
          expect(resultsForDavid.any((d) => d['id'] == 4), isFalse);
        },
      );

      test(
        'does not find document if final key in path does not exist in parent map',
        () async {
          final resultsForBob = await table.search(
            where('address.zip').exists(),
          );

          expect(resultsForBob.length, 1);
          expect(resultsForBob.first['id'], 1);
        },
      );

      test(
        'exists() on a field that is explicitly null (e.g. age: null for Eve)',
        () async {
          final results = await table.search(where('age').exists());

          expect(results.length, 4);
          expect(results.any((d) => d['id'] == 5), isTrue);
          expect(results.any((d) => d['id'] == 4), isFalse);
        },
      );
    });

    group('Query.isNull()', () {
      test('finds document where field exists and is null', () async {
        final resultsMisc = await table.search(where('misc').isNull());
        expect(resultsMisc.length, 1);
        expect(resultsMisc[0]['id'], 2);

        final resultsAge = await table.search(where('age').isNull());
        expect(resultsAge.length, 1);
        expect(resultsAge[0]['id'], 5);
      });

      test('does not find document if field does not exist', () async {
        final results = await table.search(
          where('non_existent_field').isNull(),
        );
        expect(results, isEmpty);
      });

      test('does not find document if field exists and is not null', () async {
        final results = await table.search(where('name').isNull());
        expect(results.where((d) => d['id'] == 1).toList(), isEmpty);
      });
    });

    group('Query.isNotNull()', () {
      test('finds document where field exists and is not null', () async {
        final resultsMisc = await table.search(where('misc').isNotNull());
        expect(resultsMisc.length, 1);
        expect(resultsMisc[0]['id'], 4);

        final resultsAge = await table.search(where('age').isNotNull());

        expect(resultsAge.length, 3);
        expect(resultsAge.map((d) => d['id']), containsAll([1, 2, 3]));
      });

      test('does not find document if field does not exist', () async {
        final results = await table.search(
          where('non_existent_field').isNotNull(),
        );
        expect(results, isEmpty);
      });

      test('does not find document if field exists and is null', () async {
        final results = await table.search(where('misc').isNotNull());
        expect(results.where((d) => d['id'] == 2).toList(), isEmpty);
      });
    });

    group('Query.notExists()', () {
      test('finds document if top-level field does not exist', () async {
        final results = await table.search(
          where('non_existent_field').notExists(),
        );
        expect(
          results.length,
          5,
          reason: "All 5 documents lack 'non_existent_field'",
        );
      });

      test(
        'does not find document if top-level field exists (with value)',
        () async {
          final results = await table.search(where('name').notExists());
          expect(results, isEmpty, reason: "All documents have 'name'");
        },
      );

      test(
        'does not find document if top-level field exists (with null value)',
        () async {
          final results = await table.search(where('misc').notExists());

          expect(results.length, 3);
          expect(results.map((d) => d['id']), containsAll([1, 3, 5]));
          expect(results.any((d) => d['id'] == 2 || d['id'] == 4), isFalse);
        },
      );

      test(
        'finds document if nested field does not exist (parent exists, key missing)',
        () async {
          final results = await table.search(where('address.zip').notExists());

          expect(results.length, 4);
          expect(results.any((d) => d['id'] == 1), isFalse);
        },
      );

      test(
        'finds document if intermediate path segment does not exist',
        () async {
          final results = await table.search(
            where('address.city.street').notExists(),
          );

          expect(results.length, 5);
        },
      );
    });

    group('Query Numeric Comparisons', () {
      group('Query.greaterThan()', () {
        test('finds documents where age > 25', () async {
          final results = await table.search(where('age').greaterThan(25));
          expect(results.length, 2);
          expect(results.map((d) => d['id']), containsAll([1, 3]));
        });
        test('returns empty if no document matches age > 30', () async {
          final results = await table.search(where('age').greaterThan(30));
          expect(results, isEmpty);
        });
        test('returns empty if field does not exist', () async {
          final results = await table.search(where('score').greaterThan(10));
          expect(results, isEmpty);
        });
        test('returns empty if field value is not a number', () async {
          final results = await table.search(
            where('name').greaterThan(10 as dynamic),
          );
          expect(results, isEmpty);
          final resultsForNullAge = await table.search(
            where('age').greaterThan(10),
          );
          expect(resultsForNullAge.any((d) => d['id'] == 5), isFalse);
        });
      });

      group('Query.lessThan()', () {
        test('finds documents where age < 30', () async {
          final results = await table.search(where('age').lessThan(30));
          expect(results.length, 1);
          expect(results[0]['id'], 2);
        });
        test('returns empty if no document matches age < 24', () async {
          final results = await table.search(where('age').lessThan(24));
          expect(results, isEmpty);
        });
      });

      group('Query.greaterThanOrEquals()', () {
        test('finds documents where age >= 30', () async {
          final results = await table.search(
            where('age').greaterThanOrEquals(30),
          );
          expect(results.length, 2);
          expect(results.map((d) => d['id']), containsAll([1, 3]));
        });
        test('finds documents where age >= 24', () async {
          final results = await table.search(
            where('age').greaterThanOrEquals(24),
          );
          expect(results.length, 3);
          expect(results.map((d) => d['id']), containsAll([1, 2, 3]));
        });
      });

      group('Query.lessThanOrEquals()', () {
        test('finds documents where age <= 24', () async {
          final results = await table.search(where('age').lessThanOrEquals(24));
          expect(results.length, 1);
          expect(results[0]['id'], 2);
        });
        test('finds documents where age <= 30', () async {
          final results = await table.search(where('age').lessThanOrEquals(30));
          expect(results.length, 3);
          expect(results.map((d) => d['id']), containsAll([1, 2, 3]));
        });
      });
    });

    group('Query.matches() (Regex full match)', () {
      test(
        'finds document where name fully matches regex (case sensitive)',
        () async {
          final results = await table.search(where('name').matches(r'^Alice$'));
          expect(results.length, 1);
          expect(results[0]['id'], 1);
        },
      );

      test(
        'finds document where name fully matches regex (case insensitive)',
        () async {
          final results = await table.search(
            where(
              'description',
            ).matches(r'^bob is a software developer\.$', caseSensitive: false),
          );
          expect(results.length, 1);
          expect(results[0]['id'], 2);
        },
      );

      test('does not find if not a full match', () async {
        final results = await table.search(where('name').matches(r'^Ali$'));
        expect(results, isEmpty);
      });

      test(
        'returns empty if field is not a string or does not exist',
        () async {
          expect(await table.search(where('age').matches(r'.*')), isEmpty);
          expect(
            await table.search(where('non_existent').matches(r'.*')),
            isEmpty,
          );
        },
      );
    });

    group('Query.search() (Regex substring match)', () {
      test(
        'finds document where description contains substring (case sensitive)',
        () async {
          final results = await table.search(
            where('description').search(r'Developer'),
          );
          expect(results.length, 1);
          expect(results[0]['id'], 2);
        },
      );

      test(
        'finds document where description contains substring (case insensitive)',
        () async {
          final results = await table.search(
            where('description').search(r'book', caseSensitive: false),
          );
          expect(results.length, 1);
          expect(results[0]['id'], 3);
        },
      );

      test('finds multiple documents matching substring', () async {
        final results = await table.search(
          where(
            'description',
          ).search(r'person|Developer|apples', caseSensitive: false),
        );

        expect(results.length, 3);
        expect(results.map((d) => d['id']), containsAll([1, 2, 5]));
      });

      test('returns empty if no substring match', () async {
        final results = await table.search(
          where('description').search(r'XYZ_NO_MATCH'),
        );
        expect(results, isEmpty);
      });

      test(
        'returns empty if field is not a string or does not exist for search',
        () async {
          expect(await table.search(where('age').search(r'\d+')), isEmpty);
          expect(
            await table.search(where('non_existent').search(r'abc')),
            isEmpty,
          );
        },
      );
    });

    group('Query.test() (Custom function)', () {
      test(
        'finds documents using custom test on top-level field (age)',
        () async {
          final results = await table.search(
            where('age').test((val) => val is num && val == 30),
          );
          expect(results.length, 2);
          expect(results.map((d) => d['id']), containsAll([1, 3]));
        },
      );

      test(
        'finds documents using custom test on nested field (address.zip)',
        () async {
          final results = await table.search(
            where('address.zip').test((val) => val == '10001'),
          );
          expect(results.length, 1);
          expect(results[0]['id'], 1);
        },
      );

      test('custom test receives null if field value is null', () async {
        dynamic receivedValue;
        await table.search(
          where('misc').test((val) {
            if (val == null) receivedValue = null;
            return val == null;
          }),
        );
        expect(
          receivedValue,
          isNull,
          reason: "Custom test should receive null for Bob's 'misc' field",
        );

        final results = await table.search(
          where('misc').test((val) => val == null),
        );
        expect(results.length, 1);
        expect(results[0]['id'], 2);
      });

      test(
        'custom test is not called / returns false if field does not exist',
        () async {
          bool testFnCalled = false;
          final results = await table.search(
            where('non_existent_field').test((val) {
              testFnCalled = true;
              return true;
            }),
          );
          expect(results, isEmpty);
          expect(
            testFnCalled,
            isFalse,
            reason:
                "Custom test should not be called for non-existent field if Query.test handles _NotFoundSentinel by returning false.",
          );
        },
      );

      test(
        'custom test handles different data types (e.g. list length)',
        () async {
          final results = await table.search(
            where('tags').test((val) {
              return val is List && val.length == 2;
            }),
          );

          expect(results.length, 3);
          expect(results.map((d) => d['id']), containsAll([1, 2, 3]));
        },
      );

      test('custom test throwing an error results in non-match', () async {
        final results = await table.search(
          where('age').test((val) {
            if (val == 24) throw Exception("Test error");
            return val == 30;
          }),
        );

        expect(results.length, 2);
        expect(results.map((d) => d['id']), containsAll([1, 3]));
        expect(results.any((d) => d['id'] == 2), isFalse);
      });
    });

    group('Query Logical Combinators', () {
      test('AND combinator', () async {
        final q1 = where(
          'age',
        ).equals(30).and(where('address.city').equals('New York'));
        final results1 = await table.search(q1);
        expect(results1.length, 1);
        expect(results1[0]['id'], 1);

        final q2 = where('age').equals(30).and(where('name').equals('Bob'));
        final results2 = await table.search(q2);
        expect(results2, isEmpty);

        final q3 = where('age')
            .equals(30)
            .and(where('address.city').equals('New York'))
            .and(where('name').equals('Alice'));
        final results3 = await table.search(q3);
        expect(results3.length, 1);
        expect(results3[0]['id'], 1);
      });

      test('OR combinator', () async {
        final q1 = where(
          'age',
        ).equals(24).or(where('address.city').equals('New York'));
        final results1 = await table.search(q1);

        expect(results1.length, 2);
        expect(results1.map((d) => d['id']), containsAll([1, 2]));

        final q2 = where(
          'name',
        ).equals('David').or(where('name').equals('Eve'));
        final results2 = await table.search(q2);
        expect(results2.length, 2);
        expect(results2.map((d) => d['id']), containsAll([4, 5]));

        final q3 = where('name')
            .equals('David')
            .or(where('name').equals('Eve'))
            .or(where('age').equals(24));
        final results3 = await table.search(q3);

        expect(results3.length, 3);
        expect(results3.map((d) => d['id']), containsAll([2, 4, 5]));
      });

      test('NOT combinator', () async {
        final q1 = where('age').equals(24).not();
        final results1 = await table.search(q1);
        expect(results1.length, 4);
        expect(results1.any((d) => d['id'] == 2), isFalse);

        final q2 = where('address.city').equals('New York').not();
        final results2 = await table.search(q2);
        expect(results2.length, 4);
        expect(results2.any((d) => d['id'] == 1), isFalse);

        final q3 = where('misc').exists().not();
        final results3 = await table.search(q3);
        expect(results3.length, 3);
        expect(results3.map((d) => d['id']), containsAll([1, 3, 5]));
      });

      test(
        'Complex combination: (age > 25 AND city == London) OR name == David',
        () async {
          final ageQuery = where('age').greaterThan(25);
          final cityQuery = where('address.city').equals('London');
          final nameQuery = where('name').equals('David');

          final combinedQuery = (ageQuery.and(cityQuery)).or(nameQuery);

          final results = await table.search(combinedQuery);
          expect(results.length, 1);
          expect(results[0]['id'], 4);
        },
      );

      test(
        'Complex combination with NOT: NOT (age == 30 AND city == New York) OR name == Bob',
        () async {
          final condition1 = where(
            'age',
          ).equals(30).and(where('address.city').equals('New York'));
          final notCondition1 = condition1.not();
          final condition2 = where('name').equals('Bob');

          final combinedQuery = notCondition1.or(condition2);
          final results = await table.search(combinedQuery);

          expect(results.length, 4);
          expect(results.map((d) => d['id']), containsAll([2, 3, 4, 5]));
          expect(results.any((d) => d['id'] == 1), isFalse);
        },
      );
    });

    group('QueryCondition Equality and Hashing', () {
      test('_PathValueTestQuery equality and hashCode', () {
        final q1 = where('name').equals('Alice');
        final q2 = where('name').equals('Alice');
        final q3 = where('name').equals('Bob');
        final q4 = where('age').equals('Alice');
        final q5 = where('name').notEquals('Alice');
        final q6 = where('name').matches('Alice');

        expect(
          q1 == q2,
          isTrue,
          reason: "Identical value queries should be equal",
        );
        expect(
          q1.hashCode == q2.hashCode,
          isTrue,
          reason: "HashCodes for identical value queries should be equal",
        );

        expect(q1 == q3, isFalse, reason: "Different comparison value");
        expect(q1 == q4, isFalse, reason: "Different path");
        expect(
          q1 == q5,
          isFalse,
          reason: "Different operation (_ValueTestOperation)",
        );
        expect(
          q1 == q6,
          isFalse,
          reason: "Different operation and params for regex",
        );

        final r1 = where('desc').matches('^A.*', caseSensitive: true);
        final r2 = where('desc').matches('^A.*', caseSensitive: true);
        final r3 = where('desc').matches('^B.*', caseSensitive: true);
        final r4 = where('desc').matches('^A.*', caseSensitive: false);

        expect(r1 == r2, isTrue);
        expect(r1.hashCode == r2.hashCode, isTrue);
        expect(r1 == r3, isFalse);
        expect(r1 == r4, isFalse);

        final n1 = where('age').greaterThan(20);
        final n2 = where('age').greaterThan(20);
        final n3 = where('age').greaterThan(25);
        final n4 = where('age').lessThan(20);

        expect(n1 == n2, isTrue);
        expect(n1.hashCode == n2.hashCode, isTrue);
        expect(n1 == n3, isFalse);
        expect(n1 == n4, isFalse);

        final nl1 = where('misc').isNull();
        final nl2 = where('misc').isNull();
        final nnl1 = where('misc').isNotNull();

        expect(nl1 == nl2, isTrue);
        expect(nl1.hashCode == nl2.hashCode, isTrue);
        expect(nl1 == nnl1, isFalse);
      });

      test('_ExistsQueryCondition equality and hashCode', () {
        final q1 = where('address').exists();
        final q2 = where('address').exists();
        final q3 = where('name').exists();

        expect(q1 == q2, isTrue);
        expect(q1.hashCode == q2.hashCode, isTrue);
        expect(q1 == q3, isFalse);
      });

      test('_NotQueryCondition equality and hashCode', () {
        final eq1 = where('name').equals('Alice');
        final eq2 = where('name').equals('Alice');
        final eq3 = where('name').equals('Bob');

        final notQ1 = eq1.not();
        final notQ2 = eq2.not();
        final notQ3 = eq3.not();
        final notExists = where('age').exists().not();

        expect(notQ1 == notQ2, isTrue);
        expect(notQ1.hashCode == notQ2.hashCode, isTrue);
        expect(notQ1 == notQ3, isFalse);
        expect(notQ1 == notExists, isFalse);
      });

      test('_AndQueryCondition equality and hashCode', () {
        final a1 = where('name').equals('A');
        final a2 = where('age').greaterThan(10);
        final a3 = where('city').exists();

        final and1 = a1.and(a2);
        final and2 = a1.and(a2);
        final and3 = a2.and(a1);
        final and4 = a1.and(a3);

        expect(and1 == and2, isTrue);
        expect(and1.hashCode == and2.hashCode, isTrue);

        expect(
          and1 == and3,
          isFalse,
          reason: "Order of conditions matters for ListEquality",
        );

        expect(and1 == and4, isFalse);
      });

      test('_OrQueryCondition equality and hashCode', () {
        final o1 = where('name').equals('A');
        final o2 = where('age').greaterThan(10);
        final o3 = where('city').exists();

        final or1 = o1.or(o2);
        final or2 = o1.or(o2);
        final or3 = o2.or(o1);
        final or4 = o1.or(o3);

        expect(or1 == or2, isTrue);
        expect(or1.hashCode == or2.hashCode, isTrue);
        expect(
          or1 == or3,
          isFalse,
          reason: "Order of conditions matters for ListEquality",
        );
        expect(or1 == or4, isFalse);
      });

      test('Different QueryCondition types are not equal', () {
        final qPathValue = where('name').equals('Test');
        final qExists = where('name').exists();
        final qNot = where('name').equals('Test').not();
        final qAnd = where('name').equals('A').and(where('age').equals(1));
        final qOr = where('name').equals('A').or(where('age').equals(1));

        expect(qPathValue == qExists, isFalse);
        expect(qPathValue == qNot, isFalse);
        expect(qPathValue == qAnd, isFalse);
        expect(qPathValue == qOr, isFalse);
        expect(qExists == qNot, isFalse);
      });

      test('Equality with null and other types', () {
        final q = where('name').equals('A');

        expect(q == null, isFalse);

        expect(identical(q, "a string"), isFalse);
      });

      test('Query.test() equality (current known limitation)', () {
        bool myTestFn1(dynamic v) => v == true;
        bool myTestFn2(dynamic v) => v == true;

        final qCustom1 = where('field').test(myTestFn1);
        final qCustom2 = where('field').test(myTestFn1);
        final qCustom3 = where('field').test(myTestFn2);

        expect(
          qCustom1 == qCustom2,
          isTrue,
          reason:
              "Custom test with same path and identical function instance should be equal",
        );

        expect(
          qCustom1 == qCustom3,
          isTrue,
          reason:
              "KNOWN LIMITATION: Custom tests with same path but different function instances are currently equal because function identity is not part of _PathValueTestQuery's == logic beyond the operation type.",
        );
      });
    });
  });
}
