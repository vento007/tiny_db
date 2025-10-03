// Example: Using typed models with tiny_db
// Shows how to serialize/deserialize custom classes

import 'package:tiny_db/tiny_db.dart';
import 'products_model.dart'; // Import the Product model

Future<void> main() async {
  final db = TinyDb(MemoryStorage());

  try {
    print('Model Serialization Example\n');

    // Create Product instances
    final product1 = Product(
      name: 'Laptop',
      price: 999.99,
      tags: ['electronics', 'computers'],
      lastUpdated: DateTime.now(),
    );

    final product2 = Product(
      name: 'Mouse',
      price: 29.99,
      tags: ['electronics', 'accessories'],
      lastUpdated: DateTime.now(),
    );

    final product3 = Product(
      name: 'Keyboard',
      price: 79.99,
      tags: ['electronics', 'accessories', 'gaming'],
      lastUpdated: DateTime.now(),
    );

    // Store using toJson()
    print('Storing products...');
    await db.insert(product1.toJson());
    await db.insert(product2.toJson());
    await db.insert(product3.toJson());
    print('✓ Stored 3 products\n');

    // Query and retrieve as typed objects
    print('Querying expensive products (price > 50)...');
    final expensiveDocs = await db.defaultTable.search(
      where('price').greaterThan(50),
    );

    // Convert back to Product objects using fromJson()
    final expensiveProducts = expensiveDocs.map(Product.fromJson).toList();

    print('Found ${expensiveProducts.length} expensive products:');
    for (final product in expensiveProducts) {
      print('  • ${product.name}: \$${product.price}');
      print('    Tags: ${product.tags.join(', ')}');
    }
    print('');

    // Query by tags (list operation)
    print('Querying products with "gaming" tag...');
    final gamingDocs = await db.defaultTable.search(
      where('tags').anyInList(['gaming']),
    );

    final gamingProducts = gamingDocs.map(Product.fromJson).toList();
    print('Found ${gamingProducts.length} gaming products:');
    for (final product in gamingProducts) {
      print('  • ${product.name}: \$${product.price}');
    }
    print('');

    // Update using models
    print('Updating laptop price...');
    await db.defaultTable.update(
      UpdateOperations()
          .set('price', 899.99)
          .set('lastUpdated', DateTime.now().toIso8601String()),
      where('name').equals('Laptop'),
    );

    final updatedDocs = await db.defaultTable.search(
      where('name').equals('Laptop'),
    );
    final updatedLaptop = Product.fromJson(updatedDocs.first);
    print('✓ Updated price: \$${updatedLaptop.price}\n');

    print('Benefits of using models:');
    print('  • Type safety');
    print('  • IDE autocomplete');
    print('  • Clear data structure');
    print('  • Easy validation in fromJson()');
    print('  • Reusable across your app');
  } finally {
    await db.close();
  }
}
