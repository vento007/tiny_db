class Product {
  final int? id;
  final String name;
  final double price;
  final List<String> tags;
  final DateTime lastUpdated;

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.tags,
    required this.lastUpdated,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['doc_id'] as int?,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      tags: List<String>.from(json['tags'] as List),

      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'tags': tags,

      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $price, tags: $tags, lastUpdated: $lastUpdated)';
  }
}
