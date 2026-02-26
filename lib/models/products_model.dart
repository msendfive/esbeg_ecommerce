class Product {
  final int id;
  final String name;
  final double price;
  final String brand;
  final int categoryId;
  final String image;
  final bool isFeatured;
  final String? description;
  final DateTime createdAt;
  final List<Map<String, dynamic>> variantsJson;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.brand,
    required this.categoryId,
    required this.image,
    required this.isFeatured,
    this.description,
    required this.createdAt,
    this.variantsJson = const [],
  });

  // Computed property: product is "NEW" if created within last 7 days
  bool get isNew {
    final now = DateTime.now();
    final difference = now.difference(createdAt).inDays;
    return difference <= 7;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawVariants = json['variants'] as List? ?? [];
    final variantsJson = rawVariants
        .map((v) => Map<String, dynamic>.from(v as Map))
        .toList();

    return Product(
      id: json['product_id'],
      name: json['name'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0,
      brand: json['brand']?['name'] ?? '',
      categoryId: json['brand']?['category_id'] ?? 0,
      image: json['primary_image'] != null
          ? json['primary_image']['image_url']
          : '',
      isFeatured: json['is_featured'] == 1,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      variantsJson: variantsJson,
    );
  }
}
