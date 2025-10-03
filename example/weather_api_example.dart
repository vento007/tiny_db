// Weather API caching example
// Demonstrates offline-first pattern with API data caching

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:tiny_db/tiny_db.dart';

// Mock weather API response structure
class WeatherData {
  final String city;
  final double temperature;
  final String condition;
  final int humidity;
  final DateTime timestamp;

  WeatherData({
    required this.city,
    required this.temperature,
    required this.condition,
    required this.humidity,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'city': city,
        'temperature': temperature,
        'condition': condition,
        'humidity': humidity,
        'timestamp': timestamp.toIso8601String(),
      };

  factory WeatherData.fromJson(Map<String, dynamic> json) => WeatherData(
        city: json['city'] as String,
        temperature: (json['temperature'] as num).toDouble(),
        condition: json['condition'] as String,
        humidity: json['humidity'] as int,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class WeatherCache {
  final TinyDb db;
  final Duration cacheExpiry;

  WeatherCache(this.db, {this.cacheExpiry = const Duration(hours: 1)});

  Future<WeatherData?> getWeather(String city) async {
    final table = db.table('weather');

    // Try to get from cache first
    final cached = await table.get(
      where('city').equals(city),
    );

    if (cached != null) {
      final timestamp = DateTime.parse(cached['timestamp'] as String);
      final age = DateTime.now().difference(timestamp);

      if (age < cacheExpiry) {
        print('📦 Cache HIT for $city (age: ${age.inMinutes}m)');
        return WeatherData.fromJson(cached);
      } else {
        print('⏰ Cache EXPIRED for $city (age: ${age.inHours}h)');
        await table.remove(where('city').equals(city));
      }
    } else {
      print('❌ Cache MISS for $city');
    }

    // Fetch from API
    return await _fetchFromApi(city);
  }

  Future<WeatherData?> _fetchFromApi(String city) async {
    print('🌐 Fetching from API for $city...');

    // In a real app, you'd call an actual weather API
    // For this example, we'll simulate it
    final simulatedData = _simulateApiCall(city);

    if (simulatedData != null) {
      // Cache the result
      final table = db.table('weather');
      await table.insert(simulatedData.toJson());
      print('✅ Cached weather data for $city');
    }

    return simulatedData;
  }

  // Simulate API call (in real app, use http.get)
  WeatherData? _simulateApiCall(String city) {
    // Simulate some cities being unavailable
    if (city.toLowerCase() == 'unknown') {
      return null;
    }

    // Simulated weather data
    final conditions = ['Sunny', 'Cloudy', 'Rainy', 'Snowy'];
    final temp = 15.0 + (city.hashCode % 20);
    final condition = conditions[city.hashCode % conditions.length];

    return WeatherData(
      city: city,
      temperature: temp,
      condition: condition,
      humidity: 50 + (city.hashCode % 40),
      timestamp: DateTime.now(),
    );
  }

  Future<List<WeatherData>> getCachedCities() async {
    final table = db.table('weather');
    final all = await table.all();
    return all.map((doc) => WeatherData.fromJson(doc)).toList();
  }

  Future<void> clearOldCache() async {
    final table = db.table('weather');
    final cutoff = DateTime.now().subtract(cacheExpiry);

    final removed = await table.remove(
      where('timestamp').test(
        (value) {
          if (value == null) return true;
          return DateTime.parse(value as String).isBefore(cutoff);
        },
      ),
    );

    print('🧹 Cleared $removed expired cache entries');
  }

  Future<Map<String, dynamic>> getCacheStats() async {
    final table = db.table('weather');
    final total = await table.length;

    if (total == 0) {
      return {'total': 0, 'fresh': 0, 'stale': 0};
    }

    final cutoff = DateTime.now().subtract(cacheExpiry);
    final fresh = await table.count(
      where('timestamp').test(
        (value) => DateTime.parse(value as String).isAfter(cutoff),
      ),
    );

    return {
      'total': total,
      'fresh': fresh,
      'stale': total - fresh,
    };
  }
}

Future<void> main() async {
  print('🌤️  Weather API Caching Example\n');
  print('${'=' * 60}\n');

  // Create database with JSON storage for persistence
  final dbPath = '${Directory.systemTemp.path}/weather_cache.json';
  final db = TinyDb(
    JsonStorage(dbPath, createDirs: true, indentAmount: 2),
  );

  try {
    final cache = WeatherCache(db, cacheExpiry: Duration(minutes: 30));

    // ========================================
    // Simulate user checking weather
    // ========================================
    print('1️⃣  User checks weather for multiple cities\n');

    final cities = ['New York', 'London', 'Tokyo', 'Paris', 'Sydney'];

    for (final city in cities) {
      final weather = await cache.getWeather(city);
      if (weather != null) {
        print('   $city: ${weather.temperature}°C, ${weather.condition}');
      }
    }

    print('\n${'=' * 60}\n');

    // ========================================
    // Check cache statistics
    // ========================================
    print('2️⃣  Cache Statistics\n');

    final stats = await cache.getCacheStats();
    print('   • Total cached: ${stats['total']}');
    print('   • Fresh entries: ${stats['fresh']}');
    print('   • Stale entries: ${stats['stale']}\n');

    print('${'=' * 60}\n');

    // ========================================
    // Simulate cache hits (fast!)
    // ========================================
    print('3️⃣  Retrieving from cache (should be instant)\n');

    final start = DateTime.now();
    for (final city in cities.take(3)) {
      await cache.getWeather(city);
    }
    final elapsed = DateTime.now().difference(start);
    print('   ⚡ Retrieved 3 cities in ${elapsed.inMilliseconds}ms\n');

    print('${'=' * 60}\n');

    // ========================================
    // Query cached data
    // ========================================
    print('4️⃣  Querying cached weather data\n');

    final table = db.table('weather');

    // Find hot cities
    print('   🔥 Hot cities (temp > 25°C):');
    final hotCities = await table.search(
      where('temperature').greaterThan(25),
    );
    for (final city in hotCities) {
      print('      • ${city['city']}: ${city['temperature']}°C');
    }
    print('');

    // Find cities with specific conditions
    print('   ☀️  Sunny cities:');
    final sunnyCities = await table.search(
      where('condition').equals('Sunny'),
    );
    for (final city in sunnyCities) {
      print('      • ${city['city']} (${city['temperature']}°C)');
    }
    print('');

    // Find recently updated
    final fiveMinutesAgo = DateTime.now().subtract(Duration(minutes: 5));
    print('   ⏱️  Recently updated (last 5 min):');
    final recent = await table.search(
      where('timestamp').test(
        (value) => DateTime.parse(value as String).isAfter(fiveMinutesAgo),
      ),
    );
    print('      • ${recent.length} cities\n');

    print('${'=' * 60}\n');

    // ========================================
    // Offline mode simulation
    // ========================================
    print('5️⃣  Offline Mode Simulation\n');

    print('   📶 Simulating offline mode...');
    print('   📦 Available cached cities:\n');

    final cached = await cache.getCachedCities();
    for (final weather in cached) {
      final age = DateTime.now().difference(weather.timestamp);
      print('      • ${weather.city}: ${weather.temperature}°C');
      print('        (cached ${age.inMinutes} minutes ago)');
    }
    print('');

    print('${'=' * 60}\n');

    // ========================================
    // Cache management
    // ========================================
    print('6️⃣  Cache Management\n');

    // Update weather for specific city
    print('   🔄 Refreshing weather for London...');
    await table.remove(where('city').equals('London'));
    await cache.getWeather('London');
    print('   ✅ London weather updated\n');

    // Clear old cache
    print('   🧹 Cleaning up old cache entries...');
    await cache.clearOldCache();

    final finalStats = await cache.getCacheStats();
    print('   📊 Final cache stats:');
    print('      • Total: ${finalStats['total']}');
    print('      • Fresh: ${finalStats['fresh']}');
    print('      • Stale: ${finalStats['stale']}\n');

    print('${'=' * 60}\n');

    // ========================================
    // Show persistent storage
    // ========================================
    print('7️⃣  Persistent Storage\n');

    print('   💾 Cache saved to: $dbPath');
    print('   📄 JSON file contents:\n');

    if (File(dbPath).existsSync()) {
      final jsonContent = File(dbPath).readAsStringSync();
      // Pretty print first 500 chars
      final preview = jsonContent.length > 500
          ? '${jsonContent.substring(0, 500)}...'
          : jsonContent;
      print(preview);
    }

    print('\n${'=' * 60}');
    print('\n✅ Weather caching example completed!');
    print('   Key benefits demonstrated:');
    print('   • Offline-first data access');
    print('   • Reduced API calls');
    print('   • Complex queries on cached data');
    print('   • Automatic cache expiry');
    print('   • Persistent storage\n');
  } finally {
    await db.close();
  }
}
