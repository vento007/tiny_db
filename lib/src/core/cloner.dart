dynamic _deepCopyValue(dynamic value) {
  if (value is Map) {
    return value.map((k, v) => MapEntry(_deepCopyValue(k), _deepCopyValue(v)));
  } else if (value is List) {
    return value.map(_deepCopyValue).toList();
  } else if (value is Set) {
    return value.map(_deepCopyValue).toSet();
  } else {
    return value;
  }
}

extension DeepCopyList<T> on List<T> {
  List<T> deepCopy() => List<T>.from(map((e) => _deepCopyValue(e) as T));
}

extension DeepCopyMap<K, V> on Map<K, V> {
  Map<K, V> deepCopy() => Map<K, V>.fromEntries(
    entries.map(
      (e) => MapEntry(_deepCopyValue(e.key) as K, _deepCopyValue(e.value) as V),
    ),
  );
}

extension DeepCopySet<T> on Set<T> {
  Set<T> deepCopy() => Set<T>.from(map((e) => _deepCopyValue(e) as T));
}
