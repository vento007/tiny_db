import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:tiny_db/tiny_db.dart';
import 'cloner.dart';

class Table {
  final Storage _storage;
  final TableName name;

  Map<DocumentId, Document> _data = {};
  DocumentId _lastId = 0;
  bool _initialized = false;

  Table(this._storage, this.name);

  Document _deepCopyDocument(Document source) {
    return json.decode(json.encode(source)) as Document;
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await _loadDataFromStorage();
      _initialized = true;
    }
  }

  Future<void> _loadDataFromStorage() async {
    final allDbData = await _storage.read();
    _data = {};
    _lastId = 0;

    if (allDbData != null && allDbData.containsKey(name)) {
      final tableDataFromStorage = allDbData[name] as Map<String, dynamic>?;
      if (tableDataFromStorage != null) {
        DocumentId maxIdInTable = 0;
        tableDataFromStorage.forEach((idStr, docDataUnknownType) {
          try {
            final docId = int.parse(idStr);
            if (docDataUnknownType is Map<String, dynamic>) {
              _data[docId] = _deepCopyDocument(docDataUnknownType);
              if (docId > maxIdInTable) {
                maxIdInTable = docId;
              }
            } else {
              if (kDebugMode) {
                print(
                'Warning: Malformed document data for ID $idStr in table $name. Expected Map, got ${docDataUnknownType.runtimeType}. Skipping.',
              );
              }
            }
          } on FormatException {
            if (kDebugMode) {
              print(
                'Warning: Malformed document ID "$idStr" in table $name. Skipping.',
              );
            }
          }
        });
        _lastId = maxIdInTable;
      }
    }
  }

  Future<void> _updateDbInStorage(
    Function(Map<String, dynamic> currentTableData) updater,
  ) async {
    Map<String, dynamic> allDbData = (await _storage.read()) ?? {};
    Map<String, dynamic> tableDataForStorage =
        (allDbData[name] as Map<String, dynamic>?) ?? {};
    updater(tableDataForStorage);
    allDbData[name] = tableDataForStorage;
    await _storage.write(allDbData);
  }

  DocumentId _getNextId() {
    _lastId++;
    return _lastId;
  }

  Future<DocumentId> insert(Document document) async {
    await _ensureInitialized();
    final newId = _getNextId();
    final Document docToStore = _deepCopyDocument(document);
    _data[newId] = docToStore;
    await _updateDbInStorage((Map<String, dynamic> currentTableStorageData) {
      currentTableStorageData[newId.toString()] = docToStore;
    });
    return newId;
  }

  Future<List<DocumentId>> insertMultiple(List<Document> documents) async {
    if (documents.isEmpty) return [];
    await _ensureInitialized();
    final List<DocumentId> newIds = [];
    final Map<DocumentId, Document> docsToAddInMemory = {};
    final Map<String, Document> docsToAddForStorage = {};
    for (final document in documents) {
      final newId = _getNextId();
      final Document docToStore = _deepCopyDocument(document);
      newIds.add(newId);
      docsToAddInMemory[newId] = docToStore;
      docsToAddForStorage[newId.toString()] = docToStore;
    }
    _data.addAll(docsToAddInMemory);
    await _updateDbInStorage((Map<String, dynamic> currentTableStorageData) {
      currentTableStorageData.addAll(docsToAddForStorage);
    });
    return newIds;
  }

  Future<List<Document>> all() async {
    await _ensureInitialized();
    return _data.entries.map((entry) {
      final docCopy = _deepCopyDocument(entry.value);
      docCopy['doc_id'] = entry.key;
      return docCopy;
    }).toList();
  }

  Future<Document?> getById(DocumentId id) async {
    await _ensureInitialized();
    if (_data.containsKey(id)) {
      final docCopy = _deepCopyDocument(_data[id]!);
      docCopy['doc_id'] = id;
      return docCopy;
    }
    return null;
  }

  Future<int> get length async {
    await _ensureInitialized();
    return _data.length;
  }

  Future<bool> get isEmpty async {
    await _ensureInitialized();
    return _data.isEmpty;
  }

  Future<bool> get isNotEmpty async {
    await _ensureInitialized();
    return _data.isNotEmpty;
  }

  Future<void> truncate() async {
    await _ensureInitialized();
    _data.clear();
    _lastId = 0;
    await _updateDbInStorage((Map<String, dynamic> currentTableStorageData) {
      currentTableStorageData.clear();
    });
  }

  Future<List<Document>> search(QueryCondition queryCondition) async {
    await _ensureInitialized();
    final List<Document> results = [];
    _data.forEach((docId, docContent) {
      if (queryCondition.test(docContent)) {
        final docCopy = _deepCopyDocument(docContent);
        docCopy['doc_id'] = docId;
        results.add(docCopy);
      }
    });
    return results;
  }

  Future<Document?> get(QueryCondition queryCondition) async {
    await _ensureInitialized();
    for (final entry in _data.entries) {
      if (queryCondition.test(entry.value)) {
        final docCopy = _deepCopyDocument(entry.value);
        docCopy['doc_id'] = entry.key;
        return docCopy;
      }
    }
    return null;
  }

  bool _applyOperationsToDocument(Document doc, List<UpdateAction> actions) {
    bool changed = false;

    for (final action in actions) {
      dynamic current = doc;
      List<String> pathSegments = action.pathSegments;
      int i = 0;

      for (i = 0; i < pathSegments.length - 1; i++) {
        final segment = pathSegments[i];
        if (current is! Map<String, dynamic>) {
          current = null;
          break;
        }
        Map<String, dynamic> currentMap = current;
        if (!currentMap.containsKey(segment)) {
          if (action.type == UpdateOpType.set ||
              action.type == UpdateOpType.push ||
              action.type == UpdateOpType.addUnique) {
            currentMap[segment] = <String, dynamic>{};

            if (action.type == UpdateOpType.set) changed = true;
          } else {
            current = null;
            break;
          }
        }
        current = currentMap[segment];
      }

      if (current == null) {
        continue;
      }

      if (current is! Map<String, dynamic>) {
        if (kDebugMode) {
          print(
            'Warning: Cannot apply operation to path "${action.pathSegments.join('.')}". Intermediate path does not lead to a modifiable map. Current segment is of type ${current.runtimeType}.',
          );
        }
        continue;
      }

      final String targetField = pathSegments.last;
      final Map<String, dynamic> parentMap = current;

      switch (action.type) {
        case UpdateOpType.set:
          if (!parentMap.containsKey(targetField) ||
              parentMap[targetField] != action.value) {
            parentMap[targetField] = action.value;
            changed = true;
          }
          break;
        case UpdateOpType.delete:
          if (parentMap.containsKey(targetField)) {
            parentMap.remove(targetField);
            changed = true;
          }
          break;
        case UpdateOpType.increment:
          dynamic incCurrentValue = parentMap[targetField];
          num incAmount = action.value as num;
          if (incCurrentValue is num) {
            parentMap[targetField] = incCurrentValue + incAmount;
            changed = true;
          } else if (incCurrentValue == null &&
              !parentMap.containsKey(targetField)) {
            parentMap[targetField] = incAmount;
            changed = true;
          } else {
            if (kDebugMode) {
              print(
                'Warning: Cannot increment field "$targetField" in document. Value is "$incCurrentValue". Not a number or field missing for existing non-numeric value.',
              );
            }
          }
          break;
        case UpdateOpType.decrement:
          dynamic decCurrentValue = parentMap[targetField];
          num decAmount = action.value as num;
          if (decCurrentValue is num) {
            parentMap[targetField] = decCurrentValue - decAmount;
            changed = true;
          } else if (decCurrentValue == null &&
              !parentMap.containsKey(targetField)) {
            parentMap[targetField] = -decAmount;
            changed = true;
          } else {
            if (kDebugMode) {
                print(  
                'Warning: Cannot decrement field "$targetField" in document. Value is "$decCurrentValue". Not a number or field missing for existing non-numeric value.',
              );
            }
          }
          break;
        case UpdateOpType.push:
          dynamic listField = parentMap[targetField];

          if (listField == null && !parentMap.containsKey(targetField)) {
            parentMap[targetField] = [action.value];
            changed = true;
          } else if (listField is List) {
            List<dynamic> modifiableList = listField.deepCopy();
            modifiableList.add(action.value);
            parentMap[targetField] = modifiableList;
            changed = true;
          } else {
            if (kDebugMode) {
              print(
                'Warning: Cannot push to field "$targetField". It exists but is not a List (type: ${listField.runtimeType}). Value: $listField',
              );
            }
          }
          break;
        case UpdateOpType.pull:
          dynamic listFieldToPullFrom = parentMap[targetField];
          if (listFieldToPullFrom is List) {
            List<dynamic> modifiableList = listFieldToPullFrom.deepCopy();
            int initialLength = modifiableList.length;
            modifiableList.removeWhere(
              (item) => deepEquals(item, action.value),
            );
            if (modifiableList.length < initialLength) {
              parentMap[targetField] = modifiableList;
              changed = true;
            }
          } else if (parentMap.containsKey(targetField)) {
            if (kDebugMode) {
              print(
                'Warning: Cannot pull from field "$targetField". It exists but is not a List (type: ${listFieldToPullFrom.runtimeType}).',
              );
            }
          }
          break;

        case UpdateOpType.pop:
          dynamic listFieldToPopFrom = parentMap[targetField];
          if (listFieldToPopFrom is List) {
            List<dynamic> modifiableList = listFieldToPopFrom.deepCopy();
            if (modifiableList.isNotEmpty) {
              modifiableList.removeLast();
              parentMap[targetField] = modifiableList;
              changed = true;
            }
          } else if (parentMap.containsKey(targetField)) {
            if (kDebugMode) {
              print(
                'Warning: Cannot pop from field "$targetField". It exists but is not a List (type: ${listFieldToPopFrom.runtimeType}).',
              );
            }
          }
          break;

        case UpdateOpType.addUnique:
          dynamic listFieldForAddUnique = parentMap[targetField];

          if (listFieldForAddUnique == null &&
              !parentMap.containsKey(targetField)) {
            parentMap[targetField] = [action.value];
            changed = true;
          } else if (listFieldForAddUnique is List) {
            bool alreadyExists = false;
            for (final item in listFieldForAddUnique) {
              if (deepEquals(item, action.value)) {
                alreadyExists = true;
                break;
              }
            }
            if (!alreadyExists) {
              List<dynamic> modifiableList = listFieldForAddUnique.deepCopy();
              modifiableList.add(action.value);
              parentMap[targetField] = modifiableList;

              changed = true;
            } else {}
          } else if (parentMap.containsKey(targetField)) {
            if (kDebugMode) {
              print(
                'Warning: Cannot addUnique to field "$targetField". It exists but is not a List (type: ${listFieldForAddUnique.runtimeType}).',
              );
            }
          }
          break;
      }
    }
    return changed;
  }

  bool deepEquals(dynamic a, dynamic b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key)) return false;
        if (!deepEquals(a[key], b[key])) return false;
      }
      return true;
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (int i = 0; i < a.length; i++) {
        if (!deepEquals(a[i], b[i])) return false;
      }
      return true;
    }

    return a.runtimeType == b.runtimeType && a == b;
  }

  Future<List<DocumentId>> update(
    UpdateOperations operations,
    QueryCondition queryCondition,
  ) async {
    await _ensureInitialized();

    if (operations.actions.isEmpty) {
      return [];
    }

    final List<DocumentId> updatedIds = [];
    final Map<DocumentId, Document> docsToUpdateInStorage = {};

    _data.forEach((docIdInMap, docContent) {
      bool match = queryCondition.test(docContent);

      if (match) {
        Document mutableDocCopy = _deepCopyDocument(docContent);

        if (_applyOperationsToDocument(mutableDocCopy, operations.actions)) {
          _data[docIdInMap] = mutableDocCopy;
          docsToUpdateInStorage[docIdInMap] = mutableDocCopy;
          updatedIds.add(docIdInMap);
        }
      }
    });

    if (docsToUpdateInStorage.isNotEmpty) {
      await _updateDbInStorage((Map<String, dynamic> currentTableStorageData) {
        docsToUpdateInStorage.forEach((id, doc) {
          currentTableStorageData[id.toString()] = doc;
        });
      });
    }
    return updatedIds;
  }

  Future<List<DocumentId>> remove(QueryCondition queryCondition) async {
    await _ensureInitialized();
    final List<DocumentId> idsToRemove = [];

    final List<DocumentId> currentDocIds = _data.keys.toList();

    for (final docId in currentDocIds) {
      final docContent = _data[docId];
      if (docContent != null && queryCondition.test(docContent)) {
        idsToRemove.add(docId);
      }
    }

    if (idsToRemove.isEmpty) {
      return [];
    }

    for (final id in idsToRemove) {
      _data.remove(id);
    }

    await _updateDbInStorage((Map<String, dynamic> currentTableStorageData) {
      for (final id in idsToRemove) {
        currentTableStorageData.remove(id.toString());
      }
    });

    return idsToRemove;
  }

  Future<List<DocumentId>> removeByIds(List<DocumentId> ids) async {
    await _ensureInitialized();
    if (ids.isEmpty) {
      return [];
    }

    final List<DocumentId> successfullyRemovedIds = [];

    for (final id in ids) {
      if (_data.containsKey(id)) {
        _data.remove(id);
        successfullyRemovedIds.add(id);
      }
    }

    if (successfullyRemovedIds.isEmpty) {
      return [];
    }

    await _updateDbInStorage((Map<String, dynamic> currentTableStorageData) {
      for (final id in successfullyRemovedIds) {
        currentTableStorageData.remove(id.toString());
      }
    });

    return successfullyRemovedIds;
  }

  Future<int> count(QueryCondition queryCondition) async {
    await _ensureInitialized();
    if (_data.isEmpty) return 0;

    int matchCount = 0;
    _data.forEach((docId, docContent) {
      if (queryCondition.test(docContent)) {
        matchCount++;
      }
    });
    return matchCount;
  }

  Future<bool> containsId(DocumentId id) async {
    await _ensureInitialized();
    return _data.containsKey(id);
  }

  Future<bool> contains(QueryCondition queryCondition) async {
    await _ensureInitialized();
    if (_data.isEmpty) return false;

    for (final docContent in _data.values) {
      if (queryCondition.test(docContent)) {
        return true;
      }
    }
    return false;
  }

  Future<List<DocumentId>> upsert(
    Document document,
    QueryCondition queryCondition,
  ) async {
    await _ensureInitialized();
    List<DocumentId> affectedIds = [];

    List<Document> existingDocs = await search(queryCondition);

    if (existingDocs.isNotEmpty) {
      final List<DocumentId> idsToUpdate =
          existingDocs.map((doc) => doc['doc_id'] as DocumentId).toList();

      final ops = UpdateOperations();
      document.forEach((key, value) {
        ops.set(key, value);
      });

      if (ops.actions.isNotEmpty) {
        for (final idToUpdate in idsToUpdate) {
          if (_data.containsKey(idToUpdate)) {
            final Document docToStore = _deepCopyDocument(document);
            _data[idToUpdate] = docToStore;

            affectedIds.add(idToUpdate);
          }
        }

        if (affectedIds.isNotEmpty) {
          await _updateDbInStorage((currentTableStorageData) {
            for (final id in affectedIds) {
              currentTableStorageData[id.toString()] = _data[id]!;
            }
          });
        }
      }
    } else {
      final newId = await insert(document);
      affectedIds.add(newId);
    }
    return affectedIds;
  }
}

String actionsToString(List<UpdateAction> actions) {
  return actions
      .map(
        (a) => ({
          'path': a.pathSegments.join('.'),
          'type': a.type.toString(),
          'value': a.value,
        }),
      )
      .toList()
      .toString();
}
