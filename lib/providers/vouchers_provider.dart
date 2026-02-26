import 'package:flutter/material.dart';
import '../models/vouchers_model.dart';
import '../services/vouchers_service.dart';

class VouchersProvider with ChangeNotifier {
  List<Voucher> _vouchers = [];
  bool _loading = false;

  List<Voucher> get vouchers => _vouchers;
  bool get loading => _loading;

  Future<void> loadVouchers(String token) async {
    // Tambahkan parameter token
    _loading = true;
    notifyListeners();

    try {
      // Pastikan VoucherService.fetchVouchers juga menerima token
      final data = await VoucherService.fetchVouchers(token);

      _vouchers = data.map<Voucher>((e) => Voucher.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Error Voucher: ${e.toString()}");
    }

    _loading = false;
    notifyListeners();
  }
}
