import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:tiny_db/tiny_db.dart';

void main() async {
  final tempDir = Directory(
    '${Directory.systemTemp.path}/tiny_db_example',
  );
  if (!await tempDir.exists()) {
    await tempDir.create(recursive: true);
  }

  final dbPath = '${tempDir.path}/example_db.json';
  if (kDebugMode) {
    print('Database will be stored at: $dbPath');
  }

  final dbFile = File(dbPath);
  if (await dbFile.exists()) {
    await dbFile.delete();
  }

  final db = TinyDb(JsonStorage(dbPath, indentAmount: 2, createDirs: true));

  try {
    await db.insert({
      'type': 'note',
      'title': 'Shopping List',
      'items': ['Milk', 'Eggs', 'Bread'],
    });
    await db.insert({
      'type': 'note',
      'title': 'Todo',
      'items': ['Buy groceries', 'Call mom'],
    });

    final settings = db.table('settings');
    await settings.insert({
      'theme': 'dark',
      'notifications': true,
      'preferences': {'fontSize': 14, 'language': 'en', 'autoSave': true},
    });

    final profiles = db.table('profiles');
    await profiles.insert({
      'username': 'alice',
      'email': 'alice@example.com',
      'lastLogin': DateTime.now().toIso8601String(),
      'tags': ['admin', 'verified'],
    });

    await profiles.insert({
      'username': 'bob',
      'email': 'bob@example.com',
      'lastLogin': DateTime.now().toIso8601String(),
      'tags': ['user'],
    });

    await profiles.update(
      UpdateOperations()
          .push('tags', 'active')
          .set('lastActive', DateTime.now().toIso8601String()),
      where('username').equals('alice'),
    );

    if (kDebugMode) {
      print('\nDefault table contents:');
    }
    final defaultDocs = await db.all();
    for (final doc in defaultDocs) {
      if (kDebugMode) {
        print('  - ${doc['title']} (${doc['type']})');
      }
    }

    if (kDebugMode) {
      print('\nSettings table contents:');
    }
    final settingsDocs = await settings.all();
    for (final doc in settingsDocs) {
      if (kDebugMode) {
        print(
          '  - Theme: ${doc['theme']}, Notifications: ${doc['notifications']}',
        );
      }
    }

    if (kDebugMode) {
      print('\nProfiles table contents:');
    }
    final profileDocs = await profiles.all();
    for (final doc in profileDocs) {
      if (kDebugMode) {
        print('  - ${doc['username']} (${doc['email']})');
        print('    Tags: ${doc['tags'].join(', ')}');
      }
    }

    if (kDebugMode) {
      print('\nDatabase saved to: $dbPath');
      print('You can open this file to see the JSON structure.');
    }

    final jsonContent = await File(dbPath).readAsString();
    if (kDebugMode) {
      print('\nRaw JSON content:');
      print(jsonContent);
    }
  } finally {
    await db.close();
  }
}
