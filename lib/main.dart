import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/carts_provider.dart';
import 'providers/auth_provider.dart'; // ✅ TAMBAH INI

import 'screens/home_screen.dart';
import 'screens/carts_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'providers/addresses_provider.dart';
import 'providers/vouchers_provider.dart';
import 'screens/orders_screen.dart';
import '../utilities/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AddressesProvider()),
        ChangeNotifierProvider(create: (_) => VouchersProvider()),
      ],
      child: MaterialApp(
        title: 'E-Commerce App',
        theme: AppTheme.light,
        home: const HomeScreen(),
        routes: {
          '/cart': (context) => const CartsScreen(),
          '/checkout': (context) => const CheckoutScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/orders': (context) => const OrdersScreen(),
        },
      ),
    );
  }
}
