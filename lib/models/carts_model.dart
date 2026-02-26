// models/cart_item.dart

class CartItem {
  final String productName;
  final String image;
  final int basePrice;
  final String brand;
  final int categoryId;
  final String categoryName;

  // Variant details
  final String? size;
  final String? color;
  final int? variantId;
  final int variantPrice; // Actual price (variant or base)

  int quantity;

  CartItem({
    required this.productName,
    required this.image,
    required this.basePrice,
    required this.brand,
    required this.categoryId,
    required this.categoryName,
    this.size,
    this.color,
    this.variantId,
    required this.variantPrice,
    this.quantity = 1,
  });

  // Unique identifier for cart item (product + variant combo)
  String get id {
    if (variantId != null) {
      return '$productName-$variantId';
    }
    return productName;
  }

  // Total price for this cart item
  int get totalPrice => variantPrice * quantity;

  // Variant display text
  String get variantText {
    if (size != null && color != null) {
      return 'Size: $size • Color: $color';
    } else if (size != null) {
      return 'Size: $size';
    } else if (color != null) {
      return 'Color: $color';
    }
    return 'No variants';
  }

  // Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'productName': productName,
      'image': image,
      'basePrice': basePrice,
      'brand': brand,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'size': size,
      'color': color,
      'variantId': variantId,
      'variantPrice': variantPrice,
      'quantity': quantity,
    };
  }

  // Create from JSON
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productName: json['productName'],
      image: json['image'],
      basePrice: json['basePrice'],
      brand: json['brand'],
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      size: json['size'],
      color: json['color'],
      variantId: json['variantId'],
      variantPrice: json['variantPrice'],
      quantity: json['quantity'] ?? 1,
    );
  }

  // Create a copy with modifications
  CartItem copyWith({
    String? productName,
    String? image,
    int? basePrice,
    String? brand,
    int? categoryId,
    String? categoryName,
    String? size,
    String? color,
    int? variantId,
    int? variantPrice,
    int? quantity,
  }) {
    return CartItem(
      productName: productName ?? this.productName,
      image: image ?? this.image,
      basePrice: basePrice ?? this.basePrice,
      brand: brand ?? this.brand,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      size: size ?? this.size,
      color: color ?? this.color,
      variantId: variantId ?? this.variantId,
      variantPrice: variantPrice ?? this.variantPrice,
      quantity: quantity ?? this.quantity,
    );
  }
}
