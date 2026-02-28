import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/carts_model.dart';
import '../utilities/constants.dart';

class CartsProvider with ChangeNotifier {
  List<CartItem> _items = [];
  int _subtotal = 0;
  bool _isLoading = false;
  String? _error;
  bool _sessionExpired = false;

  int _voucherDiscount = 0;
  String? _voucherCode;

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  bool get hasItems => _items.isNotEmpty;
  String? get error => _error;
  int get itemCount => _items.fold(0, (s, i) => s + i.quantity);
  int get subtotal => _subtotal;
  int get voucherDiscount => _voucherDiscount;
  String? get voucherCode => _voucherCode;
  bool get sessionExpired => _sessionExpired;

  void clearSessionExpired() {
    _sessionExpired = false;
    notifyListeners();
  }

  void applyVoucher({required String code, required int discount}) {
    _voucherCode = code;
    _voucherDiscount = discount;
    notifyListeners();
  }

  void removeVoucher() {
    _voucherCode = null;
    _voucherDiscount = 0;
    notifyListeners();
  }

  Future<void> loadCart(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await http.get(
        Uri.parse('$kBaseUrl/api/cart'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final itemsList = data['items'] as List? ?? [];
        _items = itemsList
            .map((e) => CartItem.fromApiJson(e as Map<String, dynamic>))
            .toList();
        _subtotal = (data['subtotal'] as num?)?.toInt() ?? _computeSubtotal();
      } else {
        _error = _parseError(res.body, 'Failed to load cart');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('loadCart error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addToCart({
    required int variantId,
    required int qty, // renamed: was 'quantity'
    required String token,
  }) async {
    try {
      final addRes = await http.post(
        Uri.parse('$kBaseUrl/api/cart/items'),
        headers: _headers(token),
        body: jsonEncode({
          'variant_id': variantId,
          'qty': qty,
        }), // ✅ qty included
      );

      debugPrint('addToCart [${addRes.statusCode}]: ${addRes.body}');

      debugPrint('addToCart status: \${addRes.statusCode}');
      debugPrint('addToCart body: \${addRes.body}');

      if (addRes.statusCode == 401) {
        _sessionExpired = true;
        _error = 'Session expired. Please log in again.';
        notifyListeners();
        return false;
      }

      if (addRes.statusCode != 200 && addRes.statusCode != 201) {
        _error = _parse422Error(addRes.body);
        notifyListeners();
        return false;
      }

      await loadCart(token);
      return true;
    } catch (e) {
      debugPrint('addToCart error: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateQuantity({
    required int cartItemId,
    required int qty,
    required String token,
  }) async {
    if (qty < 1) return removeFromCart(cartItemId: cartItemId, token: token);

    final idx = _items.indexWhere((i) => i.cartItemId == cartItemId);
    int? prevQty;
    if (idx >= 0) {
      prevQty = _items[idx].quantity;
      _items[idx] = _items[idx].copyWith(quantity: qty);
      _subtotal = _computeSubtotal();
      notifyListeners();
    }

    try {
      final res = await http.put(
        Uri.parse('$kBaseUrl/api/cart/items/$cartItemId'),
        headers: _headers(token),
        body: jsonEncode({'qty': qty}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['subtotal'] != null) {
          _subtotal = (data['subtotal'] as num).toInt();
          notifyListeners();
        }
        return true;
      }

      if (idx >= 0 && prevQty != null) {
        _items[idx] = _items[idx].copyWith(quantity: prevQty);
        _subtotal = _computeSubtotal();
        notifyListeners();
      }
      return false;
    } catch (e) {
      debugPrint('updateQuantity error: $e');
      if (idx >= 0 && prevQty != null) {
        _items[idx] = _items[idx].copyWith(quantity: prevQty);
        _subtotal = _computeSubtotal();
        notifyListeners();
      }
      return false;
    }
  }

  Future<bool> removeFromCart({
    required int cartItemId,
    required String token,
  }) async {
    final idx = _items.indexWhere((i) => i.cartItemId == cartItemId);
    CartItem? removed;
    if (idx >= 0) {
      removed = _items[idx];
      _items.removeAt(idx);
      _subtotal = _computeSubtotal();
      notifyListeners();
    }

    try {
      final res = await http.delete(
        Uri.parse('$kBaseUrl/api/cart/items/$cartItemId'),
        headers: _headers(token),
      );

      if (res.statusCode == 200 || res.statusCode == 204) return true;

      if (removed != null) {
        _items.insert(idx < 0 ? _items.length : idx, removed);
        _subtotal = _computeSubtotal();
        notifyListeners();
      }
      return false;
    } catch (e) {
      debugPrint('removeFromCart error: $e');
      if (removed != null) {
        _items.insert(idx < 0 ? _items.length : idx, removed);
        _subtotal = _computeSubtotal();
        notifyListeners();
      }
      return false;
    }
  }

  Future<void> increaseQuantity(int cartItemId, String token) async {
    final item = _items.firstWhere(
      (i) => i.cartItemId == cartItemId,
      orElse: () => throw StateError('Item $cartItemId not found'),
    );
    await updateQuantity(
      cartItemId: cartItemId,
      qty: item.quantity + 1,
      token: token,
    );
  }

  Future<void> decreaseQuantity(int cartItemId, String token) async {
    final item = _items.firstWhere(
      (i) => i.cartItemId == cartItemId,
      orElse: () => throw StateError('Item $cartItemId not found'),
    );
    if (item.quantity <= 1) {
      await removeFromCart(cartItemId: cartItemId, token: token);
    } else {
      await updateQuantity(
        cartItemId: cartItemId,
        qty: item.quantity - 1,
        token: token,
      );
    }
  }

  Future<bool> removeFromCartById(String itemId, String token) async {
    final cartItemId = int.tryParse(itemId);
    if (cartItemId == null) return false;
    return removeFromCart(cartItemId: cartItemId, token: token);
  }

  void clearCart() {
    _items = [];
    _subtotal = 0;
    _voucherCode = null;
    _voucherDiscount = 0;
    _error = null;
    notifyListeners();
  }

  bool hasItemByVariant(int variantId) =>
      _items.any((i) => i.variantId == variantId);

  int getQuantityByVariant(int variantId) {
    try {
      return _items.firstWhere((i) => i.variantId == variantId).quantity;
    } catch (_) {
      return 0;
    }
  }

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };

  int _computeSubtotal() => _items.fold(0, (sum, i) => sum + i.totalPrice);

  String _parseError(String body, String fallback) {
    try {
      return (jsonDecode(body) as Map)['message']?.toString() ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  /// Surfaces Laravel validation errors (422) as a readable string.
  String _parse422Error(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      if (json.containsKey('errors')) {
        final errors = json['errors'] as Map<String, dynamic>;
        return errors.values
            .expand<dynamic>((v) => v is List ? v : [v])
            .map((e) => e.toString())
            .join('\n');
      }
      return json['message']?.toString() ?? 'Request failed';
    } catch (_) {
      return 'Request failed';
    }
  }
}
