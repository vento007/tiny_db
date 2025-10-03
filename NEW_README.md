<div align="center">

<p>
  <img src="https://raw.githubusercontent.com/vento007/tiny_db/main/doc/ascii-text-art.png" alt="Tiny DB ASCII banner" width="400"/>
</p>
</div>

```dart
import 'package:tiny_db/tiny_db.dart';

final db = TinyDb(MemoryStorage());

await db.insert({'name': 'Alice', 'age': 30, 'city': 'NYC'});
await db.insert({'name': 'Bob', 'age': 25, 'city': 'NYC'});

final nycUsers = await db.defaultTable.search(where('city').equals('NYC'));
print(nycUsers.length); // 2
```

<div align="center">

<h1 align="center">tiny_db — instant queryable JSON database</h1>

<p align="center"><em>Turn any JSON into a queryable database - no schema, no setup, instant results</em></p>

<p align="center">
  <a href="https://pub.dev/packages/tiny_db">
    <img src="https://img.shields.io/pub/v/tiny_db.svg" alt="Pub">
  </a>
  <a href="https://opensource.org/licenses/MIT">
    <img src="https://img.shields.io/badge/license-MIT-purple.svg" alt="License: MIT">
  </a>
  <a href="https://dart.dev/">
    <img src="https://img.shields.io/badge/dart-3.4.0%2B-blue.svg" alt="Dart Version">
  </a>
  <img src="https://img.shields.io/badge/platform-android%20|%20ios%20|%20windows%20|%20macos-blue.svg" alt="Platform Support">
  <a href="https://github.com/vento007/tiny_db/issues">
    <img src="https://img.shields.io/github/issues/vento007/tiny_db.svg" alt="Open Issues">
  </a>
  <a href="https://github.com/vento007/tiny_db/pulls">
    <img src="https://img.shields.io/github/issues-pr/vento007/tiny_db.svg" alt="Pull Requests">
  </a>
  <a href="https://github.com/vento007/tiny_db/graphs/contributors">
    <img src="https://img.shields.io/github/contributors/vento007/tiny_db.svg" alt="Contributors">
  </a>
  <img src="https://img.shields.io/github/last-commit/vento007/tiny_db.svg" alt="Last Commit">
</p>

<hr>

</div>

## The Magic

### Use Case 1: Clean Local Database

```dart
import 'package:tiny_db/tiny_db.dart';

final db = TinyDb(MemoryStorage());

// Just add your data - plain maps, no schema needed
await db.insert({'name': 'Alice', 'age': 30, 'city': 'NYC', 'role': 'developer'});
await db.insert({'name': 'Bob', 'age': 25, 'city': 'SF', 'role': 'designer'});
await db.insert({'name': 'Charlie', 'age': 35, 'city': 'NYC', 'role': 'developer'});

// Query it like a real database
final nycDevs = await db.defaultTable.search(
  where('city').equals('NYC').and(where('role').equals('developer'))
);

print('NYC developers: ${nycDevs.length}');  // 2

for (final dev in nycDevs) {
  print('${dev['name']}, age ${dev['age']}');
}
// Alice, age 30
// Charlie, age 35
```

**Clean. Simple. No schema.**

> **Try it:** [example/use_case_1_local_db.dart](example/use_case_1_local_db.dart)

### Use Case 2: Fetch API Data & Query Instantly

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tiny_db/tiny_db.dart';

final db = TinyDb(MemoryStorage());

// Fetch JSON from any API
final response = await http.get(
  Uri.parse('https://api.github.com/users/vento007/repos')
);
final repos = jsonDecode(response.body) as List;

// Make it queryable
for (final repo in repos) {
  await db.insert(repo);
}

// Query nested data, complex conditions - instantly
final dartPackages = await db.defaultTable.search(
  where('language').equals('Dart').and(where('stargazers_count').greaterThan(3))
);

