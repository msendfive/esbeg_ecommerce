import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../utilities/constants.dart';
import '../models/products_model.dart'; // File model Product Anda

class ApiService {
  Future<List<Product>> getProducts() async {
    try {
      final response = await http.get(Uri.parse(kProductEndpoint));

      if (response.statusCode == 200) {
        // JSON Server mengembalikan List jika diakses ke /api/product
        List<dynamic> body = jsonDecode(response.body);

        return body.map((item) => Product.fromJson(item)).toList();
      } else {
        debugPrint("Error: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Exception: $e");
      return [];
    }
  }
}
