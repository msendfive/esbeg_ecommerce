import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/users_model.dart';
import 'package:flutter/foundation.dart';

class ProfileService {
  static const String baseUrl = "http://192.168.2.35:8000/api";

  // ================= GET PROFILE =================
  static Future<User?> getProfile(String token) async {
    final res = await http.get(
      Uri.parse("$baseUrl/profile"),
      headers: {"Accept": "application/json", "Authorization": "Bearer $token"},
    );

    debugPrint("STATUS: ${res.statusCode}");
    debugPrint("BODY: ${res.body}");

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return User.fromJson(data['data'] ?? data);
    }

    return null;
  }

  // ================= UPDATE PROFILE =================
  static Future<bool> updateProfile(
    String token,
    Map<String, dynamic> body,
  ) async {
    final res = await http.put(
      Uri.parse("$baseUrl/profile"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    return res.statusCode == 200;
  }

  // ================= UPDATE PASSWORD =================
  static Future<bool> updatePassword(
    String token,
    Map<String, dynamic> body,
  ) async {
    final res = await http.put(
      Uri.parse("$baseUrl/profile/password"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    return res.statusCode == 200;
  }
}