print('Found ${dartPackages.length} popular Dart packages!');
for (final pkg in dartPackages) {
  print('${pkg['name']}: ${pkg['stargazers_count']} ⭐');
}
// flexible_tree_layout: 6 ⭐
// riverpod_mvcs_example: 5 ⭐
// tiny_db: 4 ⭐
```

**Fetch → Insert → Query. Any JSON source becomes a database.**

> **Try it:** [example/use_case_2_api_query.dart](example/use_case_2_api_query.dart)

## What is tiny_db?

A lightweight, document-oriented NoSQL database for Dart & Flutter. Think of it as **SQLite for JSON** - powerful queries without the SQL.

- 🚀 **Instant Queries**: Any JSON → queryable in seconds (APIs, files, anywhere)
- 🎯 **No Schema**: Works with any JSON structure - dynamic and flexible
- 💪 **20+ Query Operators**: Nested paths, regex, logical operators, list operations
- 💾 **Dual Storage**: In-memory (fast) or persistent JSON files (human-readable)
- 📱 **Pure Dart**: Works on mobile, desktop, web, and server
- 🧪 **Battle-Tested**: 264+ automated tests, 80%+ feature parity with Python TinyDB

## Table of Contents

- [Real-World Use Cases](#real-world-use-cases)
- [Installation](#installation)
- [Quick Start Examples](#quick-start-examples)
  - [Remote API Caching](#1-remote-api-caching)
  - [Basic CRUD Operations](#2-basic-crud-operations)
  - [Persistent Storage](#3-persistent-storage)
- [Complete Query Guide](#complete-query-guide)
- [Complete Update Operations](#complete-update-operations)
- [Advanced Examples](#advanced-examples)
  - [Nested Path Queries](#nested-path-queries)
  - [Complex Logical Conditions](#complex-logical-conditions)
  - [List Operations](#list-operations)
  - [Regex Searches](#regex-searches)
  - [Custom Test Functions](#custom-test-functions)
- [Storage Backends](#storage-backends)
- [API Reference](#api-reference)
- [Practical Patterns](#practical-patterns)
- [Examples Index](#examples-index)
- [Comparison with Alternatives](#comparison-with-alternatives)
- [Credits](#credits)
- [License](#license)

## Real-World Use Cases

### 📱 App Data & User Settings
Store local app data with powerful queries:
```dart
final db = TinyDb(MemoryStorage());

// User preferences with nested data - just insert!
await db.insert({
  'theme': 'dark',
  'notifications': {
    'email': true,
    'push': false,
    'frequency': 'daily'
  },
  'features': ['premium', 'beta']
});

// Query nested settings
final emailEnabled = await db.defaultTable.get(
  where('notifications.email').equals(true)
);
```

### 💾 Local Data Storage
Perfect for to-do apps, note apps, local caches:
```dart
final db = TinyDb(JsonStorage('tasks.json'));

// Store tasks - simple insert
await db.insert({
  'title': 'Finish report',
  'priority': 'high',
  'tags': ['work', 'urgent'],
  'dueDate': '2025-10-15'
});

// Find high-priority tasks
final urgentTasks = await db.defaultTable.search(
  where('priority').equals('high')
    .and(where('tags').anyInList(['urgent']))
);
```

### 🎮 Game State & Progress
Track player data, inventory, achievements:
```dart
final db = TinyDb(JsonStorage('game_save.json'));

// Player inventory - just add it
await db.insert({
  'itemId': 'sword_001',
  'name': 'Legendary Sword',
  'stats': {'damage': 150, 'durability': 100},
  'equipped': true
});

// Find all equipped legendary items
final equipped = await db.defaultTable.search(
  where('equipped').equals(true)
    .and(where('name').search('Legendary'))
);
```

### 🧪 Testing & Development
Mock database behavior with fixtures:
```dart
// Load test data
final db = TinyDb(MemoryStorage());
await db.insertMultiple([
  {'role': 'admin', 'name': 'Alice'},
  {'role': 'user', 'name': 'Bob'}
]);

// Test your business logic
final admins = await db.search(where('role').equals('admin'));
expect(admins, hasLength(1));
```

### 🌐 Bonus: API Data (Optional!)
And yes, you can also fetch and query remote JSON:
```dart
// Fetch from any API
final response = await http.get(Uri.parse('https://api.example.com/data'));
final data = jsonDecode(response.body) as List;

// Make it queryable
for (final item in data) {
  await db.insert(item);
}

// Query API data offline
final filtered = await db.search(where('category').equals('electronics'));
```

## Installation

Add to your project:

```sh
flutter pub add tiny_db
```

Or add to `pubspec.yaml`:

```yaml
dependencies:
  tiny_db: ^0.9.1
