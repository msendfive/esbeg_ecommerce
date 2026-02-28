// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;

// class RegionItem {
//   final String id;
//   final String name;

//   const RegionItem({required this.id, required this.name});

//   @override
//   String toString() => name;

//   @override
//   bool operator ==(Object other) => other is RegionItem && other.id == id;

//   @override
//   int get hashCode => id.hashCode;
// }

// class IndonesiaRegionService {
//   static const _base = 'https://wilayah.id/api';

//   static final Map<String, List<RegionItem>> _cache = {};

//   // =====================================================
//   // CORE FETCH
//   // =====================================================

//   static Future<List<RegionItem>> _fetch(String url) async {
//     if (_cache.containsKey(url)) return _cache[url]!;

//     try {
//       final response = await http
//           .get(Uri.parse(url))
//           .timeout(const Duration(seconds: 10));

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> json = jsonDecode(response.body);

//         final List data = json['data'] ?? [];

//         final items = data
//             .map<RegionItem>(
//               (e) => RegionItem(
//                 id: e['code'].toString(),
//                 name: e['name'].toString(),
//               ),
//             )
//             .toList();

//         _cache[url] = items;
//         return items;
//       }
//     } catch (e) {
//       debugPrint('RegionService error [$url]: $e');
//     }

//     return [];
//   }

//   // =====================================================
//   // ENDPOINTS (CORRECT FORMAT)
//   // =====================================================

//   /// GET https://wilayah.id/api/provinces.json
//   static Future<List<RegionItem>> fetchProvinces() =>
//       _fetch('$_base/provinces.json');

//   /// GET https://wilayah.id/api/regencies/{provinceCode}.json
//   static Future<List<RegionItem>> fetchRegencies(String provinceCode) =>
//       _fetch('$_base/regencies/$provinceCode.json');

//   /// GET https://wilayah.id/api/districts/{regencyCode}.json
//   static Future<List<RegionItem>> fetchDistricts(String regencyCode) =>
//       _fetch('$_base/districts/$regencyCode.json');

//   /// GET https://wilayah.id/api/villages/{districtCode}.json
//   static Future<List<RegionItem>> fetchVillages(String districtCode) =>
//       _fetch('$_base/villages/$districtCode.json');

//   static void clearCache() => _cache.clear();
// }

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class RegionItem {
  final String id;
  final String name;

  const RegionItem({required this.id, required this.name});

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) => other is RegionItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class IndonesiaRegionService {
  static List<dynamic>? _allData;

  // Membaca file JSON dari assets satu kali saja ke memori
  static Future<void> _initData() async {
    if (_allData != null) return;
    try {
      final String response = await rootBundle.loadString('/data/wilayah.json');
      _allData = json.decode(response);
    } catch (e) {
      debugPrint('Error loading local JSON: $e');
      _allData = [];
    }
  }

  // =====================================================
  // LOGIKA FILTERING (BERDASARKAN POLA KODE)
  // =====================================================

  /// Provinsi: Kode hanya 2 karakter (e.g., "32")
  static Future<List<RegionItem>> fetchProvinces() async {
    await _initData();
    return _allData!
        .where((item) => item['kode'].toString().length == 2)
        .map<RegionItem>((e) => RegionItem(id: e['kode'], name: e['nama']))
        .toList();
  }

  /// Kabupaten: Kode diawali {provinceCode} + "." + 2 digit (e.g., "32.01")
  static Future<List<RegionItem>> fetchRegencies(String provinceCode) async {
    await _initData();
    return _allData!
        .where((item) {
          final String kode = item['kode'].toString();
          return kode.startsWith('$provinceCode.') && kode.length == 5;
        })
        .map<RegionItem>((e) => RegionItem(id: e['kode'], name: e['nama']))
        .toList();
  }

  /// Kecamatan: Kode diawali {regencyCode} + "." + 2 digit (e.g., "32.01.01")
  static Future<List<RegionItem>> fetchDistricts(String regencyCode) async {
    await _initData();
    return _allData!
        .where((item) {
          final String kode = item['kode'].toString();
          return kode.startsWith('$regencyCode.') && kode.length == 8;
        })
        .map<RegionItem>((e) => RegionItem(id: e['kode'], name: e['nama']))
        .toList();
  }

  /// Desa: Kode diawali {districtCode} + "." + 4 digit (e.g., "32.01.01.1001")
  static Future<List<RegionItem>> fetchVillages(String districtCode) async {
    await _initData();
    return _allData!
        .where((item) {
          final String kode = item['kode'].toString();
          return kode.startsWith('$districtCode.') && kode.length == 13;
        })
        .map<RegionItem>((e) => RegionItem(id: e['kode'], name: e['nama']))
        .toList();
  }
}
