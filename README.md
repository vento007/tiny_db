<!-- README header -->

<div align="center">
  <img src="doc/ascii-text-art.png" alt="Tiny DB ASCII banner" width="400"/>
</div>

```dart
import 'package:tiny_db/tiny_db.dart';

final db = TinyDb(JsonStorage('path/to/db.json'));
final table = db.table('users');

await table.insert({'name': 'John', 'age': 22});
final results = await table.search(where('name').equals('John'));

print(results); // [{name: John, age: 22}]
```

<div align="center">

<h1 align="center">📦 Tiny DB ⚡</h1>

<p align="center"><em>Ultra-lightweight, embeddable NoSQL database for Dart & Flutter</em></p>

<p align="center">
  <a href="https://pub.dev/packages/tiny_db">
    <img src="https://img.shields.io/pub/v/tiny_db.svg" alt="Pub">
  </a>
  <a href="https://github.com/vento007/tiny_db">
    <img src="https://img.shields.io/github/stars/vento007/tiny_db.svg?style=flat&logo=github&colorB=deeppink&label=stars" alt="Star on Github">
  </a>
  <a href="https://opensource.org/licenses/MIT">
    <img src="https://img.shields.io/badge/license-MIT-purple.svg" alt="License: MIT">
  </a>
  <a href="https://flutter.dev/">
    <img src="https://img.shields.io/badge/flutter-website-deepskyblue.svg" alt="Flutter Website">
  </a>
  <img src="https://img.shields.io/badge/dart-3.4.0-blue.svg" alt="Dart Version">
  <img src="https://img.shields.io/badge/flutter-3.19.0-blue.svg" alt="Flutter Version">
  <img src="https://img.shields.io/badge/platform-android%20|%20ios%20|%20web%20|%20windows%20|%20macos-blue.svg" alt="Platform Support">
  <img src="https://codecov.io/gh/vento007/tiny_db/graph/badge.svg?token=92U1VQ1FZH" alt="Codecov">
  <img src="https://img.shields.io/github/issues/vento007/tiny_db.svg" alt="Open Issues">
  <img src="https://img.shields.io/github/issues-pr/vento007/tiny_db.svg" alt="Pull Requests">
  <img src="https://img.shields.io/github/contributors/vento007/tiny_db.svg" alt="Contributors">
  <img src="https://img.shields.io/github/last-commit/vento007/tiny_db.svg" alt="Last Commit">
</p>

<hr>

</div>

# Tiny DB

## Overview

