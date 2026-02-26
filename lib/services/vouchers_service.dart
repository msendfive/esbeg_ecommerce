import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class VoucherService {
  static const String baseUrl = "http://192.168.2.35:8000";

  static Future<List<dynamic>> fetchVouchers(String token) async {
    // ✅ Strip "Bearer " prefix if already included, then re-add cleanly
    final cleanToken = token.startsWith('Bearer ')
        ? token.substring(7).trim()
        : token.trim();

    final response = await http.get(
      Uri.parse('$baseUrl/api/vouchers'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $cleanToken',
      },
    );

    // ✅ Debug: print status + raw body to help diagnose
    debugPrint('Voucher status: ${response.statusCode}');
    debugPrint('Voucher body: ${response.body}');

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);

      // ✅ Handle both { data: [...] } and plain [...] responses
      if (body is List) return body;
      if (body['data'] is List) return body['data'];

      return [];
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Token invalid or expired');
    } else {
      throw Exception('Failed to load vouchers (${response.statusCode})');
    }
  }
}
