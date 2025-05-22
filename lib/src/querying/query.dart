import 'package:collection/collection.dart';

import '../core/types.dart';

enum _ValueTestOperation {
  equals,
  notEquals,
  isNull,
  isNotNull,
  greaterThan,
  lessThan,
  greaterThanOrEquals,
  lessThanOrEquals,
  matchesRegex,
  searchRegex,
  customTest,
}

class _NotFoundSentinel {
  const _NotFoundSentinel();
}

const _notFound = _NotFoundSentinel();

dynamic _resolvePath(Document doc, List<String> path) {
  dynamic current = doc;
  for (final segment in path) {
    if (current is Map<String, dynamic> && current.containsKey(segment)) {
      current = current[segment];
    } else if (current is List && int.tryParse(segment) != null) {
      return _notFound;
    } else {
      return _notFound;
    }
  }
  return current;
}

abstract class QueryCondition {
  bool test(Document document);

  QueryCondition and(QueryCondition other) {
    if (this is _AndQueryCondition) {
      return _AndQueryCondition([
        ...(this as _AndQueryCondition)._conditions,
        other,
      ]);
    }
    return _AndQueryCondition([this, other]);
  }

  QueryCondition or(QueryCondition other) {
    if (this is _OrQueryCondition) {
      return _OrQueryCondition([
        ...(this as _OrQueryCondition)._conditions,
        other,
      ]);
    }
    return _OrQueryCondition([this, other]);
  }

  QueryCondition not() {
    return _NotQueryCondition(this);
  }
}

class _ListContainsAnyQueryCondition extends QueryCondition {
  final List<String> _path;
  final List<dynamic> _expectedValues;
  final Set<dynamic> _expectedValuesSet;

  _ListContainsAnyQueryCondition(this._path, List<dynamic> expectedValues)
    : _expectedValues = List.unmodifiable(expectedValues),
      _expectedValuesSet = Set.unmodifiable(expectedValues.toSet());

  @override
  bool test(Document document) {
    if (_expectedValues.isEmpty) {
      return false;
    }
    final valueAtPath = _resolvePath(document, _path);
    if (valueAtPath is _NotFoundSentinel || valueAtPath is! List) {
      return false;
    }
    if (valueAtPath.isEmpty) {
      return false;
    }

    for (final itemInDocList in valueAtPath) {
      if (_expectedValuesSet.contains(itemInDocList)) {
        return true;
      }
    }
    return false;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _ListContainsAnyQueryCondition &&
        const ListEquality().equals(_path, other._path) &&
        const ListEquality().equals(_expectedValues, other._expectedValues);
  }

  @override
  int get hashCode => Object.hash(
    const ListEquality().hash(_path),
    const ListEquality().hash(_expectedValues),
  );
}

class _ListContainsAllQueryCondition extends QueryCondition {
  final List<String> _path;
  final List<dynamic> _expectedValues;

  _ListContainsAllQueryCondition(
    List<String> path,
    List<dynamic> expectedValues,
  ) : _path = List.unmodifiable(path),
      _expectedValues = List.unmodifiable(expectedValues);

  @override
  bool test(Document document) {
    final valueAtPath = _resolvePath(document, _path);
    if (valueAtPath is _NotFoundSentinel || valueAtPath is! List) {
      return false;
    }
    if (_expectedValues.isEmpty) {
      return true;
    }
    final List<dynamic> docList = valueAtPath;
    final Set<dynamic> docListSet = Set.from(docList);
    for (final expectedItem in _expectedValues) {
      if (!docListSet.contains(expectedItem)) {
        return false;
      }
    }
    return true;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _ListContainsAllQueryCondition) return false;

    final bool pathsEqual = const ListEquality().equals(_path, other._path);
    final bool valuesEqual = const ListEquality().equals(
      _expectedValues,
      other._expectedValues,
    );

    return pathsEqual && valuesEqual;
  }

  @override
  int get hashCode => Object.hash(
    const ListEquality().hash(_path),
    const ListEquality().hash(_expectedValues),
  );
}

class _ListElementTestQueryCondition extends QueryCondition {
  final List<String> _path;
  final QueryCondition _elementCondition;
  final bool _testAllElements;

  _ListElementTestQueryCondition(
    this._path,
    this._elementCondition,
    this._testAllElements,
  );

  @override
  bool test(Document document) {
    final valueAtPath = _resolvePath(document, _path);
    if (valueAtPath is _NotFoundSentinel || valueAtPath is! List) {
      return false;
    }

    final List<dynamic> listAtPath = valueAtPath;

    if (listAtPath.isEmpty) {
      return _testAllElements;
    }

    for (final element in listAtPath) {
      bool elementMatches;
      if (element is Map<String, dynamic>) {
        elementMatches = _elementCondition.test(element);
      } else {
        elementMatches = _elementCondition.test({'value': element});

        Document elementDoc;
        if (element is Map<String, dynamic>) {
          elementDoc = element;
        } else {
          elementDoc = {'value': element};
        }
        elementMatches = _elementCondition.test(elementDoc);
      }

      if (_testAllElements) {
        if (!elementMatches) return false;
      } else {
        if (elementMatches) return true;
      }
    }

    return _testAllElements;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _ListElementTestQueryCondition &&
        const ListEquality().equals(_path, other._path) &&
        _elementCondition == other._elementCondition &&
        _testAllElements == other._testAllElements;
  }

