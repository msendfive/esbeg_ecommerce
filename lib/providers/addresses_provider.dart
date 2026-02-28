import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/addresses_model.dart';
import '../services/addresses_service.dart';

class AddressesProvider with ChangeNotifier {
  List<Address> _addresses = [];
  bool _loading = false;

  static const String _baseUrl = 'http://192.168.2.35:8000/api';

  // ── Getters ────────────────────────────────────────────────────────────────

  List<Address> get addresses => _addresses;
  bool get loading => _loading;

  Address? get defaultAddress =>
      _addresses.where((a) => a.isDefault).firstOrNull;

  // ── Load ───────────────────────────────────────────────────────────────────

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
        final List<dynamic> list = data['data'] is List
            ? data['data']
            : data is List
            ? data
            : [];
        _addresses = list.map((e) => Address.fromJson(e)).toList();
      } else {
        debugPrint('Load Address Failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Address Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ── Add ────────────────────────────────────────────────────────────────────

  Future<bool> addAddress(String token, Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final success = await AddressService.createAddress(token, data);
      if (success) await loadAddresses(token);
      return success;
    } catch (e) {
      debugPrint('Add Address Error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Update ─────────────────────────────────────────────────────────────────
  // FIX: AddressService.updateAddress returns Map<String, dynamic>? (not bool).
  // We treat non-null as success and update local state from the returned JSON
  // so the UI refreshes instantly without a round-trip loadAddresses() call.

  Future<bool> updateAddress(
    String token,
    String id,
    Map<String, dynamic> data,
  ) async {
    _setLoading(true);
    try {
      final updated = await AddressService.updateAddress(token, id, data);

      if (updated != null) {
        final index = _addresses.indexWhere((a) => a.addressId == id);
        if (index != -1) {
          // Prefer values from the server response; fall back to submitted data,
          // then the old local value — in that priority order.
          final old = _addresses[index];
          _addresses[index] = Address(
            addressId: old.addressId,
            label:
                _str(updated['label']) ??
                data['label']?.toString() ??
                old.label,
            receiverName:
                _str(updated['receiver_name']) ??
                data['receiver_name']?.toString() ??
                old.receiverName,
            phone:
                _str(updated['phone']) ??
                data['phone']?.toString() ??
                old.phone,
            addressLine:
                _str(updated['address_line']) ??
                data['address_line']?.toString() ??
                old.addressLine,
            province:
                _str(updated['province']) ??
                data['province']?.toString() ??
                old.province,
            provinceId:
                _str(updated['province_id']) ??
                data['province_id']?.toString() ??
                old.provinceId,
            city: _str(updated['city']) ?? data['city']?.toString() ?? old.city,
            cityId:
                _str(updated['city_id']) ??
                data['city_id']?.toString() ??
                old.cityId,
            district:
                _str(updated['district']) ??
                data['district']?.toString() ??
                old.district,
            districtId:
                _str(updated['district_id']) ??
                data['district_id']?.toString() ??
                old.districtId,
            subdistrict:
                _str(updated['subdistrict']) ??
                data['subdistrict']?.toString() ??
                old.subdistrict,
            subdistrictId:
                _str(updated['subdistrict_id']) ??
                data['subdistrict_id']?.toString() ??
                old.subdistrictId,
            postalCode:
                _str(updated['postal_code']) ??
                data['postal_code']?.toString() ??
                old.postalCode,
            rt: _str(updated['rt']) ?? data['rt']?.toString() ?? old.rt,
            rw: _str(updated['rw']) ?? data['rw']?.toString() ?? old.rw,
            isDefault: updated['is_default'] != null
                ? _parseBool(updated['is_default'])
                : (data['is_default'] != null
                      ? _parseBool(data['is_default'])
                      : old.isDefault),
          );
        }
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Update Address Error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<bool> deleteAddress(String token, String id) async {
    try {
      final success = await AddressService.deleteAddress(token, id);
      if (success) {
        _addresses.removeWhere((a) => a.addressId == id);
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Delete Address Error: $e');
      return false;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void clear() {
    _addresses = [];
    notifyListeners();
  }

  /// Returns the string value only if non-null and non-empty; otherwise null.
  static String? _str(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    return s.isNotEmpty ? s : null;
  }

  static bool _parseBool(dynamic v) {
    if (v is bool) return v;
    if (v is int) return v == 1;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return false;
  }
}
