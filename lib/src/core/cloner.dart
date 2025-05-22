dynamic deepCopyValue(dynamic value) {
  if (value is Map) {
    return value.map((k, v) => MapEntry(deepCopyValue(k), deepCopyValue(v)));
  } else if (value is List) {
    return value.map(deepCopyValue).toList();
  } else if (value is Set) {
    return value.map(deepCopyValue).toSet();
  } else {
    return value;
  }
}

extension DeepCopyList<T> on List<T> {
  List<dynamic> deepCopy() {
    return map((e) => deepCopyValue(e)).toList();
  }
}

extension DeepCopyMap<K, V> on Map<K, V> {
  Map<dynamic, dynamic> deepCopy() {
    return map((k, v) => MapEntry(deepCopyValue(k), deepCopyValue(v)));
  }
}

extension DeepCopySet<T> on Set<T> {
  Set<dynamic> deepCopy() {
    return map((e) => deepCopyValue(e)).toSet();
  }
}
