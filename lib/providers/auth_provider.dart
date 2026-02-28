import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;

  // ================= GETTERS =================

  bool get isLoggedIn => _token != null;

  String? get token => _token;

  String? get name => _user?['full_name'];
  String? get email => _user?['email'];
  String? get phone => _user?['phone'];
  String? get role => _user?['role'];
  String? get avatarUrl => _user?['avatar_url'];

  Map<String, dynamic>? get user => _user;

  // ================= AUTH =================

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

  // ================= UPDATE PROFILE =================

  void updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
    String? email,
  }) {
    if (_user == null) return;

    _user = Map<String, dynamic>.from(_user!);

    if (name != null) {
      _user!['full_name'] = name;
    }

    if (phone != null) {
      _user!['phone'] = phone;
    }

    if (avatarUrl != null) {
      _user!['avatar_url'] = avatarUrl;
    }

    if (email != null) {
      _user!['email'] = email;
    }

    notifyListeners();
  }
}
