// Complete CRUD operations example
// Demonstrates all core database operations

import 'package:tiny_db/tiny_db.dart';

Future<void> main() async {
  print('🗄️  Complete CRUD Operations Example\n');
  print('${'=' * 60}\n');

  final db = TinyDb(MemoryStorage());

  try {
    // ========================================
    // CREATE Operations
    // ========================================
    print('📝 CREATE Operations\n');

    // Single insert
    print('1. Inserting single document...');
    final id1 = await db.insert({
      'name': 'Alice',
      'age': 30,
      'city': 'New York',
      'email': 'alice@example.com',
      'tags': ['developer', 'flutter', 'senior'],
    });
    print('   ✅ Inserted with ID: $id1\n');

    // Multiple inserts
    print('2. Batch inserting multiple documents...');
    final ids = await db.insertMultiple([
      {
        'name': 'Bob',
        'age': 25,
        'city': 'San Francisco',
        'email': 'bob@example.com',
        'tags': ['designer', 'ui-ux'],
      },
      {
        'name': 'Charlie',
        'age': 35,
        'city': 'New York',
        'email': 'charlie@example.com',
        'tags': ['developer', 'backend', 'senior'],
      },
      {
        'name': 'Diana',
        'age': 28,
        'city': 'Los Angeles',
        'email': 'diana@example.com',
        'tags': ['developer', 'mobile', 'flutter'],
      },
      {
        'name': 'Eve',
        'age': 32,
        'city': 'Seattle',
        'email': 'eve@example.com',
        'tags': ['manager', 'agile'],
      },
    ]);
    print('   ✅ Inserted ${ids.length} documents with IDs: $ids\n');

    print('${'=' * 60}\n');

    // ========================================
    // READ Operations
    // ========================================
    print('🔍 READ Operations\n');

    // Get by ID
    print('1. Get document by ID ($id1)...');
    final alice = await db.getById(id1);
    print('   📄 ${alice?['name']}, age ${alice?['age']}, from ${alice?['city']}');
    print('   📧 Email: ${alice?['email']}\n');

    // Get all documents
    print('2. Get all documents...');
    final all = await db.all();
    print('   📊 Total documents: ${all.length}\n');

    // Search with simple condition
    print('3. Search: Find users in New York...');
    final nycUsers = await db.defaultTable.search(where('city').equals('New York'));
    print('   🏙️  Found ${nycUsers.length} NYC users:');
    for (final user in nycUsers) {
      print('      • ${user['name']}');
    }
    print('');

    // Search with numeric comparison
    print('4. Search: Find users under 30...');
    final youngUsers = await db.defaultTable.search(where('age').lessThan(30));
    print('   👶 Found ${youngUsers.length} young users:');
    for (final user in youngUsers) {
      print('      • ${user['name']}, age ${user['age']}');
    }
    print('');

    // Search with AND condition
    print('5. Search: Find senior developers (age >= 30 AND has tag "developer")...');
    final seniorDevs = await db.defaultTable.search(
      where('age').greaterThanOrEquals(30).and(
            where('tags').anyInList(['developer']),
          ),
    );
    print('   👨‍💻 Found ${seniorDevs.length} senior developers:');
    for (final user in seniorDevs) {
      print('      • ${user['name']}, age ${user['age']}');
    }
    print('');

    // Get first match
    print('6. Get first: Find any user in San Francisco...');
    final sfUser = await db.defaultTable.get(where('city').equals('San Francisco'));
    print('   🌉 First SF user: ${sfUser?['name']}\n');

    // Count matches
    print('7. Count: How many users are developers?');
    final devCount = await db.defaultTable.count(
      where('tags').anyInList(['developer']),
    );
    print('   🔢 $devCount developers\n');

    // Check existence
    print('8. Contains: Any Flutter developers?');
    final hasFlutter = await db.defaultTable.contains(
      where('tags').anyInList(['flutter']),
    );
    print('   ✓ Has Flutter devs: $hasFlutter\n');

    print('${'=' * 60}\n');

    // ========================================
    // UPDATE Operations
    // ========================================
    print('✏️  UPDATE Operations\n');

    // Simple update
    print('1. Update: Increment age for NYC users...');
    final updated1 = await db.defaultTable.update(
      UpdateOperations().increment('age', 1),
      where('city').equals('New York'),
    );
    print('   ✅ Updated ${updated1.length} documents\n');

    // Verify update
    final aliceUpdated = await db.getById(id1);
    print('   Alice new age: ${aliceUpdated?['age']}\n');

    // Complex chained update
    print('2. Update: Add metadata to all developers...');
    final updated2 = await db.defaultTable.update(
      UpdateOperations()
          .set('verified', true)
          .set('lastUpdated', DateTime.now().toIso8601String())
          .push('tags', 'active')
          .increment('loginCount', 1),
      where('tags').anyInList(['developer']),
    );
    print('   ✅ Updated ${updated2.length} developers\n');

    // List operations
    print('3. Update: Add unique tag to senior users...');
    final updated3 = await db.defaultTable.update(
      UpdateOperations().addUnique('tags', 'senior-member'),
      where('age').greaterThanOrEquals(30),
    );
    print('   ✅ Updated ${updated3.length} senior users\n');

    // Nested field update
    print('4. Update: Add profile data...');
    final updated4 = await db.defaultTable.update(
      UpdateOperations()
          .set('profile.status', 'online')
          .set('profile.lastSeen', DateTime.now().toIso8601String()),
      where('name').equals('Alice'),
    );
    print('   ✅ Updated ${updated4.length} user profile\n');

    // Upsert (update or insert)
    print('5. Upsert: Update existing or insert new...');
    final upsertIds = await db.defaultTable.upsert(
      {'name': 'Frank', 'age': 40, 'city': 'Boston'},
      where('name').equals('Frank'),
    );
    print('   ✅ Upserted with ID(s): $upsertIds\n');

    print('${'=' * 60}\n');

    // ========================================
    // DELETE Operations
    // ========================================
    print('🗑️  DELETE Operations\n');

    // Delete by condition
    print('1. Delete: Remove users from Los Angeles...');
    final deleted1 = await db.defaultTable.remove(
      where('city').equals('Los Angeles'),
    );
    print('   ✅ Deleted ${deleted1.length} documents\n');

    // Delete by IDs
    print('2. Delete: Remove specific user by ID...');
    final deleted2 = await db.defaultTable.removeByIds([id1 + 1]); // Bob
    print('   ✅ Deleted ${deleted2.length} documents\n');

    // Check remaining count
    final remaining = await db.length;
    print('   📊 Remaining documents: $remaining\n');

    print('${'=' * 60}\n');

    // ========================================
    // UTILITY Operations
    // ========================================
    print('🔧 UTILITY Operations\n');

    print('1. Database stats:');
    print('   • Length: ${await db.length}');
    print('   • Is empty: ${await db.isEmpty}');
    print('   • Is not empty: ${await db.isNotEmpty}\n');

    print('2. Table operations:');
    final userTable = db.table('users');
    await userTable.insert({'name': 'Test User', 'role': 'tester'});

    final tableNames = await db.tables();
    print('   • Tables: ${tableNames.join(', ')}\n');

    print('3. Truncate default table...');
    await db.truncate();
    print('   ✅ Default table cleared');
    print('   • Length after truncate: ${await db.length}\n');

    print('4. Drop specific table...');
    final dropped = await db.dropTable('users');
    print('   ✅ Table dropped: $dropped\n');

    print('${'=' * 60}\n');

    // ========================================
    // Advanced Queries
    // ========================================
    print('🎯 ADVANCED Queries\n');

    // Re-populate for advanced queries
    await db.insertMultiple([
      {
        'name': 'User1',
        'age': 22,
        'skills': ['dart', 'flutter', 'firebase'],
        'experience': 2,
      },
      {
        'name': 'User2',
        'age': 28,
        'skills': ['dart', 'python'],
        'experience': 5,
      },
      {
        'name': 'User3',
        'age': 35,
        'skills': ['flutter', 'react'],
        'experience': 8,
      },
    ]);

    // List contains all
    print('1. Find users with both Dart AND Flutter skills...');
    final fullStack = await db.defaultTable.search(
      where('skills').allInList(['dart', 'flutter']),
    );
    print('   🎯 Found ${fullStack.length} full-stack Dart developers\n');

    // List contains any
    print('2. Find users with Dart OR Python skills...');
    final programmers = await db.defaultTable.search(
      where('skills').anyInList(['dart', 'python']),
    );
    print('   💻 Found ${programmers.length} programmers\n');

    // Complex OR logic
    print('3. Find junior OR very experienced users...');
    final extremes = await db.defaultTable.search(
      where('experience')
          .lessThanOrEquals(2)
          .or(where('experience').greaterThanOrEquals(8)),
    );
    print('   ⚡ Found ${extremes.length} users\n');

    // NOT logic
    print('4. Find users without Flutter skills...');
    final noFlutter = await db.defaultTable.search(
      where('skills').anyInList(['flutter']).not(),
    );
    print('   ❌ Found ${noFlutter.length} non-Flutter users\n');

    // Exists check
    print('5. Find users with experience field defined...');
    final hasExperience = await db.defaultTable.search(
      where('experience').exists(),
    );
    print('   ✓ Found ${hasExperience.length} users with experience data\n');

    print('${'=' * 60}\n');
    print('\n✅ Complete CRUD example finished!\n');
    print('All core database operations demonstrated successfully.\n');
  } finally {
    await db.close();
  }
}
