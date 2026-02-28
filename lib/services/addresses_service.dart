import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AddressService {
  static const String baseUrl = 'http://192.168.2.35:8000/api';

  static Map<String, String> _headers(String token) => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ── GET /addresses ──────────────────────────────────────────────────────

  static Future<List<dynamic>> fetchAddresses(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/addresses'),
        headers: _headers(token),
      );
      debugPrint('GET /addresses -> ${response.statusCode}');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data'] is List
            ? json['data'] as List
            : json is List
            ? json
            : [];
      }
      if (response.statusCode == 401) throw Exception('Unauthorized');
      throw Exception('Failed to load addresses (${response.statusCode})');
    } on SocketException {
      throw Exception('No internet connection');
    } catch (e) {
      throw Exception('Fetch address error: $e');
    }
  }

  // ── POST /addresses ─────────────────────────────────────────────────────

  static Future<bool> createAddress(
    String token,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/addresses'),
        headers: _headers(token),
        body: jsonEncode(body),
      );
      debugPrint('POST /addresses -> ${response.statusCode}: ${response.body}');
      return response.statusCode == 200 || response.statusCode == 201;
    } on SocketException {
      throw Exception('No internet connection');
    } catch (e) {
      debugPrint('Create address error: $e');
      return false;
    }
  }

  // ── PUT /addresses/{id} ─────────────────────────────────────────────────
  // Returns the updated address JSON map on success, null on failure.
  // Provider uses null-check to determine success — no separate bool needed.

  static Future<Map<String, dynamic>?> updateAddress(
    String token,
    String id,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/addresses/$id'),
        headers: _headers(token),
        body: jsonEncode(body),
      );
      debugPrint(
        'PUT /addresses/$id -> ${response.statusCode}: ${response.body}',
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        // Support { data: {...} } or bare object
        return (json['data'] is Map
                ? json['data']
                : json is Map
                ? json
                : null)
            ?.cast<String, dynamic>();
      }
      return null;
    } on SocketException {
      throw Exception('No internet connection');
    } catch (e) {
      debugPrint('Update address error: $e');
      return null;
    }
  }

  // ── DELETE /addresses/{id} ──────────────────────────────────────────────

  static Future<bool> deleteAddress(String token, String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/addresses/$id'),
        headers: _headers(token),
      );
      debugPrint('DELETE /addresses/$id -> ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Delete address error: $e');
      return false;
    }
  }
}