  @override
  int get hashCode => Object.hash(
    const ListEquality().hash(_path),
    _elementCondition,
    _testAllElements,
  );
}

class _AndQueryCondition extends QueryCondition {
  final List<QueryCondition> _conditions;

  _AndQueryCondition(List<QueryCondition> conditions)
    : _conditions = List.unmodifiable(conditions) {
    if (_conditions.isEmpty) {
      throw ArgumentError('AND condition requires at least one sub-condition.');
    }
  }

  @override
  bool test(Document document) {
    for (final condition in _conditions) {
      if (!condition.test(document)) return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _AndQueryCondition &&
        const ListEquality().equals(_conditions, other._conditions);
  }

  @override
  int get hashCode => const ListEquality().hash(_conditions);
}

class _OrQueryCondition extends QueryCondition {
  final List<QueryCondition> _conditions;
  _OrQueryCondition(List<QueryCondition> conditions)
    : _conditions = List.unmodifiable(conditions) {
    if (_conditions.isEmpty) {
      throw ArgumentError('OR condition requires at least one sub-condition.');
    }
  }

  @override
  bool test(Document document) {
    for (final condition in _conditions) {
      if (condition.test(document)) return true;
    }
    return false;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _OrQueryCondition &&
        const ListEquality().equals(_conditions, other._conditions);
  }

  @override
  int get hashCode => const ListEquality().hash(_conditions);
}

class _PathValueTestQuery extends QueryCondition {
  final List<String> _path;
  final bool Function(dynamic valueAtPath) _valueTest;

  final _ValueTestOperation _operation;
  final dynamic _comparisonValue;

  final String? _regexPattern;
  final bool? _regexCaseSensitive;

  _PathValueTestQuery(
    this._path,
    this._valueTest, {
    required _ValueTestOperation operation,
    dynamic comparisonValue,
    String? regexPattern,
    bool? regexCaseSensitive,
  }) : _operation = operation,
       _comparisonValue = comparisonValue,
       _regexPattern = regexPattern,
       _regexCaseSensitive = regexCaseSensitive;

  @override
  bool test(Document document) {
    final valueAtActualPath = _resolvePath(document, _path);
    return _valueTest(valueAtActualPath);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _PathValueTestQuery) return false;

    if (_path.length != other._path.length) return false;
    for (int i = 0; i < _path.length; i++) {
      if (_path[i] != other._path[i]) return false;
    }

    return _operation == other._operation &&
        _comparisonValue == other._comparisonValue &&
        _regexPattern == other._regexPattern &&
        _regexCaseSensitive == other._regexCaseSensitive;
  }

  @override
  int get hashCode {
    int pathHash = 0;
    for (final segment in _path) {
      pathHash = pathHash * 31 + segment.hashCode;
    }

    return Object.hash(
      pathHash,
      _operation,
      _comparisonValue,
      _regexPattern,
      _regexCaseSensitive,
    );
  }
}

class _ExistsQueryCondition extends QueryCondition {
  final List<String> _path;
  _ExistsQueryCondition(this._path);