```

Then run:

```sh
flutter pub get
```

## Quick Start Examples

### 1. Remote API Caching

Fetch and query data from any HTTP API:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tiny_db/tiny_db.dart';

Future<void> main() async {
  // Fetch repos from GitHub API
  final response = await http.get(
    Uri.parse('https://api.github.com/users/dart-lang/repos')
  );
  final repos = jsonDecode(response.body) as List<dynamic>;

  // Create database and store repos
  final db = TinyDb(MemoryStorage());
  try {
    final table = db.table('repos');
    await table.insertMultiple(
      repos.cast<Map<String, dynamic>>()
    );

    // Query: Find popular Dart repositories
    final popular = await table.search(
      where('language').equals('Dart')
        .and(where('stargazers_count').greaterThan(500))
    );

    print('Found ${popular.length} popular Dart repos:');
    for (final repo in popular) {
      print('  • ${repo['name']}: ${repo['stargazers_count']} ⭐');
    }

    // Query: Find recently updated repos
    final recentDate = DateTime.now().subtract(Duration(days: 30));
    final recent = await table.search(
      where('updated_at').test(
        (value) => DateTime.parse(value).isAfter(recentDate)
      )
    );

    print('\nRecently updated: ${recent.length} repos');

    // Query: Archived vs active
    final archived = await table.count(where('archived').equals(true));
    final active = await table.count(where('archived').equals(false));
    print('\nArchived: $archived, Active: $active');

  } finally {
    await db.close();
  }
}
```

See [example/remote_api_example.dart](example/remote_api_example.dart) for the complete example.

### 2. Basic CRUD Operations

Core database operations - Create, Read, Update, Delete:

```dart
import 'package:tiny_db/tiny_db.dart';

Future<void> main() async {
  final db = TinyDb(MemoryStorage());

  try {
    // CREATE: Insert documents
    final id1 = await db.insert({'name': 'Alice', 'age': 30, 'city': 'NYC'});
    final id2 = await db.insert({'name': 'Bob', 'age': 25, 'city': 'SF'});

    // Batch insert
    final ids = await db.insertMultiple([
      {'name': 'Charlie', 'age': 35, 'city': 'NYC'},
      {'name': 'Diana', 'age': 28, 'city': 'LA'}
    ]);

    // READ: Query documents
    final nycUsers = await db.search(where('city').equals('NYC'));
    print('NYC users: ${nycUsers.length}'); // 2

    final youngUsers = await db.search(where('age').lessThan(30));
    print('Young users: ${youngUsers.length}'); // 2

    // Get by ID
    final alice = await db.getById(id1);
    print('Alice: ${alice?['name']}, ${alice?['age']}');

    // Get first match
    final firstNyc = await db.defaultTable.get(where('city').equals('NYC'));
    print('First NYC user: ${firstNyc?['name']}');

    // Count matches
    final count = await db.defaultTable.count(where('age').greaterThan(27));
    print('Users over 27: $count'); // 3

    // UPDATE: Modify documents
    await db.defaultTable.update(
      UpdateOperations().increment('age', 1),
      where('city').equals('NYC')
    );

    final aliceUpdated = await db.getById(id1);
    print('Alice new age: ${aliceUpdated?['age']}'); // 31

    // Complex update
    await db.defaultTable.update(
      UpdateOperations()
        .set('verified', true)
        .push('tags', 'premium'),
      where('age').greaterThanOrEquals(30)
    );

    // DELETE: Remove documents
    await db.defaultTable.remove(where('city').equals('LA'));

    print('Remaining users: ${await db.length}'); // 3

    // Get all documents
    final all = await db.all();
    for (final doc in all) {
      print('${doc['name']} (${doc['age']}) from ${doc['city']}');
    }

  } finally {
    await db.close();
  }
}
```

### 3. Persistent Storage

Save data to a JSON file that persists across app restarts:

```dart
import 'dart:io';
import 'package:tiny_db/tiny_db.dart';
import 'package:path_provider/path_provider.dart'; // For Flutter apps

Future<void> main() async {
  // For Flutter: Use app documents directory
  // final appDir = await getApplicationDocumentsDirectory();
  // final dbPath = '${appDir.path}/my_app.json';

  // For pure Dart: Use any path
  final dbPath = 'data/my_database.json';

  final db = TinyDb(
    JsonStorage(
      dbPath,
      createDirs: true,    // Auto-create parent directories
      indentAmount: 2,     // Pretty-print with 2-space indent
    )
  );

  try {
    // Insert data - automatically saved to file
    await db.insert({
      'type': 'note',
      'title': 'Shopping List',
      'items': ['Milk', 'Eggs', 'Bread'],
      'created': DateTime.now().toIso8601String()
    });

    // Use named tables for organization
    final settings = db.table('settings');
    await settings.insert({
      'theme': 'dark',
      'notifications': true,
      'language': 'en'
    });

    final users = db.table('users');
    await users.insert({
      'username': 'alice',
      'email': 'alice@example.com',
      'preferences': {
        'fontSize': 14,
        'colorScheme': 'blue'
      }
    });

    // Query persisted data
    final notes = await db.search(where('type').equals('note'));
    print('Found ${notes.length} notes');

    // The JSON file is human-readable!
    print('\nJSON file contents:');
    print(File(dbPath).readAsStringSync());

    // List all tables
    final tables = await db.tables();
    print('\nTables: ${tables.join(', ')}');

  } finally {
    await db.close(); // Important: Save and release file locks
  }
}
```

