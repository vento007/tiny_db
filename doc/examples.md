# tiny_db: More Examples

This document contains a wide variety of advanced, edge-case, and real-world usage examples for tiny_db.

## Table of Contents
- [Multi-Table Usage](#multi-table-usage)
- [Batch Insert & Upsert](#batch-insert--upsert)
- [Complex Queries](#complex-queries)
- [Advanced Update Operations](#advanced-update-operations)
- [Model Serialization](#model-serialization)
- [Custom Document IDs](#custom-document-ids)
- [Working with Dates](#working-with-dates)
- [Error Handling](#error-handling)
- [Migration & Compatibility](#migration--compatibility)

---

## Multi-Table Usage
```dart
final db = TinyDb(MemoryStorage());
final users = db.table('users');
final products = db.table('products');
await users.insert({'username': 'alice', 'active': true});
await products.insert({'name': 'Widget', 'price': 9.99});
```

## Batch Insert & Upsert
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

## Complex Queries
```dart
final results = await users.search(
  where('active').equals(true).and(where('username').anyInList(['alice', 'charlie']))
);
```

## Advanced Update Operations
```dart
await users.update(
  UpdateOperations()
    .push('tags', 'newbie')
    .addUnique('roles', 'admin')
    .increment('loginCount', 1),
  where('username').equals('alice'),
);
```

## Model Serialization
```dart
class Product {
  // ... fields ...
  factory Product.fromJson(Map<String, dynamic> json) => /* ... */;
  Map<String, dynamic> toJson() => /* ... */;
}
await products.insert(product.toJson());
final docs = await products.search(where('price').greaterThan(5));
final productList = docs.map(Product.fromJson).toList();
```

## Custom Document IDs
```dart
final customId = 123;
await users.insert({'doc_id': customId, 'username': 'special'});
```

## Working with Dates
```dart
final now = DateTime.now();
await users.insert({'created': now.toIso8601String()});
final docs = await users.search(where('created').greaterThan('2024-01-01T00:00:00Z'));
```

## Error Handling
```dart
try {
  await db.insert({'bad': 'data'});
} catch (e) {
  print('Error: $e');
}
```

## Migration & Compatibility
- See README for migration tips from Python TinyDB or other NoSQL solutions.

---

Have a cool example? PRs welcome!
