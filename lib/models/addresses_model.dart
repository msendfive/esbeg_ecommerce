class Address {
  final String addressId;

  final String label;
  final String receiverName;
  final String phone;
  final String addressLine;

  // ================= REGION =================
  final String province;
  final String provinceId;

  final String city; // regency
  final String cityId;

  final String district;
  final String districtId;

  final String subdistrict; // village
  final String subdistrictId;

  final String postalCode;
  final String rt;
  final String rw;

  final bool isDefault;

  const Address({
    required this.addressId,
    required this.label,
    required this.receiverName,
    required this.phone,
    required this.addressLine,
    required this.province,
    this.provinceId = '',
    required this.city,
    this.cityId = '',
    required this.district,
    this.districtId = '',
    required this.subdistrict,
    this.subdistrictId = '',
    required this.postalCode,
    this.rt = '',
    this.rw = '',
    required this.isDefault,
  });

  // =========================================================
  // HELPERS
  // =========================================================

  String get id => addressId;

  /// Full formatted address
  String get fullAddress {
    final parts = <String>[
      if (rt.isNotEmpty && rw.isNotEmpty) 'RT $rt/RW $rw',
      addressLine,
      subdistrict,
      district,
      city,
      province,
      postalCode,
    ].where((e) => e.isNotEmpty).toList();

    return parts.join(', ');
  }

  // =========================================================
  // FROM JSON (BACKEND → APP)
  // =========================================================

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      addressId: json['address_id'].toString(),

      label: json['label'] ?? '',
      receiverName: json['receiver_name'] ?? '',
      phone: json['phone'] ?? '',
      addressLine: json['address_line'] ?? '',

      province: json['province'] ?? '',
      provinceId: json['province_id'] ?? '',

      // wilayah.id = regency
      city: json['city'] ?? json['regency'] ?? '',

      cityId: json['city_id'] ?? json['regency_id'] ?? '',

      district: json['district'] ?? '',
      districtId: json['district_id'] ?? '',

      // wilayah.id terminology
      subdistrict: json['subdistrict'] ?? json['village'] ?? '',

      subdistrictId: json['subdistrict_id'] ?? json['village_id'] ?? '',

      postalCode: json['postal_code'] ?? '',
      rt: json['rt'] ?? '',
      rw: json['rw'] ?? '',

      isDefault:
          json['is_default'] == true ||
          json['is_default'] == 1 ||
          json['is_default'] == '1',
    );
  }

  // =========================================================
  // TO JSON (APP → BACKEND)
  // =========================================================

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'receiver_name': receiverName,
      'phone': phone,
      'address_line': addressLine,

      'province': province,
      'province_id': provinceId,

      'city': city,
      'city_id': cityId,

      'district': district,
      'district_id': districtId,

      // kirim dua nama biar aman backend lama & baru
      'subdistrict': subdistrict,
      'village': subdistrict,

      'subdistrict_id': subdistrictId,
      'village_id': subdistrictId,

      'postal_code': postalCode,
      'rt': rt,
      'rw': rw,

      'is_default': isDefault ? 1 : 0,
    };
  }
}