**JSON file structure** (`my_database.json`):
```json
{
  "_default": {
    "1": {
      "type": "note",
      "title": "Shopping List",
      "items": ["Milk", "Eggs", "Bread"],
      "created": "2025-10-03T10:30:00.000"
    }
  },
  "settings": {
    "1": {
      "theme": "dark",
      "notifications": true,
      "language": "en"
    }
  },
  "users": {
    "1": {
      "username": "alice",
      "email": "alice@example.com",
      "preferences": {
        "fontSize": 14,
        "colorScheme": "blue"
      }
    }
  }
}
```

## Complete Query Guide

All 20+ query methods with examples:

| Method | Example | Description |
|--------|---------|-------------|
| **Equality** | | |
| `equals(value)` | `where('age').equals(30)` | Exact match |
| `notEquals(value)` | `where('status').notEquals('deleted')` | Not equal to value |
| **Existence** | | |
| `exists()` | `where('email').exists()` | Field exists (even if null) |
| `notExists()` | `where('optionalField').notExists()` | Field doesn't exist |
| **Null Checks** | | |
| `isNull()` | `where('deletedAt').isNull()` | Field is null |
| `isNotNull()` | `where('email').isNotNull()` | Field is not null |
| **Numeric Comparisons** | | |
| `greaterThan(n)` | `where('price').greaterThan(100)` | Greater than number |
| `lessThan(n)` | `where('age').lessThan(18)` | Less than number |
| `greaterThanOrEquals(n)` | `where('score').greaterThanOrEquals(90)` | >= number |
| `lessThanOrEquals(n)` | `where('quantity').lessThanOrEquals(10)` | <= number |
| **String/Regex** | | |
| `matches(regex)` | `where('email').matches(r'.*@gmail\.com')` | Full regex match |
| `search(regex)` | `where('name').search(r'john', caseSensitive: false)` | Partial match (contains) |
| **Custom Tests** | | |
| `test(fn)` | `where('date').test((v) => DateTime.parse(v).isAfter(...))` | Custom function test |
| **List Operations** | | |
| `anyInList([values])` | `where('tags').anyInList(['urgent', 'important'])` | List contains any of these |
| `allInList([values])` | `where('tags').allInList(['reviewed', 'approved'])` | List contains all of these |
| `anyElementSatisfies(cond)` | `where('scores').anyElementSatisfies(where('value').greaterThan(90))` | Any element matches |
| `allElementsSatisfy(cond)` | `where('items').allElementsSatisfy(where('status').equals('ready'))` | All elements match |
| **Logical Operators** | | |
| `.and(condition)` | `where('age').greaterThan(18).and(where('verified').equals(true))` | AND logic |
| `.or(condition)` | `where('role').equals('admin').or(where('role').equals('moderator'))` | OR logic |
| `.not()` | `where('status').equals('active').not()` | NOT logic |

### Nested Path Examples

Access nested fields using dot notation:

```dart
// Document structure
await db.insert({
  'user': {
    'profile': {
      'name': 'Alice',
      'address': {
        'city': 'NYC',
        'zip': '10001'
      }
    },
    'settings': {
      'notifications': true
    }
  }
});

// Query nested fields
final nycUsers = await db.search(
  where('user.profile.address.city').equals('NYC')
);

final notificationsOn = await db.search(
  where('user.settings.notifications').equals(true)
);
```

## Complete Update Operations

All 8 update operations with examples:

| Operation | Example | Description |
|-----------|---------|-------------|
| **Field Operations** | | |
| `set(path, value)` | `.set('status', 'active')` | Set field value |
| `delete(path)` | `.delete('temporaryField')` | Remove field |
| **Numeric Operations** | | |
| `increment(path, n)` | `.increment('views', 1)` | Increment number field |
| `decrement(path, n)` | `.decrement('stock', 5)` | Decrement number field |
| **List Operations** | | |
| `push(path, value)` | `.push('tags', 'new-tag')` | Append to list |
| `pull(path, value)` | `.pull('tags', 'old-tag')` | Remove all instances (deep equality) |
| `pop(path)` | `.pop('items')` | Remove last element |
| `addUnique(path, value)` | `.addUnique('categories', 'premium')` | Add if not exists (deep equality) |

