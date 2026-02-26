import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/addresses_model.dart';
import '../services/addresses_service.dart';

class AddressesProvider with ChangeNotifier {
  List<Address> _addresses = [];
  bool _loading = false;

  final String _baseUrl = "http://192.168.2.35:8000/api";

  // ================= GETTERS =================
  List<Address> get addresses => _addresses;
  bool get loading => _loading;

  // ================= FETCH =================
  Future<void> loadAddresses(String token) async {
    _setLoading(true);

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/addresses'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final List<dynamic> listData = data['data'] ?? data;

        _addresses = listData.map((e) => Address.fromJson(e)).toList();
      } else {
        debugPrint("Load Address Failed: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Address Error: $e");
    } finally {
      _setLoading(false);
    }
  }

  // ================= ADD =================
  Future<bool> addAddress(String token, Map<String, dynamic> data) async {
    _setLoading(true);

    try {
      final success = await AddressService.createAddress(token, data);

      if (success) {
        await loadAddresses(token);
      }

      return success;
    } catch (e) {
      debugPrint("Add Address Error: $e");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ================= UPDATE =================
  Future<bool> updateAddress(
    String token,
    String id,
    Map<String, dynamic> data,
  ) async {
    _setLoading(true);

    try {
      final success = await AddressService.updateAddress(token, id, data);

      if (success) {
        await loadAddresses(token);
      }

      return success;
    } catch (e) {
      debugPrint("Update Address Error: $e");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ================= DELETE =================
  Future<bool> deleteAddress(String token, String id) async {
    try {
      final success = await AddressService.deleteAddress(token, id);

      if (success) {
        _addresses.removeWhere((a) => a.addressId == id);
        notifyListeners();
      }

      return success;
    } catch (e) {
      debugPrint("Delete Address Error: $e");
      return false;
    }
  }

  // ================= HELPERS =================
  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void clear() {
    _addresses = [];
    notifyListeners();
  }
}
