import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AddressService {
  static const String baseUrl = "http://192.168.2.35:8000/api";

  static Map<String, String> _headers(String token) {
    return {
      "Accept": "application/json",
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  static Future<List<dynamic>> fetchAddresses(String token) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/addresses"),
        headers: _headers(token),
      );
      debugPrint("GET /addresses -> ${response.statusCode}");
      debugPrint(response.body);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data'] ?? [];
      }
      if (response.statusCode == 401) {
        throw Exception("Unauthorized (token invalid)");
      }
      throw Exception("Failed load addresses (${response.statusCode})");
    } on SocketException {
      throw Exception("No internet connection");
    } catch (e) {
      throw Exception("Fetch address error: $e");
    }
  }

  static Future<bool> createAddress(
    String token,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/addresses"),
        headers: _headers(token),
        body: jsonEncode(body),
      );
      debugPrint("POST /addresses -> ${response.statusCode}");
      debugPrint(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) return true;
      if (response.statusCode == 401) throw Exception("Unauthorized");
      if (response.statusCode == 419) throw Exception("CSRF / Sanctum issue");
      return false;
    } on SocketException {
      throw Exception("No internet connection");
    } catch (e) {
      debugPrint("Create address error: $e");
      return false;
    }
  }

  // ✅ FIX: was '$baseUrl/api/addresses/$id' → duplicate /api segment
  static Future<bool> updateAddress(
    String token,
    String id,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/addresses/$id"),
        headers: _headers(token),
        body: jsonEncode(body),
      );
      debugPrint("PUT /addresses/$id -> ${response.statusCode}");
      debugPrint(response.body);
      return response.statusCode == 200;
    } on SocketException {
      throw Exception("No internet connection");
    } catch (e) {
      debugPrint("Update address error: $e");
      return false;
    }
  }

  static Future<bool> deleteAddress(String token, String addressId) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/addresses/$addressId"),
        headers: _headers(token),
      );
      debugPrint("DELETE /addresses/$addressId -> ${response.statusCode}");
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Delete address error: $e");
      return false;
    }
  }
}