### Chaining Operations

Combine multiple operations in one update:

```dart
await db.defaultTable.update(
  UpdateOperations()
    .set('lastModified', DateTime.now().toIso8601String())
    .increment('viewCount', 1)
    .push('history', {'action': 'viewed', 'timestamp': DateTime.now()})
    .addUnique('tags', 'popular'),
  where('id').equals(123)
);
```

### Nested Path Updates

Modify nested fields using dot notation:

```dart
await db.defaultTable.update(
  UpdateOperations()
    .set('user.profile.name', 'Alice Smith')
    .increment('user.stats.loginCount', 1)
    .push('user.notifications', {
      'type': 'info',
      'message': 'Welcome back!'
    }),
  where('userId').equals(42)
);
```

## Advanced Examples

### Nested Path Queries

```dart
// Complex nested structure
await db.insert({
  'order': {
    'id': 'ORD-001',
    'customer': {
      'name': 'Alice',
      'address': {
        'city': 'New York',
        'state': 'NY',
        'zip': '10001'
      }
    },
    'items': [
      {'product': 'Widget', 'price': 29.99, 'quantity': 2},
      {'product': 'Gadget', 'price': 49.99, 'quantity': 1}
    ],
    'total': 109.97
  }
});

// Query nested customer data
final nyOrders = await db.search(
  where('order.customer.address.state').equals('NY')
);

// Query by total amount
final largeOrders = await db.search(
  where('order.total').greaterThan(100)
);
```

### Complex Logical Conditions

```dart
// Multiple AND conditions
final results = await db.search(
  where('age').greaterThanOrEquals(18)
    .and(where('age').lessThan(65))
    .and(where('verified').equals(true))
    .and(where('status').equals('active'))
);

// OR with nested AND
final vipUsers = await db.search(
  where('role').equals('admin')
    .or(
      where('subscriptionLevel').equals('premium')
        .and(where('yearsActive').greaterThan(5))
    )
);

// NOT logic
final incompleteProfiles = await db.search(
  where('profileComplete').equals(true).not()
);
```

### List Operations

```dart
// Insert documents with lists
await db.insertMultiple([
  {'name': 'Alice', 'tags': ['developer', 'flutter', 'senior']},
  {'name': 'Bob', 'tags': ['designer', 'ui-ux']},
  {'name': 'Charlie', 'tags': ['developer', 'backend', 'junior']}
]);

// Find documents where list contains ANY of these values
final devOrDesigner = await db.search(
  where('tags').anyInList(['developer', 'designer'])
);
print('Developers or designers: ${devOrDesigner.length}'); // 3

// Find documents where list contains ALL of these values
final seniorFlutter = await db.search(
  where('tags').allInList(['flutter', 'senior'])
);
print('Senior Flutter devs: ${seniorFlutter.length}'); // 1

// Complex list element matching
await db.insert({
  'project': 'Website',
  'tasks': [
    {'name': 'Design', 'status': 'done', 'hours': 20},
    {'name': 'Development', 'status': 'in-progress', 'hours': 40},
    {'name': 'Testing', 'status': 'pending', 'hours': 10}
  ]
});

// Find projects with any completed tasks
final hasCompletedTasks = await db.search(
  where('tasks').anyElementSatisfies(
    where('status').equals('done')
  )
);

// Find projects where all tasks are completed
final fullyCompleted = await db.search(
  where('tasks').allElementsSatisfy(
    where('status').equals('done')
  )
);
```

### Regex Searches

```dart
await db.insertMultiple([
  {'email': 'alice@gmail.com', 'name': 'Alice'},
  {'email': 'bob@company.com', 'name': 'Bob'},
  {'email': 'charlie@gmail.com', 'name': 'Charlie'}
]);

// Full regex match (entire string must match)
final gmailUsers = await db.search(
  where('email').matches(r'^[a-z]+@gmail\.com$')
);
print('Gmail users: ${gmailUsers.length}'); // 2

// Partial match (search/contains)
final hasGmail = await db.search(
  where('email').search(r'gmail', caseSensitive: false)
);

// Case-insensitive name search
final nameContainsBob = await db.search(
  where('name').search(r'bob', caseSensitive: false)
);
```

### Custom Test Functions