**Tiny DB** is a modern, ultra-lightweight NoSQL database for Dart and Flutter, inspired by the beloved [Python TinyDB](https://tinydb.readthedocs.io/en/latest/). With over 80% feature parity and several unique enhancements, it brings the power and flexibility of document-oriented storage to your Dart and Flutter apps—no server required!

- 🚀 **Feature-rich:** Supports advanced queries, update operations, and deep equality for robust data handling.
- 🧠 **In-memory & JSON file storage:** Choose blazing-fast ephemeral memory mode or persistent, human-readable JSON file storage—switch at any time.
- 🔄 **Familiar, expressive API:** Inspired by Python TinyDB, but fully Dart-idiomatic and enhanced for Dart and Flutter developers.
- 🎯 **Embeddable & portable:** Works everywhere Dart or Flutter runs. In-memory mode is pure Dart (no native code). JSON file storage for Flutter apps uses the standard `path_provider` plugin for safe device storage.

Whether you need a simple embedded database for prototyping, testing, or production apps, Tiny DB offers a clean, intuitive, and powerful solution.

Wondering how Tiny DB compares to SharedPreferences, Isar, Hive, or SQLite? See our [detailed comparison](doc/comparison.md).

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [API Overview](#api-overview)
- [Advanced Usage](#advanced-usage)
- [List & Update Operations](#list--update-operations)
- [Storage Backends](#storage-backends)
- [Dependency Injection & App Integration](#dependency-injection--app-integration)
- [Testing](#testing)
- [Contributing](#contributing)
- [Roadmap](#roadmap)
- [Credits](#credits)
- [License](#license)
- [Comparisons vs SharedPreferences, Isar, Hive, SQLite](#comparisons)

<br>

---

# Features

- Document-oriented, schema-free data storage
- Powerful query language (`where`, logical operators, deep matching)
- Advanced update operations: `push`, `pull`, `pop`, `addUnique` (deep equality)
- Multiple storage backends: In-memory (pure Dart), JSON file (pretty-print, dirs)
- Batch insert, upsert, and multi-table support
- Defensive copying for safe list/mutation operations
- Portable: Dart & Flutter (mobile, desktop, server, CLI)
- 200+ automated tests for reliability

<br>

---

# Installation

Add to your project:

```sh
flutter pub add tiny_db
```

Or add to your `pubspec.yaml`:

```yaml
dependencies:
  tiny_db: ^0.9
```

Then run:

```sh
flutter pub get
```

<br>

---

# Quick Start

```dart
// Always remember to properly initialize and close your database
import 'package:tiny_db/tiny_db.dart';

Future<void> main() async {
  // Create the database
  final db = TinyDb(MemoryStorage());
  
  try {
    // Use the database
    await db.insert({'name': 'John', 'age': 30});
    final results = await db.search(where('name').equals('John'));
    print(results);
  } finally {
    // Always close the database when done
    await db.close();
  }
}
```

> **Important**: Always call `db.close()` when you're done with the database to properly release resources, especially when using JsonStorage.

<br>

---

# API Overview

### Core Classes

- **TinyDb**  
  Main database entry point.  
  - `TinyDb(Storage backend)`  
  - `table(String name)` → Table  
  - `defaultTable`  
  - `close()` - **Important**: Always call this when done with the database  
  - `truncate()`, `tables()`, `all()`, `length`, `isEmpty`, `isNotEmpty`, etc.
  - **Note:** `truncate()` only affects the default table. To clear other tables, call `truncate()` on the respective Table instance, or use `dropTables()` to remove all tables.

- **Table**  
  Represents a collection of documents.  
  - `insert(Map doc)`  
  - `insertMultiple(List<Map> docs)`  
  - `upsert(Map doc, QueryCondition condition)`  
  - `update(UpdateOperations ops, QueryCondition condition)`  
  - `search(QueryCondition condition)`  
  - `get(QueryCondition condition)`  
  - `getById(DocumentId id)`  
  - `remove(QueryCondition condition)`  
  - `all()`, `length`, `truncate()`, `containsId(id)`

- **Query & QueryCondition**  
  Build expressive queries.  
  - `where('field').equals(value)`  
  - Logical operators: `.and()`, `.or()`, `.not()`  
  - List/collection queries: `.anyInList([...])`, `.allInList([...])`, etc.

- **UpdateOperations**  
  Chainable update helpers for document mutation:  
  - `.push(field, value)`  
  - `.pull(field, value)`  
  - `.pop(field)`  
  - `.addUnique(field, value)`  
  - `.set(field, value)`  
  - `.delete(field)`  
  - `.increment(field, amount)`, `.decrement(field, amount)`

- **Storage Backends**  
  - `MemoryStorage()` (pure Dart, in-memory)
  - `JsonStorage(path, {indentAmount, createDirs})` (persistent, file-based)

### Example

```dart
final db = TinyDb(MemoryStorage());
final users = db.table('users');

// Insert
await users.insert({'name': 'Alice', 'age': 30});

// Query
final result = await users.search(where('name').equals('Alice'));

// Update
await users.update(
  UpdateOperations().increment('age', 1),
  where('name').equals('Alice'),
);

// Remove
await users.remove(where('age').equals(31));
```

### Notes

- All operations are async (`Future`-based).
- Data is always deeply copied for safety.
- Table names are strings; documents are `Map<String, dynamic>`.
- Querying and update APIs are chainable and composable.
- **Resource Management**: Always call `db.close()` when done with the database to properly release resources.
<br>

---

# Advanced Usage

Below are a few advanced patterns and real-world use cases. For a comprehensive set of examples, see [More Examples](doc/examples.md).

### Multi-Table Usage

```dart
final db = TinyDb(MemoryStorage());
final users = db.table('users');
final products = db.table('products');

await users.insert({'username': 'alice', 'active': true});
await products.insert({'name': 'Widget', 'price': 9.99});
```

### Batch Insert & Upsert

```dart
await users.insertMultiple([
  {'username': 'bob', 'active': false},
  {'username': 'charlie', 'active': true},
]);

await users.upsert(
  {'username': 'alice', 'active': false},
  where('username').equals('alice'),
);
```

### Complex Queries

```dart
final results = await users.search(
  where('active').equals(true).and(where('username').anyInList(['alice', 'charlie']))
);
```

### Advanced Update Operations

```dart
await users.update(
  UpdateOperations()
    .push('tags', 'newbie')
    .addUnique('roles', 'admin')
    .increment('loginCount', 1),
  where('username').equals('alice'),
);
```

### Model Serialization

```dart
class Product {
  // ... fields ...

  factory Product.fromJson(Map<String, dynamic> json) => /* ... */;
  Map<String, dynamic> toJson() => /* ... */;
}

// Store
await products.insert(product.toJson());

// Retrieve
final docs = await products.search(where('price').greaterThan(5));
final productList = docs.map(Product.fromJson).toList();
```

---

**See [doc/examples.md](doc/examples.md) for a full list of advanced and edge-case examples.**

<br>

---

# List & Update Operations

Tiny DB provides robust list mutation and update operations, all with deep equality and defensive copying for safe, predictable behavior.

- **addUnique(field, value):** Add to a list only if the value (by deep equality) isn't already present.
- **push(field, value):** Append to a list.
- **pull(field, value):** Remove all occurrences of a value from a list (deep equality).
- **pop(field):** Remove the last element from a list.

**Deep equality** means:
- Lists: Equal if all elements are deeply equal.
- Maps: Equal if all keys and values are deeply equal.
- Primitives: Standard `==`.

**Defensive copying** ensures all list operations create a deep copy before mutation, preventing accidental reference bugs.

### Example

```dart
// Add unique value to a list
await table.update(UpdateOperations().addUnique('tags', 'flutter'), where('name').equals('Alice'));

// Remove all occurrences of a value
await table.update(UpdateOperations().pull('tags', 'old'), where('name').equals('Alice'));
```

For more details and advanced examples, see  
[doc/deep_equality_and_add_unique.md](doc/deep_equality_and_add_unique.md)


<br>

---

# Storage Backends

Tiny DB offers two storage backends to suit different needs:

### MemoryStorage

```dart
final db = TinyDb(MemoryStorage());
```

- **Pure Dart**: No native dependencies, works on all platforms
- **In-memory only**: Data is lost when the app restarts
- **Fast**: All operations happen in memory
- **Great for**: Testing, prototyping, temporary caches, and ephemeral data

### JsonStorage

```dart
final db = TinyDb(JsonStorage('path/to/db.json', 
  indentAmount: 2,  // Pretty-print with 2-space indentation
  createDirs: true, // Create parent directories if they don't exist
));
```

- **Persistent**: Data is saved to a JSON file
- **Human-readable**: JSON format is easy to inspect and edit
- **Flutter dependency**: Uses `path_provider` plugin for safe file access on mobile
- **Configuration options**:
  - `indentAmount`: Controls JSON formatting (null for compact output)
  - `createDirs`: Automatically creates parent directories

#### JSON File Structure

The JSON storage format organizes data by tables, with document IDs as keys:

```json
{
  "_default": {                     // Default table
    "1": {                         // Document ID 1
      "type": "note",
      "title": "Shopping List",
      "items": ["Milk", "Eggs", "Bread"]
    },
    "2": { ... }                   // Document ID 2
  },
  "settings": {                    // Named table "settings"
    "1": {
      "theme": "dark",
      "notifications": true,
      "preferences": {
        "fontSize": 14,
        "language": "en",
        "autoSave": true
      }
    }
  },
  "profiles": {                    // Named table "profiles"
    "1": {
      "username": "alice",
      "email": "alice@example.com",
      "tags": ["admin", "verified", "active"]
    },
    "2": { ... }                   // Another document
  }
}
```

See [json_storage_example.dart](example/json_storage_example.dart) for a complete example.

### Platform Considerations

- **Flutter apps**: Use `path_provider` to get the correct app storage directory:

  ```dart
  import 'package:path_provider/path_provider.dart';
  
  Future<void> main() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = '${appDir.path}/my_db.json';
    final db = TinyDb(JsonStorage(dbPath));
    // ...
  }
  ```

- **Pure Dart (CLI, server)**: Use direct file paths:

  ```dart
  final db = TinyDb(JsonStorage('data/my_db.json', createDirs: true));
  ```

<br>

---

# Dependency Injection & App Integration

Here are some approaches to integrate Tiny DB into your application architecture:

### Simple Global Instance

For smaller apps or prototypes, a global instance can be simple and effective:

```dart
// db_provider.dart
import 'package:tiny_db/tiny_db.dart';
import 'package:path_provider/path_provider.dart';

class DbProvider {
  static TinyDb? _instance;
  
  static Future<TinyDb> get instance async {
    if (_instance == null) {
      final appDir = await getApplicationDocumentsDirectory();
      final dbPath = '${appDir.path}/app_database.json';
      _instance = TinyDb(JsonStorage(dbPath, createDirs: true));
    }
    return _instance!;
  }
}
```

Then in your main.dart file, initialize it early:

```dart
// main.dart
import 'package:flutter/material.dart';
import 'db_provider.dart';

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the database early
  final db = await DbProvider.instance;
  
  // Now you can run your app
  runApp(MyApp(db: db));
}

class MyApp extends StatelessWidget {
  final TinyDb db;
  
  const MyApp({super.key, required this.db});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TinyDB Demo',
      home: HomeScreen(db: db),
    );
  }
}

// Usage in any screen or service:
class HomeScreen extends StatelessWidget {
  final TinyDb db;
  
  const HomeScreen({super.key, required this.db});
  
  Future<void> _addUser() async {
    final users = db.table('users');
    await users.insert({'name': 'Alice', 'joined': DateTime.now().toIso8601String()});
  }
  
  // Rest of your widget...
}
```

### Using get_it (Service Locator)

For more structured dependency injection, [get_it](https://pub.dev/packages/get_it) is a popular choice:

```dart
// service_locator.dart
import 'package:tiny_db/tiny_db.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';

final getIt = GetIt.instance;

Future<void> setupServices() async {
  // Register as a lazy singleton
  getIt.registerLazySingletonAsync<TinyDb>(() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = '${appDir.path}/app_database.json';
    return TinyDb(JsonStorage(dbPath, createDirs: true));
  });
  
  // Initialize the database
  await getIt.isReady<TinyDb>();
}

// In main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupServices();
  runApp(MyApp());
}

// Usage anywhere in your app
final db = getIt<TinyDb>();
final products = db.table('products');
```

### With Provider or Riverpod

For Flutter apps using Provider or Riverpod:

```dart
// With Provider
final dbProvider = Provider<TinyDb>((ref) {
  final db = TinyDb(MemoryStorage()); // Or JsonStorage
  ref.onDispose(() => db.close());
  return db;
});

// In a widget
final db = ref.watch(dbProvider);
```

### Closing the Database

**IMPORTANT**: Always close the database when you're done with it, regardless of how it was created. This ensures proper resource cleanup and data integrity.

```dart
// For global instances
Future<void> closeDatabase() async {
  final db = await DbProvider.instance;
  await db.close();
}

// With get_it, in your app's dispose method
getIt<TinyDb>().close();

// In a stateful widget
@override
void dispose() {
  db.close();
  super.dispose();
}

// With direct usage, use try/finally
Future<void> someFunction() async {
  final db = TinyDb(MemoryStorage());
  try {
    // Use the database
  } finally {
    await db.close(); // Always called, even if an exception occurs
  }
}
```

Failure to close the database properly may result in resource leaks or data integrity issues, especially with JsonStorage.

<br>

---

# Testing

Tiny DB includes comprehensive tests to help ensure reliability and correctness.

### Running the Tests

To run the full test suite:

```bash
flutter test
```

The package includes over 200 automated tests covering core functionality, edge cases, and defensive copying behavior.

> **Note about test warnings**: When running tests, you may see warnings like `Cannot increment field "name" in document. Value is "Alice". Not a number...`. These are expected and intentional - they're part of tests that verify the library correctly handles invalid operations (like trying to increment a string) by warning rather than crashing.

### Common Testing Patterns

When writing tests for your app that uses Tiny DB:

```dart
// 1. Always use MemoryStorage for tests
setUp(() {
  db = TinyDb(MemoryStorage());
});

// 2. Always clean up after tests
tearDown(() async {
  await db.close();
});

// 3. Test document equality with deep comparisons
test('document equality', () async {
  final doc = {'nested': {'list': [1, 2, {'key': 'value'}]}};
  final id = await db.insert(doc);
  final retrieved = await db.getById(id);
  
  // Remove doc_id for comparison
  retrieved?.remove('doc_id');
  expect(retrieved, equals(doc)); // Deep equality works automatically
});
```

<br>

---

# Contributing

Contributions to Tiny DB are welcome and appreciated! This project aims to maintain a high standard of code quality and test coverage.

### Pull Request Guidelines

When submitting a PR, please ensure:

1. **Test Coverage**: All new features or bug fixes include appropriate tests
2. **Documentation**: Update relevant documentation for any changes
3. **Code Style**: Follow the existing code style and Dart conventions
4. **Focused Changes**: Keep PRs focused on a single issue/feature

### Writing Tests

Tiny DB uses Dart's built-in testing framework. Here's a simple example of how to write a test:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tiny_db/tiny_db.dart';

void main() {
  late TinyDb db;
  
  setUp(() {
    // Use MemoryStorage for tests to avoid file system operations
    db = TinyDb(MemoryStorage());
  });
  
  tearDown(() async {
    // Always clean up after tests
    await db.close();
  });
  
  test('insert and retrieve document', () async {
    // Arrange
    final doc = {'name': 'Test', 'value': 42};
    
    // Act
    final id = await db.insert(doc);
    final result = await db.getById(id);
    
    // Assert
    expect(result?['name'], equals('Test'));
    expect(result?['value'], equals(42));
  });
  
  test('update operations work correctly', () async {
    // Arrange
    final id = await db.insert({'tags': ['a', 'b']});
    
    // Act
    await db.update(
      UpdateOperations().addUnique('tags', 'c'),
      where('doc_id').equals(id)
    );
    final result = await db.getById(id);
    
    // Assert
    expect(result?['tags'], containsAll(['a', 'b', 'c']));
  });
}
```

### Edge Case Testing

When fixing bugs or adding features, consider these edge cases:

- Empty collections/documents
- Null values and optional fields
- Deep nesting of objects and arrays
- Concurrent operations (if applicable)
- Resource cleanup (especially with JsonStorage)

Thank you for contributing to Tiny DB!
<br>

---

# Roadmap

Features under consideration for future releases:

### Plugin Support
- Index plugins for faster queries on large datasets
- Custom storage backends
- Schema validation plugins

### Performance Optimizations
- Batch operations for JsonStorage
- Streaming query results for large datasets

### Other Considerations

Some features like query caching and middleware were considered but may not be implemented due to architectural decisions favoring simplicity and resource management. The current design emphasizes proper database closing and clean resource management over persistent middleware chains.

<br>

---

# Credits

This package is heavily inspired by the outstanding [TinyDB](https://tinydb.readthedocs.io/en/latest/) project for Python, created by Markus Unterwaditzer and contributors. Many thanks to the TinyDB community for their elegant design and documentation.

# License

Tiny DB is available under the MIT License. See the [LICENSE](LICENSE) file for more information.

<br>

---

# Comparisons vs SharedPreferences, Isar, Hive, SQLite

Wondering how Tiny DB compares to other storage solutions?

We've created a detailed comparison with SharedPreferences, Isar, Hive, and SQLite to help you choose the right tool for your needs.

**[Read the full comparison here](doc/comparison.md)**

Tiny DB positions itself as the "just right" option between simple key-value stores and full-featured databases - powerful enough for real applications but simple enough to learn in minutes.


