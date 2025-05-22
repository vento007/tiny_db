import 'package:test/test.dart';
import 'package:tiny_db/src/core/cloner.dart';

void main() {
  group('DeepCopyList', () {
    test('copies simple list', () {
      final original = [1, 2, 3];
      final copy = original.deepCopy();
      expect(copy, equals(original));
      expect(copy, isNot(same(original)));
    });

    test('copies nested list', () {
      final original = [
        [1, 2],
        [3, 4],
      ];
      final copy = original.deepCopy();
      expect(copy, equals(original));
      expect(copy[0], isNot(same(original[0])));
    });

    test('copies list with maps', () {
      final original = [
        {'a': 1},
        {'b': 2},
      ];
      final copy = original.deepCopy();
      expect(copy, equals(original));
      expect(copy[0], isNot(same(original[0])));
    });
  });

  group('DeepCopyMap', () {
    test('copies simple map', () {
      final original = {'a': 1, 'b': 2};
      final copy = original.deepCopy();
      expect(copy, equals(original));
      expect(copy, isNot(same(original)));
    });

    test('copies nested map', () {
      final original = {
        'a': {'b': 1},
        'c': {'d': 2},
      };
      final copy = original.deepCopy();
      expect(copy, equals(original));
      expect(copy['a'], isNot(same(original['a'])));
    });

    test('copies map with lists', () {
      final original = {
        'a': [1, 2],
        'b': [3, 4],
      };
      final copy = original.deepCopy();
      expect(copy, equals(original));
      expect(copy['a'], isNot(same(original['a'])));
    });
  });

  group('DeepCopySet', () {
    test('copies simple set', () {
      final original = {1, 2, 3};
      final copy = original.deepCopy();
      expect(copy, equals(original));
      expect(copy, isNot(same(original)));
    });

    test('copies set with lists', () {
      final original = {
        [1, 2],
        [3, 4],
      };
      final copy = original.deepCopy();
      expect(copy, equals(original));
      expect(copy.first, isNot(same(original.first)));
    });

    test('copies set with maps', () {
      final original = {
        {'a': 1},
        {'b': 2},
      };
      final copy = original.deepCopy();
      expect(copy, equals(original));
      expect(copy.first, isNot(same(original.first)));
    });
  });

  group('deepCopyValue', () {
    test('handles null', () {
      expect(deepCopyValue(null), isNull);
    });

    test('handles primitive values', () {
      expect(deepCopyValue(42), equals(42));
      expect(deepCopyValue('string'), equals('string'));
      expect(deepCopyValue(true), isTrue);
    });

    test('handles complex nested structures', () {
      final original = {
        'a': [
          {
            'b': {1, 2, 3},
          },
          [4, 5, 6],
        ],
      };
      final copy = deepCopyValue(original);
      expect(copy, equals(original));
      final copyList = (copy as Map)['a'] as List;
      final copyMap = copyList[0] as Map;
      final originalList = (original['a']) as List;
      final originalMap = originalList[0] as Map;
      expect(copyMap['b'], isNot(same(originalMap['b'])));
    });
  });
}
