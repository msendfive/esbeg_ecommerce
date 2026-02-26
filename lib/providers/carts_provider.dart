// providers/cart_provider.dart

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/carts_model.dart';

class CartsProvider with ChangeNotifier {
  List<CartItem> _items = [];
  bool _isLoading = false;

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  bool get hasItems => _items.isNotEmpty;

  int get subtotal => _items.fold(0, (sum, item) => sum + item.totalPrice);
  int _voucherDiscount = 0;
  String? _voucherCode;

  int get voucherDiscount => _voucherDiscount;
  String? get voucherCode => _voucherCode;

  // ─── INITIALIZE ────────────────────────────────────────────────────────────

  Future<void> loadCart() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cartData = prefs.getString('cart');

      if (cartData != null) {
        final List<dynamic> jsonList = json.decode(cartData);
        _items = jsonList.map((json) => CartItem.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error loading cart: $e');
      _items = [];
    }

    _isLoading = false;
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

  // ─── SAVE TO STORAGE ───────────────────────────────────────────────────────

  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String cartData = json.encode(
        _items.map((item) => item.toJson()).toList(),
      );
      await prefs.setString('cart', cartData);
    } catch (e) {
      debugPrint('Error saving cart: $e');
    }
  }

  // ─── ADD TO CART ───────────────────────────────────────────────────────────

  void addToCart(CartItem newItem) {
    // Check if item already exists
    final existingIndex = _items.indexWhere((item) => item.id == newItem.id);

    if (existingIndex >= 0) {
      // Item exists, increase quantity
      _items[existingIndex].quantity += newItem.quantity;
    } else {
      // New item, add to cart
      _items.add(newItem);
    }

    _saveCart();
    notifyListeners();
  }

  // ─── REMOVE FROM CART ──────────────────────────────────────────────────────

  void removeFromCart(String itemId) {
    _items.removeWhere((item) => item.id == itemId);
    _saveCart();
    notifyListeners();
  }

  // ─── UPDATE QUANTITY ───────────────────────────────────────────────────────

  void updateQuantity(String itemId, int newQuantity) {
    if (newQuantity < 1) {
      removeFromCart(itemId);
      return;
    }

    final index = _items.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      _items[index].quantity = newQuantity;
      _saveCart();
      notifyListeners();
    }
  }

  // ─── INCREASE QUANTITY ─────────────────────────────────────────────────────

  void increaseQuantity(String itemId) {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      _items[index].quantity++;
      _saveCart();
      notifyListeners();
    }
  }

  // ─── DECREASE QUANTITY ─────────────────────────────────────────────────────

  void decreaseQuantity(String itemId) {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
        _saveCart();
        notifyListeners();
      } else {
        // If quantity is 1 and user decreases, remove item
        removeFromCart(itemId);
      }
    }
  }

  // ─── CLEAR CART ────────────────────────────────────────────────────────────

  void clearCart() {
    _items.clear();
    _saveCart();
    notifyListeners();
  }

  // ─── GET ITEM ──────────────────────────────────────────────────────────────

  CartItem? getItem(String itemId) {
    try {
      return _items.firstWhere((item) => item.id == itemId);
    } catch (e) {
      return null;
    }
  }

  // ─── CHECK IF ITEM EXISTS ──────────────────────────────────────────────────

  bool hasItem(String itemId) {
    return _items.any((item) => item.id == itemId);
  }

  // ─── GET ITEM QUANTITY ─────────────────────────────────────────────────────

  int getItemQuantity(String itemId) {
    final item = getItem(itemId);
    return item?.quantity ?? 0;
  }
}
