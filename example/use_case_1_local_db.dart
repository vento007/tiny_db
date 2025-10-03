// Use Case 1 from README: Clean Local Database
// This matches the example shown in the "The Magic" section

import 'package:tiny_db/tiny_db.dart';

Future<void> main() async {
  final db = TinyDb(MemoryStorage());

  try {
    // Just add your data - plain maps, no schema needed
    await db.insert({'name': 'Alice', 'age': 30, 'city': 'NYC', 'role': 'developer'});
    await db.insert({'name': 'Bob', 'age': 25, 'city': 'SF', 'role': 'designer'});
    await db.insert({'name': 'Charlie', 'age': 35, 'city': 'NYC', 'role': 'developer'});

    // Query it like a real database
    final nycDevs = await db.defaultTable.search(
      where('city').equals('NYC').and(where('role').equals('developer')),
    );

    print('NYC developers: ${nycDevs.length}');  // 2

    for (final dev in nycDevs) {
      print('${dev['name']}, age ${dev['age']}');
    }
    // Alice, age 30
    // Charlie, age 35

    print('\nExpected output:');
    print('NYC developers: 2');
    print('Alice, age 30');
    print('Charlie, age 35');
  } finally {
    await db.close();
  }
}
