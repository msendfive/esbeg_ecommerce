import '../utilities/constants.dart';

// ---------------------------------------------------------------------------
// OrderStatus
// ---------------------------------------------------------------------------

enum OrderStatus {
  pending,
  processing,
  shipped,
  delivered,
  cancelled,
  unknown;

  static OrderStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'processing':
        return OrderStatus.processing;
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.unknown;
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.unknown:
        return 'Unknown';
    }
  }
}

// ---------------------------------------------------------------------------
// OrderItem
// ---------------------------------------------------------------------------

class OrderItem {
  final int? orderItemId;
  final String productName;
  final String image;
  final String? size;
  final String? color;
  final int variantPrice;
  final int quantity;

  const OrderItem({
    this.orderItemId,
    required this.productName,
    required this.image,
    this.size,
    this.color,
    required this.variantPrice,
    required this.quantity,
  });

  int get totalPrice => variantPrice * quantity;

  String get variantText {
    if (size != null && color != null) return 'Size: $size • Color: $color';
    if (size != null) return 'Size: $size';
    if (color != null) return 'Color: $color';
    return 'No variants';
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return double.tryParse(value)?.toInt() ?? 0;
    return 0;
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // image may be a full URL or a storage path
    final rawImage = json['image']?.toString() ?? '';
    final image = rawImage.isEmpty
        ? ''
        : rawImage.startsWith('http')
        ? rawImage
        : '$kBaseUrl/storage/$rawImage';

    return OrderItem(
      orderItemId: json['order_item_id'] as int? ?? json['id'] as int?,
      productName:
          json['product_name']?.toString() ?? json['name']?.toString() ?? '',
      image: image,
      size: json['size']?.toString(),
      color: json['color']?.toString(),
      variantPrice: _toInt(json['variant_price'] ?? json['price_snapshot']),
      quantity: json['qty'] as int? ?? json['quantity'] as int? ?? 1,
    );
  }
}

// ---------------------------------------------------------------------------
// ShippingAddress
// ---------------------------------------------------------------------------

class ShippingAddress {
  final String name;
  final String phone;
  final String address;
  final String? city;
  final String? province;
  final String? postalCode;

  const ShippingAddress({
    required this.name,
    required this.phone,
    required this.address,
    this.city,
    this.province,
    this.postalCode,
  });

  String get fullAddress {
    final parts = [
      address,
      city,
      province,
      postalCode,
    ].where((p) => p != null && p.isNotEmpty).toList();
    return parts.join(', ');
  }

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      name:
          json['name']?.toString() ?? json['recipient_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? json['street']?.toString() ?? '',
      city: json['city']?.toString(),
      province: json['province']?.toString(),
      postalCode: json['postal_code']?.toString() ?? json['zip']?.toString(),
    );
  }
}

// ---------------------------------------------------------------------------
// Order
// ---------------------------------------------------------------------------

class Order {
  final int orderId;
  final String orderCode;
  final OrderStatus status;
  final int subtotal;
  final int shippingCost;
  final int insuranceCost;
  final int discount;
  final int grandTotal;
  final String? voucherCode;
  final String? paymentMethod;
  final ShippingAddress? shippingAddress;
  final List<OrderItem> items;
  final DateTime createdAt;

  const Order({
    required this.orderId,
    required this.orderCode,
    required this.status,
    required this.subtotal,
    required this.shippingCost,
    required this.insuranceCost,
    required this.discount,
    required this.grandTotal,
    this.voucherCode,
    this.paymentMethod,
    this.shippingAddress,
    required this.items,
    required this.createdAt,
  });

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return double.tryParse(value)?.toInt() ?? 0;
    return 0;
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    // items
    final rawItems =
        json['items'] as List? ?? json['order_items'] as List? ?? [];
    final items = rawItems
        .map((i) => OrderItem.fromJson(Map<String, dynamic>.from(i as Map)))
        .toList();

    // shipping address
    ShippingAddress? address;
    final rawAddr = json['shipping_address'] ?? json['address'];
    if (rawAddr is Map) {
      address = ShippingAddress.fromJson(Map<String, dynamic>.from(rawAddr));
    }

    return Order(
      orderId: json['order_id'] as int? ?? json['id'] as int? ?? 0,
      orderCode:
          json['order_code']?.toString() ??
          json['code']?.toString() ??
          '#${json['order_id'] ?? json['id']}',
      status: OrderStatus.fromString(json['status']?.toString()),
      subtotal: _toInt(json['subtotal'] ?? json['total_price']),
      shippingCost: _toInt(json['shipping_cost']),
      insuranceCost: _toInt(json['insurance_cost']),
      discount: _toInt(json['discount']),
      grandTotal: _toInt(json['grand_total'] ?? json['total']),
      voucherCode: json['voucher_code']?.toString(),
      paymentMethod: json['payment_method']?.toString(),
      shippingAddress: address,
      items: items,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
