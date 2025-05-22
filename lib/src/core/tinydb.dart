import 'dart:async';

import '../storages/storage.dart';
import 'table.dart';
import 'types.dart';

const String defaultTableName = '_default';

class TinyDb {
  final Storage _storage;
  final Map<TableName, Table> _tables = {};
  bool _isClosed = false;

  TinyDb(this._storage);

  Table table(TableName name) {
    if (_isClosed) {
      throw StateError('Database is closed.');
    }
    if (_tables.containsKey(name)) {
      return _tables[name]!;
    } else {
      final newTable = Table(_storage, name);
      _tables[name] = newTable;
      return newTable;
    }
  }

  Table get defaultTable => table(defaultTableName);

  Future<void> close() async {
    if (_isClosed) {
      return;
    }
    await _storage.close();
    _tables.clear();
    _isClosed = true;
  }

  Future<Set<TableName>> tables() async {
    if (_isClosed) {
      throw StateError('Database is closed.');
    }
    final data = await _storage.read();
    return data?.keys.toSet() ?? <TableName>{};
  }

  Future<bool> dropTable(TableName name) async {
    if (_isClosed) {
      throw StateError('Database is closed.');
    }
    if (name == defaultTableName && _tables.containsKey(defaultTableName)) {}

    final data = await _storage.read();
    if (data != null && data.containsKey(name)) {
      data.remove(name);
      await _storage.write(data);
      _tables.remove(name);
      return true;
    }
    return false;
  }

  Future<void> dropTables() async {
    if (_isClosed) {
      throw StateError('Database is closed.');
    }
    await _storage.write({});
    _tables.clear();
  }

  Future<DocumentId> insert(Document document) {
    if (_isClosed) {
      throw StateError('Database is closed.');
    }
    return defaultTable.insert(document);
  }

  Future<List<DocumentId>> insertMultiple(List<Document> documents) {
    if (_isClosed) {
      throw StateError('Database is closed.');
    }
    return defaultTable.insertMultiple(documents);
  }

  Future<List<Document>> all() {
    if (_isClosed) {
      throw StateError('Database is closed.');
    }
    return defaultTable.all();
  }

  Future<Document?> getById(DocumentId id) {
    if (_isClosed) {
      throw StateError('Database is closed.');
    }
    return defaultTable.getById(id);
  }

  Future<int> get length {
    if (_isClosed) {
      throw StateError('Database is closed.');
    }
    return defaultTable.length;
  }

  Future<bool> get isEmpty {
    if (_isClosed) {
      throw StateError('Database is closed.');
    }
    return defaultTable.isEmpty;
  }

  Future<bool> get isNotEmpty {
    if (_isClosed) {
      throw StateError('Database is closed.');
    }
    return defaultTable.isNotEmpty;
  }

  Future<void> truncate() {
    if (_isClosed) {
      throw StateError('Database is closed.');
    }
    return defaultTable.truncate();
  }
}
