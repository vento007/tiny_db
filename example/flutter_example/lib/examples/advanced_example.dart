import 'package:flutter/foundation.dart';
import 'package:tiny_db/tiny_db.dart';

Future<void> runAdvancedExample(TinyDb db) async {
  await db.dropTables();

  final usersTable = db.table('users');
  final postsTable = db.table('posts');
  final commentsTable = db.table('comments');

  await usersTable.insertMultiple([
    {
      'id': 1,
      'username': 'johndoe',
      'profile': {
        'fullName': 'John Doe',
        'email': 'john@example.com',
        'age': 30,
      },
      'preferences': {'theme': 'dark', 'notifications': true},
      'roles': ['user', 'admin'],
      'loginCount': 42,
      'lastLogin': DateTime.now().toIso8601String(),
    },
    {
      'id': 2,
      'username': 'janesmith',
      'profile': {
        'fullName': 'Jane Smith',
        'email': 'jane@example.com',
        'age': 25,
      },
      'preferences': {'theme': 'light', 'notifications': false},
      'roles': ['user', 'editor'],
      'loginCount': 28,
      'lastLogin': DateTime.now().toIso8601String(),
    },
  ]);

  await postsTable.insertMultiple([
    {
      'id': 101,
      'userId': 1,
      'title': 'Understanding Tiny DB',
      'content': 'This is a comprehensive guide to using Tiny DB...',
      'tags': ['dart', 'database', 'tutorial'],
      'createdAt': DateTime.now().toIso8601String(),
      'viewCount': 120,
      'likes': 15,
    },
    {
      'id': 102,
      'userId': 1,
      'title': 'Advanced Queries in Tiny DB',
      'content': 'Learn how to create complex queries with Tiny DB...',
      'tags': ['dart', 'database', 'advanced'],
      'createdAt': DateTime.now().toIso8601String(),
      'viewCount': 85,
      'likes': 10,
    },
    {
      'id': 103,
      'userId': 2,
      'title': 'Designing with Flutter',
      'content': 'Best practices for UI/UX design in Flutter applications...',
      'tags': ['flutter', 'design', 'ui/ux'], 
      'createdAt': DateTime.now().toIso8601String(),
      'viewCount': 95,
      'likes': 12,
    },
  ]);

  await commentsTable.insertMultiple([
    {
      'id': 1001,
      'postId': 101,
      'userId': 2,
      'content': 'Great article! Very helpful.',
      'createdAt': DateTime.now().toIso8601String(),
      'likes': 3,
    },
    {
      'id': 1002,
      'postId': 101,
      'userId': 2,
      'content': 'I have a question about the query syntax...',
      'createdAt': DateTime.now().toIso8601String(),
      'likes': 1,
    },
    {
      'id': 1003,
      'postId': 102,
      'userId': 2,
      'content': 'This advanced tutorial is exactly what I needed!',
      'createdAt': DateTime.now().toIso8601String(),
      'likes': 4,
    },
    {
      'id': 1004,
      'postId': 103,
      'userId': 1,
      'content': 'Great design tips, Jane!',
      'createdAt': DateTime.now().toIso8601String(),
      'likes': 2,
    },
  ]);

  final popularPostsByJohn = await postsTable.search(
    where('userId').equals(1).and(where('viewCount').greaterThan(100)),
  );
  if (kDebugMode) {
    print('Popular posts by John: ${popularPostsByJohn.length}');
  }

  final commentsOnPost101 = await commentsTable.search(
    where('postId').equals(101),
  );
  if (kDebugMode) {
    print('Comments on post 101: ${commentsOnPost101.length}');
  }

  for (final comment in commentsOnPost101) {
    final userId = comment['userId'];
    final user = await usersTable.getById(userId);
    if (user != null) {
      final updatedComment = Map<String, dynamic>.from(comment);
      updatedComment['author'] = user['username'];
      updatedComment['authorFullName'] = user['profile']['fullName'];

      final postId = comment['postId'];
      final post = await postsTable.getById(postId);
      if (post != null) {
        updatedComment['postTitle'] = post['title'];
      }

      await commentsTable.upsert(
        updatedComment,
        where('id').equals(comment['id']),
      );
    }
  }

  final updatedComments = await commentsTable.search(
    where('postId').equals(101),
  );
  if (kDebugMode) {
    print('Updated comments with author data: ${updatedComments.length}');
    for (final comment in updatedComments) {
      print(
        'Comment by ${comment['author'] ?? 'unknown'} on post: ${comment['postTitle'] ?? 'unknown'}',
      );
    }
  }

  final addTagOps = UpdateOperations().addUnique('tags', 'dart');
  await postsTable.update(addTagOps, where('userId').equals(1));

  final removeTagOps = UpdateOperations().pull('tags', 'advanced');
  await postsTable.update(removeTagOps, where('id').equals(102));

  final updatePrefsOps = UpdateOperations()
      .set('preferences.theme', 'system')
      .set('preferences.notifications', true);

  await usersTable.update(updatePrefsOps, where('id').equals(2));

  final incrementViewsOps = UpdateOperations().increment('viewCount', 5);
  await postsTable.update(incrementViewsOps, where('id').equals(103));

  await usersTable.upsert({
    'id': 3,
    'username': 'newuser',
    'profile': {'fullName': 'New User', 'email': 'new@example.com', 'age': 22},
    'roles': ['user'],
    'loginCount': 1,
    'lastLogin': DateTime.now().toIso8601String(),
  }, where('id').equals(3));

  final userCount = await usersTable.length;
  final postCount = await postsTable.length;
  final commentCount = await commentsTable.length;

  if (kDebugMode) {
    print('Database stats:');
    print('- Users: $userCount');
    print('- Posts: $postCount');
    print('- Comments: $commentCount');
  }
}
