import 'package:cr_json_widget/cr_json_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tiny_db/tiny_db.dart';

import 'examples/basic_example.dart';
import 'examples/advanced_example.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'tiny_db Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Tiny DB Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TinyDb? _db;
  Map<String, dynamic> _jsonData = {};
  bool _isLoading = true;
  String _currentExample = 'Basic';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initDb();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _closeDb();
    super.dispose();
  }

  Future<void> _initDb() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _db = TinyDb(MemoryStorage());

      await runBasicExample(_db!);

      await _refreshJsonView();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing database: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _closeDb() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  Future<void> _refreshJsonView() async {
    try {
      final allTables = await _db?.tables() ?? {};
      Map<String, dynamic> dbData = {};

      for (final tableName in allTables) {
        final table = _db!.table(tableName);
        final docs = await table.all();
        dbData[tableName] = docs;
      }

      setState(() {
        _jsonData = dbData;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error reading database: $e');
      }
    }
  }

  Future<void> _runExample(String example) async {
    setState(() {
      _isLoading = true;
      _currentExample = example;
    });

    try {
      await _closeDb();

      _db = TinyDb(MemoryStorage());

      if (example == 'Basic') {
        await runBasicExample(_db!);
      } else if (example == 'Advanced') {
        await runAdvancedExample(_db!);
      }

      await _refreshJsonView();
    } catch (e) {
      if (kDebugMode) {
        print('Error running example: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Examples'), Tab(text: 'JSON View')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildExamplesTab(), _buildJsonViewTab()],
      ),
    );
  }

  Widget _buildExamplesTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tiny DB Examples',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Current Example: $_currentExample',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              ElevatedButton(
                onPressed: _isLoading ? null : () => _runExample('Basic'),
                child: const Text('Basic Example'),
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : () => _runExample('Advanced'),
                child: const Text('Advanced Example'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Example Description:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(_getExampleDescription()),
                          const SizedBox(height: 16),
                          Text(
                            'Storage Type:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          const Text('In-memory database (for demo purposes)'),
                          const SizedBox(height: 24),
                          const Text(
                            'Switch to the JSON View tab to see the database contents.',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildJsonViewTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Database Structure',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'This shows the actual structure of the Tiny DB database.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (_currentExample == 'Advanced') _buildDatabaseOverview(),
              if (_currentExample == 'Advanced' &&
                  _jsonData.containsKey('comments'))
                _buildCommentsSection(),
              const SizedBox(height: 24),
              Text(
                'Full Database Structure:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              CrJsonWidget(json: _jsonData),
            ],
          ),
        );
  }

  Widget _buildDatabaseOverview() {
    final tableNames = _jsonData.keys.toList();
    final tableCounts = <String, int>{};

    for (final tableName in tableNames) {
      final tableData = _jsonData[tableName];
      if (tableData is List) {
        tableCounts[tableName] = tableData.length;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Database Overview:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade50,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tables and Relationships:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              _buildTableInfoCard(
                'users',
                tableCounts['users'] ?? 0,
                'Contains user profiles with nested data',
                'Primary table with user information',
                Colors.blue.shade100,
              ),
              const SizedBox(height: 8),

              _buildTableInfoCard(
                'posts',
                tableCounts['posts'] ?? 0,
                'Contains posts with userId foreign key',
                'References users table via userId field',
                Colors.green.shade100,
              ),
              const SizedBox(height: 8),

              _buildTableInfoCard(
                'comments',
                tableCounts['comments'] ?? 0,
                'Contains comments with userId and postId foreign keys',
                'References both users and posts tables',
                Colors.orange.shade100,
              ),
              const SizedBox(height: 16),
              Text(
                'Relationship Diagram:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [_buildTableBox('Users', Colors.blue.shade100)],
                    ),
                    Icon(Icons.arrow_downward, color: Colors.grey.shade600),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTableBox('Posts', Colors.green.shade100),
                      ],
                    ),
                    Icon(Icons.arrow_downward, color: Colors.grey.shade600),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTableBox('Comments', Colors.orange.shade100),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'One user can have many posts, and one post can have many comments',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTableInfoCard(
    String name,
    int count,
    String description,
    String relationship,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count records',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 2),
          Text(
            relationship,
            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildTableBox(String name, Color color) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCommentsSection() {
    if (!_jsonData.containsKey('comments')) {
      return const Text('No comments data available');
    }

    final comments = _jsonData['comments'] as List<dynamic>;
    if (comments.isEmpty) {
      return const Text('Comments list is empty');
    }

    final enhancedComments =
        comments.where((c) => c.containsKey('author')).toList();
    if (enhancedComments.isEmpty) {
      return const Text('No enhanced comments with author data found');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comments with Joined Data:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'The advanced example demonstrates how to join data from multiple tables.',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < enhancedComments.length; i++)
                _buildCommentItem(enhancedComments[i], i),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    (comment['authorFullName'] as String?)
                            ?.substring(0, 1)
                            .toUpperCase() ??
                        'U',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment['authorFullName'] ?? 'Unknown User',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '@${comment['author'] ?? 'unknown'}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'On post: ${comment['postTitle'] ?? 'Unknown post'}',
              style: TextStyle(color: Colors.blue[800], fontSize: 12),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              comment['content'] ?? 'No content',
              style: const TextStyle(fontSize: 14),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${comment['likes'] ?? 0} likes',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getExampleDescription() {
    switch (_currentExample) {
      case 'Basic':
        return 'This example demonstrates basic operations with Tiny DB, including creating a database, inserting documents, and querying data. It uses the default table and shows simple document storage.';
      case 'Advanced':
        return 'This example shows advanced features like multiple tables, complex queries, and update operations. It demonstrates how to use specialized list operations, nested data, and table organization.';
      default:
        return '';
    }
  }
}