```dart
// Date comparisons
final recentDocs = await db.search(
  where('createdAt').test((value) {
    final date = DateTime.parse(value as String);
    final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
    return date.isAfter(thirtyDaysAgo);
  })
);

// Complex validation
final validEmails = await db.search(
  where('email').test((value) {
    if (value is! String) return false;
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value);
  })
);

// Numeric ranges with custom logic
final midRange = await db.search(
  where('score').test((value) {
    if (value is! num) return false;
    return value >= 40 && value <= 60;
  })
);
```

## Storage Backends

### Comparison: MemoryStorage vs JsonStorage

| Feature | MemoryStorage | JsonStorage |
|---------|---------------|-------------|
| **Persistence** | Lost on app restart | Saved to disk |
| **Speed** | Fastest | Fast (with mutex protection) |
| **File I/O** | None | Yes |
| **Dependencies** | Pure Dart | Uses `dart:io` |
| **Best For** | Testing, caching, temp data | Production apps, settings |
| **Human Readable** | No (in-memory) | Yes (JSON format) |
| **Multi-process** | No | No (file-based) |

### MemoryStorage

```dart
final db = TinyDb(MemoryStorage());

// Fast, ephemeral storage
// Perfect for:
// - Unit tests
// - Temporary caching
// - Development/prototyping
// - Session data

await db.close(); // No file cleanup needed
```

### JsonStorage

```dart
final db = TinyDb(
  JsonStorage(
    'path/to/database.json',
    createDirs: true,    // Create parent directories automatically
    indentAmount: 2,     // Pretty-print (null for compact)
  )
);

// Persistent storage
// Perfect for:
// - User data
// - App settings
// - Offline-first apps
// - Human-readable data inspection

await db.close(); // Important: Ensures data is flushed to disk
```

### Platform-Specific Paths

**Flutter (Mobile/Desktop):**
```dart
import 'package:path_provider/path_provider.dart';

Future<TinyDb> createDatabase() async {
  final appDir = await getApplicationDocumentsDirectory();
  return TinyDb(
    JsonStorage('${appDir.path}/app_data.json', createDirs: true)
  );
}
```

**Pure Dart (CLI/Server):**
```dart
// Relative path
final db = TinyDb(JsonStorage('data/db.json', createDirs: true));

// Absolute path
final db = TinyDb(JsonStorage('/var/app/database.json'));

// Temp directory
import 'dart:io';
final tempDb = TinyDb(
  JsonStorage('${Directory.systemTemp.path}/temp_db.json')
);
```

### Performance Characteristics

- **Insert**: O(1) - direct ID assignment
- **Query (simple)**: O(n) - full table scan
- **Query (by ID)**: O(1) - direct lookup
- **Update**: O(n) - scan + modify matched docs
- **Delete**: O(n) - scan + remove matched docs
- **Storage**: All operations protected by mutex for thread safety (JsonStorage)

For large datasets (10k+ documents), consider:
- Indexing strategies (future plugin support)
- Filtering before insertion
- Batch operations where possible
- MemoryStorage for read-heavy workloads

## API Reference

### TinyDb Class

```dart
final db = TinyDb(storage);
```

**Methods:**
- `table(String name)` → `Table` - Get or create named table
- `defaultTable` → `Table` - Get default table (`_default`)
- `tables()` → `Future<Set<String>>` - List all table names
- `dropTable(String name)` → `Future<bool>` - Delete a table
- `dropTables()` → `Future<void>` - Delete all tables
- `close()` → `Future<void>` - Close database and release resources

**Default table proxy methods** (operate on `_default` table):
- `insert(doc)`, `insertMultiple(docs)`, `all()`, `getById(id)`, `length`, `isEmpty`, `isNotEmpty`, `truncate()`

### Table Class

**CRUD Operations:**
- `insert(Map<String, dynamic> doc)` → `Future<int>` - Insert document, returns ID
- `insertMultiple(List<Map<String, dynamic>> docs)` → `Future<List<int>>` - Batch insert
- `search(QueryCondition condition)` → `Future<List<Map<String, dynamic>>>` - Find all matches
- `get(QueryCondition condition)` → `Future<Map<String, dynamic>?>` - Find first match
- `getById(int id)` → `Future<Map<String, dynamic>?>` - Get by ID
- `update(UpdateOperations ops, QueryCondition condition)` → `Future<List<int>>` - Update matches, returns IDs
- `upsert(Map doc, QueryCondition condition)` → `Future<List<int>>` - Update or insert
- `remove(QueryCondition condition)` → `Future<List<int>>` - Delete matches, returns IDs
- `removeByIds(List<int> ids)` → `Future<List<int>>` - Delete by IDs

