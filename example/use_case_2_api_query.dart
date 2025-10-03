// Use Case 2 from README: Fetch API Data & Query Instantly
// This matches the example shown in the "The Magic" section

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tiny_db/tiny_db.dart';

Future<void> main() async {
  final db = TinyDb(MemoryStorage());

  try {
    print('Fetching from GitHub API...\n');

    // Fetch JSON from any API
    final response = await http.get(
      Uri.parse('https://api.github.com/users/vento007/repos'),
    );

    if (response.statusCode != 200) {
      print('Failed to fetch: ${response.statusCode}');
      return;
    }

    final repos = jsonDecode(response.body) as List;
    print('Fetched ${repos.length} repositories\n');

    // Make it queryable
    for (final repo in repos) {
      await db.insert(repo);
    }

    // Query nested data, complex conditions - instantly
    final dartPackages = await db.defaultTable.search(
      where('language').equals('Dart').and(
            where('stargazers_count').greaterThan(3),
          ),
    );

    print('Found ${dartPackages.length} popular Dart packages!');
    for (final pkg in dartPackages) {
      print('${pkg['name']}: ${pkg['stargazers_count']} ⭐');
    }

    print('\nExpected output:');
    print('flexible_tree_layout: 6 ⭐');
    print('riverpod_mvcs_example: 5 ⭐');
    print('tiny_db: 4 ⭐');
  } finally {
    await db.close();
  }
}
