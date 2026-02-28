// import 'package:flutter/material.dart';
// import '../models/users_model.dart';
// import '../services/profiles_service.dart';

// class ProfileProvider with ChangeNotifier {
//   User? _user;
//   bool _loading = false;

//   // ================= STATE =================

//   User? get user => _user;

//   bool get isLoading => _loading;

//   bool get hasProfile => _user != null;

//   // ================= GETTERS =================
//   // 🔥 digunakan langsung oleh UI

//   String? get fullName => _user?.fullName;
//   String? get email => _user?.email;
//   String? get phone => _user?.phone;
//   String? get avatarUrl => _user?.avatarUrl;
//   String? get role => _user?.role;

//   // ================= FETCH PROFILE =================

//   Future<void> fetchProfile(String token) async {
//     try {
//       _loading = true;
//       notifyListeners();

//       final result = await ProfileService.getProfile(token);

//       if (result != null) {
//         _user = result;
//       }
//     } catch (e) {
//       debugPrint('Fetch profile error: $e');
//     } finally {
//       _loading = false;
//       notifyListeners();
//     }
//   }

//   // ================= LOCAL UPDATE =================
//   // dipakai setelah edit profile sukses

//   void updateLocal(User user) {
//     _user = user;
//     notifyListeners();
//   }

//   // ================= PATCH UPDATE =================
//   // update sebagian field tanpa reload API

//   void patch({
//     String? fullName,
//     String? email,
//     String? phone,
//     String? avatarUrl,
//   }) {
//     if (_user == null) return;

//     _user = _user!.copyWith(
//       fullName: fullName,
//       email: email,
//       phone: phone,
//       avatarUrl: avatarUrl,
//     );

//     notifyListeners();
//   }

//   // ================= CLEAR =================
//   // dipanggil saat logout

//   void clear() {
//     _user = null;
//     notifyListeners();
//   }
// }
