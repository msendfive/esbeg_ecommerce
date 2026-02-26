import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/carts_screen.dart';
import '../screens/search_screen.dart';
import '../utilities/constants.dart';
import '../providers/carts_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/menu_widget.dart';

// ---------------------------------------------------------------------------
// HeaderWidget — top AppBar used on every screen.
// Replaces: widgets/main_app_bar.dart  →  widgets/header_widget.dart
// ---------------------------------------------------------------------------

class HeaderWidget extends StatelessWidget implements PreferredSizeWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: kSurfaceColor,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: kSpaceLG,
      leadingWidth: 60,

      // ── Logo ──────────────────────────────────────────────────────────────
      leading: Padding(
        padding: const EdgeInsets.only(left: kSpaceMD),
        child: GestureDetector(
          onTap: () {
            if (ModalRoute.of(context)?.settings.name != '/') {
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            }
          },
          child: Center(
            child: Image.asset(kEsbegLogo, height: 32, fit: BoxFit.contain),
          ),
        ),
      ),

      // ── Search bar ────────────────────────────────────────────────────────
      title: SizedBox(
        height: 44,
        child: TextField(
          style: const TextStyle(fontSize: 15),
          textInputAction: TextInputAction.search,
          onSubmitted: (value) {
            if (value.trim().isEmpty) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => SearchScreen(keyword: value.trim()),
              ),
            );
          },
          decoration: InputDecoration(
            hintText: 'Search products...',
            hintStyle: const TextStyle(
              color: kTextSecondaryColor,
              fontSize: 15,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: kTextSecondaryColor,
              size: 22,
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: kSpaceLG),
            filled: true,
            fillColor: kScaffoldBgColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kRadiusSM),
              borderSide: const BorderSide(color: kBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kRadiusSM),
              borderSide: const BorderSide(color: kBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kRadiusSM),
              borderSide: const BorderSide(color: kPrimaryColor, width: 2),
            ),
          ),
        ),
      ),

      // ── Action icons ──────────────────────────────────────────────────────
      actions: [
        // Cart with badge
        Consumer<CartsProvider>(
          builder: (context, cart, _) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_bag_outlined),
                  color: kTextPrimaryColor,
                  iconSize: 24,
                  tooltip: 'Cart',
                  onPressed: () {
                    final auth = context.read<AuthProvider>();
                    if (!auth.isLoggedIn) {
                      _showLoginSheet(context);
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartsScreen()),
                    );
                  },
                ),
                if (cart.itemCount > 0)
                  Positioned(
                    right: kSpaceSM,
                    top: kSpaceSM,
                    child: Container(
                      padding: const EdgeInsets.all(kSpaceXS),
                      decoration: const BoxDecoration(
                        color: kErrorColor,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${cart.itemCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),

        const SizedBox(width: kSpaceXS),

        // Notifications
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          color: kTextPrimaryColor,
          iconSize: 24,
          tooltip: 'Notifications',
          onPressed: () {
            // TODO: navigate to notifications screen when created
          },
        ),

        const SizedBox(width: kSpaceXS),

        // Menu
        IconButton(
          icon: const Icon(Icons.menu_rounded),
          color: kTextPrimaryColor,
          iconSize: 26,
          tooltip: 'Menu',
          onPressed: () => showMenuBottomSheet(context),
        ),

        const SizedBox(width: kSpaceSM),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Shows the login bottom sheet. Kept here to avoid a dependency on a
  /// standalone login_sheet.dart that may live elsewhere in the old structure.
  void _showLoginSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _LoginPromptSheet(),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// ---------------------------------------------------------------------------
// _LoginPromptSheet — minimal prompt redirecting to the login screen.
// Replace the body with the real LoginScreen widget when it is ready.
// ---------------------------------------------------------------------------

class _LoginPromptSheet extends StatelessWidget {
  const _LoginPromptSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: kSpaceXL,
        right: kSpaceXL,
        top: kSpace2XL,
        bottom: MediaQuery.of(context).viewInsets.bottom + kSpace2XL,
      ),
      decoration: const BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(kRadiusXL)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: kBorderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: kSpace2XL),
          const Icon(Icons.lock_outline, size: 48, color: kPrimaryColor),
          const SizedBox(height: kSpaceLG),
          Text(
            'Login Required',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: kSpaceSM),
          Text(
            'Please log in to view your cart.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: kSpace2XL),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/login');
              },
              child: const Text('Login'),
            ),
          ),
        ],
      ),
    );
  }
}