  @override
  bool test(Document document) {
    if (_path.isEmpty) return false;
    dynamic current = document;
    for (int i = 0; i < _path.length - 1; i++) {
      final segment = _path[i];
      if (current is Map<String, dynamic> && current.containsKey(segment)) {
        current = current[segment];
      } else {
        return false;
      }
    }
    if (current is Map<String, dynamic>) {
      return current.containsKey(_path.last);
    }
    return false;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _ExistsQueryCondition) return false;
    if (_path.length != other._path.length) return false;
    for (int i = 0; i < _path.length; i++) {
      if (_path[i] != other._path[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    int pathHash = 0;
    for (final segment in _path) {
      pathHash = pathHash * 31 + segment.hashCode;
    }
    return pathHash;
  }
}

class _NotQueryCondition extends QueryCondition {
  final QueryCondition _conditionToNegate;
  _NotQueryCondition(this._conditionToNegate);

  @override
  bool test(Document document) {
    return !_conditionToNegate.test(document);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _NotQueryCondition &&
        _conditionToNegate == other._conditionToNegate;
  }

  @override
  int get hashCode => _conditionToNegate.hashCode * -1;
}

class Query {
  final List<String> _currentPath;

  Query._(this._currentPath);

  factory Query(String fieldPath) {
    if (fieldPath.isEmpty) {
      return Query._([]);
    }

    return Query._(fieldPath.split('.'));
  }

  factory Query.path(List<String> fieldPathSegments) {
    return Query._(List.unmodifiable(fieldPathSegments));
  }
  QueryCondition equals(dynamic expectedValue) {
    return _PathValueTestQuery(
      _currentPath,
      (valueAtPath) {
        if (valueAtPath is _NotFoundSentinel) return false;
        return valueAtPath == expectedValue;
      },
      operation: _ValueTestOperation.equals,
      comparisonValue: expectedValue,
    );
  }

  QueryCondition notEquals(dynamic unexpectedValue) {
    return _PathValueTestQuery(
      _currentPath,
      (valueAtPath) {
        if (valueAtPath is _NotFoundSentinel) return true;
        return valueAtPath != unexpectedValue;
      },
      operation: _ValueTestOperation.notEquals,
      comparisonValue: unexpectedValue,
    );
  }

  QueryCondition exists() {
    return _ExistsQueryCondition(_currentPath);
  }

  QueryCondition notExists() {
    return _NotQueryCondition(_ExistsQueryCondition(_currentPath));
  }

  QueryCondition isNull() {
    return _PathValueTestQuery(_currentPath, (valueAtPath) {
      if (valueAtPath is _NotFoundSentinel) return false;
      return valueAtPath == null;
    }, operation: _ValueTestOperation.isNull);
  }

  QueryCondition isNotNull() {
    return _PathValueTestQuery(_currentPath, (valueAtPath) {
      if (valueAtPath is _NotFoundSentinel) return false;
      return valueAtPath != null;
    }, operation: _ValueTestOperation.isNotNull);
  }

  QueryCondition _numericComparison(
    num comparisonValue,
    bool Function(num valueAtNum, num compareTo) operatorFn,
    _ValueTestOperation operationEnum,
  ) {
    return _PathValueTestQuery(
      _currentPath,
      (valueAtPath) {
        if (valueAtPath is _NotFoundSentinel || valueAtPath is! num) {
          return false;
        }
        return operatorFn(valueAtPath, comparisonValue);
      },
      operation: operationEnum,
      comparisonValue: comparisonValue,
    );
  }

  QueryCondition greaterThan(num value) {
    return _numericComparison(
      value,
      (val, comp) => val > comp,
      _ValueTestOperation.greaterThan,
    );
  }

  QueryCondition lessThan(num value) {
    return _numericComparison(
      value,
      (val, comp) => val < comp,
      _ValueTestOperation.lessThan,
    );
  }

  QueryCondition greaterThanOrEquals(num value) {
    return _numericComparison(
      value,
      (val, comp) => val >= comp,
      _ValueTestOperation.greaterThanOrEquals,
    );
  }

  QueryCondition lessThanOrEquals(num value) {
    return _numericComparison(
      value,
      (val, comp) => val <= comp,
      _ValueTestOperation.lessThanOrEquals,
    );
  }

  QueryCondition matches(String regexPattern, {bool caseSensitive = true}) {
    return _PathValueTestQuery(
      _currentPath,
      (valueAtPath) {
        if (valueAtPath is _NotFoundSentinel || valueAtPath is! String) {
          return false;
        }
        final regex = RegExp(regexPattern, caseSensitive: caseSensitive);
        final match = regex.stringMatch(valueAtPath);
        return match == valueAtPath;
      },
      operation: _ValueTestOperation.matchesRegex,
      regexPattern: regexPattern,
      regexCaseSensitive: caseSensitive,
    );
  }

  QueryCondition search(String regexPattern, {bool caseSensitive = true}) {
    return _PathValueTestQuery(
      _currentPath,
      (valueAtPath) {
        if (valueAtPath is _NotFoundSentinel || valueAtPath is! String) {
          return false;
        }
        final regex = RegExp(regexPattern, caseSensitive: caseSensitive);
        return regex.hasMatch(valueAtPath);
      },
      operation: _ValueTestOperation.searchRegex,
      regexPattern: regexPattern,
      regexCaseSensitive: caseSensitive,
    );
  }

  QueryCondition test(bool Function(dynamic valueAtPath) customTest) {
    return _PathValueTestQuery(_currentPath, (valueAtPath) {
      if (valueAtPath is _NotFoundSentinel) return false;
      try {
        return customTest(valueAtPath);
      } catch (e) {
        return false;
      }
    }, operation: _ValueTestOperation.customTest);
  }

  QueryCondition anyInList(List<dynamic> values) {
    return _ListContainsAnyQueryCondition(_currentPath, values);
  }

  QueryCondition allInList(List<dynamic> values) {
    return _ListContainsAllQueryCondition(_currentPath, values);
  }

  QueryCondition anyElementSatisfies(QueryCondition elementCondition) {
    return _ListElementTestQueryCondition(
      _currentPath,
      elementCondition,
      false,
    );
  }

  QueryCondition allElementsSatisfy(QueryCondition elementCondition) {
    return _ListElementTestQueryCondition(_currentPath, elementCondition, true);
  }
}

Query where(String fieldPath) {
  return Query(fieldPath);
}
