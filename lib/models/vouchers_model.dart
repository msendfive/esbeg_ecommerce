enum DiscountType { percentage, fixed }

class Voucher {
  final String id;
  final String code;
  final String title;
  final String description;
  final DiscountType type;
  final double value;
  final double minOrder;
  final double? maxDiscount; // null = no cap
  final DateTime startAt;
  final DateTime endAt;
  final String status;

  Voucher({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.type,
    required this.value,
    required this.minOrder,
    required this.maxDiscount,
    required this.startAt,
    required this.endAt,
    required this.status,
  });

  bool get isExpired => DateTime.now().isAfter(endAt);

  factory Voucher.fromJson(Map<String, dynamic> json) {
    final rawMax = json['max_discount_amount'];
    final parsedMax = rawMax != null
        ? double.tryParse(rawMax.toString()) ?? 0.0
        : 0.0;

    return Voucher(
      id: json['voucher_id'].toString(),
      code: json['code'] ?? '',
      title: json['name'] ?? '',
      description: json['description'] ?? '',

      type: json['discount_type'] == 'percent'
          ? DiscountType.percentage
          : DiscountType.fixed,

      value: double.parse(json['discount_value'].toString()),
      minOrder: double.parse(json['min_order_amount'].toString()),

      // ✅ FIX: treat 0 as "no cap" → null
      // e.g. PBEMEB has max_discount_amount=0, meaning unlimited discount
      maxDiscount: parsedMax > 0 ? parsedMax : null,

      startAt: DateTime.parse(json['start_at']),
      endAt: DateTime.parse(json['end_at']),
      status: json['status'] ?? 'active',
    );
  }
}
