// The opening code example from the top of the README

import 'package:tiny_db/tiny_db.dart';

Future<void> main() async {
  final db = TinyDb(MemoryStorage());

  await db.insert({'name': 'Alice', 'age': 30, 'city': 'NYC'});
  await db.insert({'name': 'Bob', 'age': 25, 'city': 'NYC'});

  final nycUsers = await db.defaultTable.search(where('city').equals('NYC'));
  print(nycUsers.length); // 2

  await db.close();
}
