import 'dart:async';
import 'dart:convert';

import 'storage.dart';

class MemoryStorage extends Storage {
  Map<String, dynamic>? _memory;

  MemoryStorage();

  Map<String, dynamic>? _deepCopy(Map<String, dynamic>? source) {
    if (source == null) {
      return null;
    }

    return json.decode(json.encode(source)) as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>?> read() async {
    await Future.delayed(Duration.zero);
    return _deepCopy(_memory);
  }

  @override
  Future<void> write(Map<String, dynamic> data) async {
    await Future.delayed(Duration.zero);
    _memory = _deepCopy(data);
  }

  @override
  Future<void> close() async {
    await Future.delayed(Duration.zero);
  }

  Future<void> clear() async {
    await Future.delayed(Duration.zero);
    _memory = null;
  }
}
