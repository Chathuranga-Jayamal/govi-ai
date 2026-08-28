enum ProductCategory {
  fertilizer,
  pesticide,
  tools;

  String get label {
    switch (this) {
      case ProductCategory.fertilizer:
        return 'Fertilizer';
      case ProductCategory.pesticide:
        return 'Pesticide';
      case ProductCategory.tools:
        return 'Tools';
    }
  }
}

/// Result of a GET /products or GET /products/{id} call.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.rating,
    required this.isBestSeller,
    this.description,
    this.usageInstructions,
    this.warningText,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as int,
    name: json['name'] as String,
    category: ProductCategory.values.byName(json['category'] as String),
    price: (json['price'] as num).toDouble(),
    rating: (json['rating'] as num).toDouble(),
    isBestSeller: json['isBestSeller'] as bool,
    description: json['description'] as String?,
    usageInstructions: json['usageInstructions'] as String?,
    warningText: json['warningText'] as String?,
    imageUrl: json['imageUrl'] as String?,
  );

  final int id;
  final String name;
  final ProductCategory category;
  final double price;
  final double rating;
  final bool isBestSeller;
  final String? description;
  final String? usageInstructions;
  final String? warningText;
  final String? imageUrl;

  String get priceLabel => 'Rs. ${price.toStringAsFixed(0)}';
}
