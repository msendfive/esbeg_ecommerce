import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/orders_model.dart';
import '../utilities/constants.dart';

// ---------------------------------------------------------------------------
// OrdersProvider
// ---------------------------------------------------------------------------

class OrdersProvider extends ChangeNotifier {
  List<Order> _orders = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  // ── Getters ────────────────────────────────────────────────────────────────

  List<Order> get orders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  bool get hasOrders => _orders.isNotEmpty;

  List<Order> get activeOrders => _orders
      .where(
        (o) =>
            o.status != OrderStatus.delivered &&
            o.status != OrderStatus.cancelled,
      )
      .toList();

  List<Order> get completedOrders => _orders
      .where(
        (o) =>
            o.status == OrderStatus.delivered ||
            o.status == OrderStatus.cancelled,
      )
      .toList();

  // ── GET /orders ────────────────────────────────────────────────────────────

  Future<void> loadOrders(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/orders'),
        headers: _headers(token),
      );

      debugPrint('loadOrders [${response.statusCode}]: ${response.body}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        // Support both array root and { data: [...] } wrapper
        final List raw = body is List
            ? body
            : (body['data'] as List? ?? body['orders'] as List? ?? []);

        _orders = raw
            .map((e) => Order.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

        // Most recent first
        _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } else {
        _error = _parseError(response.body, response.statusCode);
      }
    } catch (e) {
      debugPrint('loadOrders error: $e');
      _error = 'Failed to load orders. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── POST /orders ───────────────────────────────────────────────────────────

  /// Creates a new order from the current cart.
  ///
  /// Returns the created [Order] on success, or `null` on failure.
  /// On failure, [error] is set with a human-readable message.
  Future<Order?> createOrder({
    required String token,
    required int shippingAddressId,
    String? voucherCode,
    String paymentMethod = 'transfer',
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        'shipping_address_id': shippingAddressId,
        'payment_method': paymentMethod,
        if (voucherCode != null && voucherCode.isNotEmpty)
          'voucher_code': voucherCode,
      };

      final response = await http.post(
        Uri.parse('$kBaseUrl/orders'),
        headers: _headers(token),
        body: jsonEncode(body),
      );

      debugPrint('createOrder [${response.statusCode}]: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // Support { order: {...} } or { data: {...} } or raw object
        final orderJson = data['order'] ?? data['data'] ?? data;
        final order = Order.fromJson(
          Map<String, dynamic>.from(orderJson as Map),
        );

        // Prepend to list (most recent first)
        _orders = [order, ..._orders];
        notifyListeners();
        return order;
      } else {
        _error = _parseError(response.body, response.statusCode);
        notifyListeners();
        return null;
      }
    } catch (e) {
      debugPrint('createOrder error: $e');
      _error = 'Failed to place order. Please try again.';
      notifyListeners();
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };

  String _parseError(String body, int statusCode) {
    try {
      final data = jsonDecode(body);
      if (data is Map) {
        // Laravel validation errors: { errors: { field: ["msg"] } }
        if (data['errors'] is Map) {
          return (data['errors'] as Map).values.first[0]?.toString() ??
              'Validation failed';
        }
        return data['message']?.toString() ?? 'Error $statusCode';
      }
    } catch (_) {}
    return 'Error $statusCode';
  }
}