**Utility Methods:**
- `all()` → `Future<List<Map>>` - Get all documents
- `length` → `Future<int>` - Count documents
- `isEmpty` / `isNotEmpty` → `Future<bool>` - Check if empty
- `truncate()` → `Future<void>` - Clear all documents
- `count(QueryCondition condition)` → `Future<int>` - Count matches
- `contains(QueryCondition condition)` → `Future<bool>` - Check if any match exists
- `containsId(int id)` → `Future<bool>` - Check if ID exists

### Query Class

**Factory:**
- `where(String fieldPath)` → `Query` - Create query for field path (supports dot notation)

**Comparison Methods:**
- `equals(value)` - Exact match
- `notEquals(value)` - Not equal
- `greaterThan(num)` - Greater than (numeric)
- `lessThan(num)` - Less than (numeric)
- `greaterThanOrEquals(num)` - >= (numeric)
- `lessThanOrEquals(num)` - <= (numeric)

**Existence & Null:**
- `exists()` - Field exists
- `notExists()` - Field doesn't exist
- `isNull()` - Field is null
- `isNotNull()` - Field is not null

**String/Regex:**
- `matches(String pattern, {bool caseSensitive = true})` - Full regex match
- `search(String pattern, {bool caseSensitive = true})` - Partial match

**List Operations:**
- `anyInList(List values)` - List contains any value
- `allInList(List values)` - List contains all values
- `anyElementSatisfies(QueryCondition)` - Any element matches
- `allElementsSatisfy(QueryCondition)` - All elements match

**Custom:**
- `test(bool Function(dynamic) fn)` - Custom test function

**Logical Operators:**
- `.and(QueryCondition)` - Logical AND
- `.or(QueryCondition)` - Logical OR
- `.not()` - Logical NOT

### UpdateOperations Class

**Field Operations:**
- `set(String path, dynamic value)` - Set field value
- `delete(String path)` - Remove field

**Numeric:**
- `increment(String path, num amount)` - Increment number
- `decrement(String path, num amount)` - Decrement number

**List Operations:**
- `push(String path, dynamic value)` - Append to list
- `pull(String path, dynamic value)` - Remove all instances (deep equality)
- `pop(String path)` - Remove last element
- `addUnique(String path, dynamic value)` - Add if not exists (deep equality)

All operations support **nested paths** via dot notation and are **chainable**.

## Practical Patterns

### Model Serialization

```dart
class User {
  final String name;
  final int age;
  final String email;

  User({required this.name, required this.age, required this.email});

  // Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'name': name,
    'age': age,
    'email': email,
  };

  // Create from JSON
  factory User.fromJson(Map<String, dynamic> json) => User(
    name: json['name'] as String,
    age: json['age'] as int,
    email: json['email'] as String,
  );
}

// Usage
final user = User(name: 'Alice', age: 30, email: 'alice@example.com');

// Store
final id = await db.table('users').insert(user.toJson());

// Retrieve
final docs = await db.table('users').search(where('name').equals('Alice'));
final retrievedUser = User.fromJson(docs.first);
```

### Dependency Injection with get_it

```dart
import 'package:get_it/get_it.dart';
import 'package:tiny_db/tiny_db.dart';
import 'package:path_provider/path_provider.dart';

final getIt = GetIt.instance;

Future<void> setupDatabase() async {
  getIt.registerLazySingletonAsync<TinyDb>(() async {
    final appDir = await getApplicationDocumentsDirectory();
    return TinyDb(
      JsonStorage('${appDir.path}/app_db.json', createDirs: true)
    );
  });

  await getIt.isReady<TinyDb>();
}

// In main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDatabase();
  runApp(MyApp());
}

// Use anywhere
final db = getIt<TinyDb>();
final users = db.table('users');
```

### Error Handling

```dart
try {
  final db = TinyDb(JsonStorage('data/db.json', createDirs: true));

  try {
    await db.insert({'data': 'value'});
  } on StorageException catch (e) {
    print('Storage error: ${e.message}');
  } on CorruptStorageException catch (e) {
    print('Corrupt database: ${e.message}');
    // Handle data recovery
  }

} finally {
  await db.close();
}
```

### Resource Cleanup

```dart
// Always close databases
Future<void> myFunction() async {
  final db = TinyDb(JsonStorage('data.json'));
  try {
    // Use database
    await db.insert({'key': 'value'});
  } finally {
    await db.close(); // Ensures data is saved and resources released
  }
}

// In Flutter widgets
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late TinyDb db;

  @override
  void initState() {
    super.initState();
    db = TinyDb(MemoryStorage());
  }

  @override
  void dispose() {
    db.close();
    super.dispose();
  }
}
```

