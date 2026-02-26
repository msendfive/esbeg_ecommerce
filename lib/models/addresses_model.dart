class Address {
  final String addressId;
  final String label;
  final String receiverName;
  final String phone;
  final String addressLine;
  final String city;
  final String province;
  final String postalCode;
  final bool isDefault;

  Address({
    required this.addressId,
    required this.label,
    required this.receiverName,
    required this.phone,
    required this.addressLine,
    required this.city,
    required this.province,
    required this.postalCode,
    required this.isDefault,
  });

  // ✅ Convenience getter so profile_page can use addr.id
  String get id => addressId;

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      addressId: json['address_id'].toString(),
      label: json['label']?.toString() ?? '',
      receiverName: json['receiver_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      addressLine: json['address_line']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      province: json['province']?.toString() ?? '',
      postalCode: json['postal_code']?.toString() ?? '',
      isDefault:
          json['is_default'] == true ||
          json['is_default'] == 1 ||
          json['is_default'] == '1',
    );
  }
}
