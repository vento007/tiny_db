// Example: Fetch and query data from GitHub API
// This demonstrates tiny_db's killer feature: making any JSON instantly queryable

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tiny_db/tiny_db.dart';

Future<void> main() async {
  print('Fetching repositories from GitHub API...\n');

  // 1. Fetch JSON data from GitHub API
  final response = await http.get(
    Uri.parse('https://api.github.com/users/dart-lang/repos'),
  );

  if (response.statusCode != 200) {
    print('Failed to fetch data: ${response.statusCode}');
    return;
  }

  final repos = jsonDecode(response.body) as List<dynamic>;
  print('Fetched ${repos.length} repositories\n');

  // 2. Create database and make the JSON instantly queryable
  final db = TinyDb(MemoryStorage());

  try {
    final table = db.table('repos');
    await table.insertMultiple(repos.cast<Map<String, dynamic>>());

    print('✅ Data loaded into tiny_db!\n');
    print('${'=' * 60}\n');

    // 3. Query: Find popular Dart repositories
    print('🔍 Finding popular Dart repositories (500+ stars)...\n');
    final popularDart = await table.search(
      where('language').equals('Dart').and(
            where('stargazers_count').greaterThan(500),
          ),
    );

    print('Found ${popularDart.length} popular Dart repos:');
    for (final repo in popularDart) {
      print('  ⭐ ${repo['name']}: ${repo['stargazers_count']} stars');
      print('     ${repo['description'] ?? 'No description'}');
    }

    print('\n${'=' * 60}\n');

    // 4. Query: Recently updated repositories
    print('🔍 Finding recently updated repos (last 60 days)...\n');
    final sixtyDaysAgo = DateTime.now().subtract(Duration(days: 60));

    final recentlyUpdated = await table.search(
      where('updated_at').test((value) {
        if (value == null) return false;
        final updateDate = DateTime.parse(value as String);
        return updateDate.isAfter(sixtyDaysAgo);
      }),
    );

    print('Found ${recentlyUpdated.length} recently updated repos:');
    for (final repo in recentlyUpdated.take(5)) {
      final updated = DateTime.parse(repo['updated_at'] as String);
      final daysAgo = DateTime.now().difference(updated).inDays;
      print('  📅 ${repo['name']}: updated $daysAgo days ago');
    }

    print('\n${'=' * 60}\n');

    // 5. Query: Archived vs Active repositories
    print('📊 Repository statistics:\n');

    final archived = await table.count(where('archived').equals(true));
    final active = await table.count(where('archived').equals(false));
    final hasIssues = await table.count(where('has_issues').equals(true));
    final forked = await table.count(where('fork').equals(true));

    print('  • Archived: $archived');
    print('  • Active: $active');
    print('  • With issues enabled: $hasIssues');
    print('  • Forks: $forked');

    print('\n${'=' * 60}\n');

    // 6. Query: Find repositories by topic/language
    print('🔍 Querying by language...\n');

    final languages = <String>{};
    final allRepos = await table.all();
    for (final repo in allRepos) {
      if (repo['language'] != null) {
        languages.add(repo['language'] as String);
      }
    }

    print('Languages found: ${languages.join(', ')}\n');

    for (final lang in languages.take(3)) {
      final count = await table.count(where('language').equals(lang));
      print('  • $lang: $count repos');
    }

    print('\n${'=' * 60}\n');

    // 7. Complex query: High quality repos
    print('🔍 Finding high-quality repositories...\n');
    print('(Criteria: 100+ stars, not archived, not a fork)\n');

    final highQuality = await table.search(
      where('stargazers_count')
          .greaterThan(100)
          .and(where('archived').equals(false))
          .and(where('fork').equals(false)),
    );

    print('Found ${highQuality.length} high-quality repos:');
    for (final repo in highQuality.take(10)) {
      print('  ✨ ${repo['name']}');
      print('     ⭐ ${repo['stargazers_count']} stars, '
          '🍴 ${repo['forks_count']} forks');
    }

    print('\n${'=' * 60}\n');

    // 8. Demonstrate nested path queries
    print('🔍 Querying nested data (owner information)...\n');

    final firstRepo = await table.get(where('name').isNotNull());
    if (firstRepo != null && firstRepo['owner'] != null) {
      final owner = firstRepo['owner'] as Map<String, dynamic>;
      print('Owner info from first repo:');
      print('  • Login: ${owner['login']}');
      print('  • Type: ${owner['type']}');
      print('  • URL: ${owner['url']}');
    }

    print('\n${'=' * 60}\n');

    // 9. Show how easy it is to add/update data
    print('📝 Adding custom metadata to repos...\n');

    await table.update(
      UpdateOperations()
          .set('analyzed', true)
          .set('analysis_date', DateTime.now().toIso8601String())
          .push('tags', 'dart-ecosystem'),
      where('language').equals('Dart'),
    );

    final analyzed = await table.count(where('analyzed').equals(true));
    print('✅ Added metadata to $analyzed Dart repositories');

    print('\n${'=' * 60}');
    print('\n✨ That\'s the magic of tiny_db!');
    print('   Fetch any JSON → Instantly queryable → No schema needed\n');
  } finally {
    await db.close();
  }
}
