import 'package:flutter/foundation.dart';
import 'package:tiny_db/tiny_db.dart';

Future<void> runBasicExample(TinyDb db) async {
  await db.truncate();

  await db.insert({
    'id': 1,
    'name': 'John Doe',
    'email': 'john@example.com',
    'age': 30,
    'isActive': true,
    'tags': ['developer', 'flutter'],
  });

  await db.insert({
    'id': 2,
    'name': 'Jane Smith',
    'email': 'jane@example.com',
    'age': 25,
    'isActive': true,
    'tags': ['designer', 'ui/ux'],
  });

  await db.insert({
    'id': 3,
    'name': 'Bob Johnson',
    'email': 'bob@example.com',
    'age': 35,
    'isActive': false,
    'tags': ['manager', 'product'],
  });

  final activeUsers = await db.defaultTable.search(
    where('isActive').equals(true),
  );
  if (kDebugMode) {
    print('Active users: ${activeUsers.length}');
  }

  final youngActiveUsers = await db.defaultTable.search(
    where('isActive').equals(true).and(where('age').lessThan(30)),
  );
  if (kDebugMode) {
    print('Young active users: ${youngActiveUsers.length}');
  }

  final updateOps = UpdateOperations().set('age', 31).set('loginCount', 1);

  await db.defaultTable.update(updateOps, where('id').equals(1));

  final john = await db.defaultTable.getById(1);
  if (kDebugMode) {
    print('Updated John: $john');
  }

  final listOps = UpdateOperations().push('tags', 'dart');

  await db.defaultTable.update(listOps, where('id').equals(1));

  final johnUpdated = await db.defaultTable.getById(1);
  if (kDebugMode) {
    print('John with new tag: $johnUpdated');
  }
}
