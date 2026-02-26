import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;

  bool get isLoggedIn => _token != null;

  String? get token => _token;

  String? get name =>
      _user?['name'] ?? _user?['username'] ?? _user?['full_name'];
  String? get email => _user?['email'];
  String? get phone => _user?['phone'];
  String? get role => _user?['role'];

  Map<String, dynamic>? get user => _user;

  void login({required String token, required Map<String, dynamic> user}) {
    _token = token;
    _user = user;
    notifyListeners();
  }

  void logout() {
    _token = null;
    _user = null;
    notifyListeners();
  }
}