### Testing Patterns

```dart
import 'package:test/test.dart';
import 'package:tiny_db/tiny_db.dart';

void main() {
  late TinyDb db;

  setUp(() {
    // Use MemoryStorage for tests - fast and isolated
    db = TinyDb(MemoryStorage());
  });

  tearDown(() async {
    // Clean up after each test
    await db.close();
  });

  test('user creation and retrieval', () async {
    final id = await db.insert({'name': 'Test User', 'role': 'admin'});

    final user = await db.getById(id);
    expect(user?['name'], 'Test User');
    expect(user?['role'], 'admin');
  });

  test('query with complex conditions', () async {
    await db.insertMultiple([
      {'name': 'Alice', 'age': 25, 'active': true},
      {'name': 'Bob', 'age': 35, 'active': false},
      {'name': 'Charlie', 'age': 30, 'active': true}
    ]);

    final activeUsers = await db.search(
      where('active').equals(true).and(where('age').greaterThan(26))
    );

    expect(activeUsers.length, 1);
    expect(activeUsers.first['name'], 'Charlie');
  });
}
```

## Examples Index

Complete working examples in the [`example/`](example/) directory:

**Quick Start Examples:**
- **[readme_intro_example.dart](example/readme_intro_example.dart)** - The opening example from top of README
- **[use_case_1_local_db.dart](example/use_case_1_local_db.dart)** - Clean local database usage
- **[use_case_2_api_query.dart](example/use_case_2_api_query.dart)** - Fetch & query API data

**Comprehensive Examples:**
- **[complete_crud_example.dart](example/complete_crud_example.dart)** - All CRUD operations demo
- **[model_serialization_example.dart](example/model_serialization_example.dart)** - Using typed models (with [products_model.dart](example/products_model.dart))
- **[remote_api_example.dart](example/remote_api_example.dart)** - Fetch and query GitHub repos
- **[weather_api_example.dart](example/weather_api_example.dart)** - Weather API caching pattern
- **[json_storage_example.dart](example/json_storage_example.dart)** - Persistent JSON storage
- **[flutter_example/](example/flutter_example/)** - Complete Flutter app

Run any example:
```bash
dart run example/use_case_1_local_db.dart
dart run example/model_serialization_example.dart
dart run example/complete_crud_example.dart
```

## Comparison with Alternatives

| Feature | tiny_db | SharedPreferences | Hive | SQLite | Isar |
|---------|---------|-------------------|------|--------|------|
| **Setup Complexity** | None | None | Minimal | Moderate | Moderate |
| **Schema Required** | No | No | Optional | Yes | Yes |
| **Query Capability** | 20+ operators | Key-value only | Limited | SQL (full) | Advanced |
| **JSON Support** | Native | Manual | Manual | Manual | Manual |
| **Nested Queries** | Yes | No | No | Joins required | Yes |
| **Human Readable** | Yes (JSON files) | Yes (XML/JSON) | No (binary) | No (binary) | No (binary) |
| **Best For** | JSON APIs, prototyping, flexible data | Simple settings | Structured data | Complex relations | Performance-critical |
| **Learning Curve** | Minutes | Minutes | Hours | Days | Days |
| **File Size** | Small | Small | Small | Medium | Large |

**When to use tiny_db:**
- ✅ Working with API JSON data
- ✅ Rapid prototyping with real data
- ✅ Flexible/evolving data structures
- ✅ Human-readable storage preferred
- ✅ Simple to moderate query complexity
- ✅ < 10,000 documents per table

**When to use alternatives:**
- ❌ Simple key-value storage → SharedPreferences
- ❌ Millions of records → Isar or SQLite
- ❌ Complex relationships → SQLite
- ❌ Maximum performance → Hive or Isar

## Credits

Inspired by the excellent [TinyDB](https://tinydb.readthedocs.io/) for Python by Markus Unterwaditzer and contributors. tiny_db brings the same philosophy of simplicity and power to the Dart ecosystem with 80%+ feature parity and several enhancements.

## License

MIT License - see [LICENSE](LICENSE) file for details.

---

<div align="center">

**[Documentation](https://github.com/vento007/tiny_db)** • **[Issues](https://github.com/vento007/tiny_db/issues)** • **[Contributing](https://github.com/vento007/tiny_db/blob/main/CONTRIBUTING.md)**

Made with ❤️ for the Dart & Flutter community

</div>
