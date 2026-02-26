class Brand {
  final int id;
  final int categoryId;
  final String name;
  final String imageLogo; // ✅ tambahkan ini

  Brand({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.imageLogo,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['brand_id'],
      categoryId: json['category_id'],
      name: json['name'],
      imageLogo: json['image_logo'], // ✅ ambil dari API
    );
  }
}
