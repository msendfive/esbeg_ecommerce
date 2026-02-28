import '../utilities/constants.dart';

class CartItem {
  // ── server identity ─────────────────────────────────────────────
  final int? cartItemId;

  // ── display ─────────────────────────────────────────────────────
  final String productName;
  final String image;
  final int basePrice;
  final String brand;
  final int categoryId;
  final String categoryName;

  // ── variant ─────────────────────────────────────────────────────
  final String? size;
  final String? color;
  final int? variantId;
  final int variantPrice;

  int quantity;

  CartItem({
    this.cartItemId,
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

  // ── computed ────────────────────────────────────────────────────

  String get id => cartItemId != null
      ? '$cartItemId'
      : (variantId != null ? '$productName-$variantId' : productName);

  int get totalPrice => variantPrice * quantity;

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return double.tryParse(value)?.toInt() ?? 0;
    return 0;
  }

  String get variantText {
    if (size != null && color != null) return 'Size: $size • Color: $color';
    if (size != null) return 'Size: $size';
    if (color != null) return 'Color: $color';
    return 'No variants';
  }

  // ── FROM API ────────────────────────────────────────────────────

  factory CartItem.fromApiJson(Map<String, dynamic> json) {
    final variant = (json['variant'] as Map<String, dynamic>?) ?? {};
    final product = (variant['product'] as Map<String, dynamic>?) ?? {};

    // IMAGE ----------------------------------------------------------
    // FIX: Laravel returns snake_case — was 'primaryImage', must be 'primary_image'
    final primaryImage =
        (product['primary_image'] as Map<String, dynamic>?) ?? // ✅ snake_case
        (product['primaryImage']
            as Map<String, dynamic>?); // fallback camelCase

    final variantImages = variant['images'] as List?;

    String rawUrl =
        primaryImage?['image_url']?.toString() ??
        (variantImages != null && variantImages.isNotEmpty
            ? (variantImages.first as Map)['image_url']?.toString()
            : null) ??
        '';

    final image = rawUrl.isEmpty
        ? ''
        : rawUrl.startsWith('http')
        ? rawUrl
        : '$kBaseUrl$rawUrl';

    // BRAND ----------------------------------------------------------
    final brandRaw = product['brand'];
    final brandName = brandRaw is Map
        ? brandRaw['name']?.toString() ?? ''
        : brandRaw?.toString() ?? '';

    // CATEGORY -------------------------------------------------------
    final catRaw = product['category'] as Map<String, dynamic>?;
    final categoryId = _toInt(catRaw?['category_id'] ?? product['category_id']);
    final categoryName =
        catRaw?['name']?.toString() ??
        product['category_name']?.toString() ??
        '';

    // PRODUCT NAME ---------------------------------------------------
    // FIX: products_model uses 'name', so prefer that over 'product_name'
    final productName =
        product['name']?.toString() ??
        product['product_name']?.toString() ??
        '';

    return CartItem(
      cartItemId: json['cart_item_id'] as int? ?? json['id'] as int?,
      productName: productName,
      image: image,
      basePrice: _toInt(variant['price']),
      brand: brandName,
      categoryId: categoryId,
      categoryName: categoryName,
      size: variant['size']?.toString(),
      color: variant['color']?.toString(),
      variantId: variant['variant_id'] as int? ?? json['variant_id'] as int?,
      variantPrice: _toInt(json['price_snapshot']),
      quantity: json['qty'] as int? ?? 1,
    );
  }

  // ── LOCAL JSON ──────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'cartItemId': cartItemId,
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

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    cartItemId: json['cartItemId'] as int?,
    productName: json['productName'],
    image: json['image'],
    basePrice: _toInt(json['basePrice']),
    brand: json['brand'],
    categoryId: _toInt(json['categoryId']),
    categoryName: json['categoryName'],
    size: json['size'],
    color: json['color'],
    variantId: json['variantId'],
    variantPrice: _toInt(json['variantPrice']),
    quantity: json['quantity'] ?? 1,
  );

  // ── COPY ────────────────────────────────────────────────────────

  CartItem copyWith({
    int? cartItemId,
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
  }) => CartItem(
    cartItemId: cartItemId ?? this.cartItemId,
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
