import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/brands_model.dart';
import '../models/categories_model.dart';
import '../providers/auth_provider.dart';
import '../providers/carts_provider.dart';
import '../providers/addresses_provider.dart';
import '../screens/carts_screen.dart';
import '../screens/brands_screen.dart';
import '../screens/categories_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/register_screen.dart';
import '../utilities/constants.dart';

// ---------------------------------------------------------------------------
// showMenuBottomSheet — global helper called from HeaderWidget.
// Replaces: menu_sheet.dart  →  widgets/menu_widget.dart
// ---------------------------------------------------------------------------

void showMenuBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag: true,
    builder: (_) => const _MenuSheet(),
  );
}

// ---------------------------------------------------------------------------
// _MenuSheet — private; only exposed via showMenuBottomSheet().
// ---------------------------------------------------------------------------

class _MenuSheet extends StatefulWidget {
  const _MenuSheet();

  @override
  State<_MenuSheet> createState() => _MenuSheetState();
}

class _MenuSheetState extends State<_MenuSheet>
    with SingleTickerProviderStateMixin {
  // ─── STATE ─────────────────────────────────────────────────────────────────

  String? _expandedSection;

  List<Brand> _brands = [];
  List<Category> _categories = [];
  bool _isBrandLoading = true;
  bool _isCategoryLoading = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ─── LIFECYCLE ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _animController.forward();
    _fetchBrands();
    _fetchCategories();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ─── DATA FETCHING ─────────────────────────────────────────────────────────

  Future<void> _fetchBrands() async {
    try {
      final response = await http.get(Uri.parse(kBrandEndpoint));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body)['data'];
        if (mounted) {
          setState(() {
            _brands = data.map((e) => Brand.fromJson(e)).toList();
            _isBrandLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Brand fetch error: $e');
      if (mounted) setState(() => _isBrandLoading = false);
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(Uri.parse(kCategoryEndpoint));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body)['data'];
        if (mounted) {
          setState(() {
            _categories = data.map((e) => Category.fromJson(e)).toList();
            _isCategoryLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Category fetch error: $e');
      if (mounted) setState(() => _isCategoryLoading = false);
    }
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: kScaffoldBgColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(kSpace2XL)),
        ),
        child: Column(
          children: [
            _DragHandle(),
            _Header(onClose: () => Navigator.pop(context)),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      kSpaceXL,
                      0,
                      kSpaceXL,
                      kSpaceXL,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _WelcomeCard(),
                        const SizedBox(height: kSpace2XL),
                        _QuickActions(),
                        const SizedBox(height: kSpace2XL),
                        _SectionTitle(title: 'Shop by'),
                        const SizedBox(height: kSpaceMD),
                        _ExpandableSection(
                          title: 'Categories',
                          icon: Icons.category_outlined,
                          isLoading: _isCategoryLoading,
                          isExpanded: _expandedSection == 'categories',
                          itemCount: _categories.length,
                          onToggle: () => setState(() {
                            _expandedSection = _expandedSection == 'categories'
                                ? null
                                : 'categories';
                          }),
                          itemBuilder: (i) => _ListItem(
                            name: _categories[i].name,
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CategoriesScreen(
                                    categoryName: _categories[i].name,
                                    categoryId: _categories[i].id,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: kSpaceMD),
                        _ExpandableSection(
                          title: 'Brands',
                          icon: Icons.label_outline,
                          isLoading: _isBrandLoading,
                          isExpanded: _expandedSection == 'brands',
                          itemCount: _brands.length,
                          onToggle: () => setState(() {
                            _expandedSection = _expandedSection == 'brands'
                                ? null
                                : 'brands';
                          }),
                          itemBuilder: (i) => _ListItem(
                            name: _brands[i].name,
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      BrandsScreen(brandName: _brands[i].name),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: kSpace2XL),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _BottomActions(onLogout: () => _showLogoutDialog(context)),
          ],
        ),
      ),
    );
  }

  // ─── LOGOUT DIALOG ─────────────────────────────────────────────────────────

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusLG),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final auth = context.read<AuthProvider>();
              final cart = context.read<CartsProvider>();
              final address = context.read<AddressesProvider>();

              auth.logout();
              cart.clearCart();
              address.clear();

              Navigator.pop(context); // close dialog
              Navigator.pop(context); // close menu sheet
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logged out successfully'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kErrorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

// ─── Drag handle ────────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: kSpaceMD, bottom: kSpaceSM),
    width: 40,
    height: 4,
    decoration: BoxDecoration(
      color: kBorderColor,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

// ─── Header ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(kSpaceXL, kSpaceSM, kSpaceLG, kSpaceLG),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Menu', style: Theme.of(context).textTheme.headlineSmall),
        IconButton(
          icon: const Icon(Icons.close, size: 24),
          onPressed: onClose,
          style: IconButton.styleFrom(
            backgroundColor: kSurfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kRadiusMD - 2),
            ),
          ),
        ),
      ],
    ),
  );
}

// ─── Welcome card (shown only when logged in) ────────────────────────────────

class _WelcomeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (_, auth, _) {
        // ✅ __ not _
        if (!auth.isLoggedIn) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(kSpaceLG),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [kPrimaryColor, Color(0xFF26D0CE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(kRadiusLG),
            boxShadow: [
              BoxShadow(
                color: kPrimaryColor.withValues(alpha: 0.30),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 28),
              ),
              const SizedBox(width: kSpaceLG),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back!',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: kSpaceXS),
                    Text(
                      auth.name ?? 'User',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Quick actions ───────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (_, auth, _) => Row(
        // ✅ __ not _
        children: [
          Expanded(
            child: _ActionCard(
              icon: Icons.bolt,
              label: 'Flash Sale',
              color: Colors.orange,
              onTap: () => Navigator.pop(context),
            ),
          ),
          if (auth.isLoggedIn) ...[
            const SizedBox(width: kSpaceMD),
            Expanded(
              child: _ActionCard(
                icon: Icons.shopping_bag_outlined,
                label: 'My Orders',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartsScreen()),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: kSurfaceColor,
    borderRadius: BorderRadius.circular(kRadiusLG),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kRadiusLG),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: kSpaceLG),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: kSpaceSM),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: kTextPrimaryColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}

// ─── Section title ───────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) =>
      Text(title, style: Theme.of(context).textTheme.titleMedium);
}

// ─── Expandable section ──────────────────────────────────────────────────────

class _ExpandableSection extends StatelessWidget {
  const _ExpandableSection({
    required this.title,
    required this.icon,
    required this.isLoading,
    required this.isExpanded,
    required this.itemCount,
    required this.onToggle,
    required this.itemBuilder,
  });

  final String title;
  final IconData icon;
  final bool isLoading;
  final bool isExpanded;
  final int itemCount;
  final VoidCallback onToggle;
  final Widget Function(int) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: kSurfaceColor,
          borderRadius: BorderRadius.circular(kRadiusLG),
          child: InkWell(
            onTap: isLoading ? null : onToggle,
            borderRadius: BorderRadius.circular(kRadiusLG),
            child: Padding(
              padding: const EdgeInsets.all(kSpaceLG),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(kRadiusMD - 2),
                    ),
                    child: Icon(icon, size: 20, color: kPrimaryColor),
                  ),
                  const SizedBox(width: kSpaceMD),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  if (isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: kBorderColor,
                      ),
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (itemCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: kSpaceSM,
                              vertical: kSpaceXS,
                            ),
                            decoration: BoxDecoration(
                              color: kScaffoldBgColor,
                              borderRadius: BorderRadius.circular(kRadiusSM),
                            ),
                            child: Text(
                              '$itemCount',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: kTextSecondaryColor),
                            ),
                          ),
                        const SizedBox(width: kSpaceSM),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            Icons.keyboard_arrow_down,
                            color: kTextSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: isExpanded
              ? Container(
                  margin: const EdgeInsets.only(top: kSpaceSM),
                  decoration: BoxDecoration(
                    color: kSurfaceColor,
                    borderRadius: BorderRadius.circular(kRadiusLG),
                  ),
                  child: itemCount == 0
                      ? Padding(
                          padding: const EdgeInsets.all(kSpaceXL),
                          child: Center(
                            child: Text(
                              'No ${title.toLowerCase()} available',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: kTextSecondaryColor),
                            ),
                          ),
                        )
                      : Column(
                          children: List.generate(
                            itemCount,
                            (i) => itemBuilder(i),
                          ),
                        ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ─── List item ───────────────────────────────────────────────────────────────

class _ListItem extends StatelessWidget {
  const _ListItem({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: kSpaceLG,
          vertical: kSpaceMD + 2,
        ),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: kScaffoldBgColor)),
        ),
        child: Row(
          children: [
            const SizedBox(width: kSpaceSM),
            Expanded(
              child: Text(
                name,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: kTextSecondaryColor),
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: kBorderColor),
          ],
        ),
      ),
    ),
  );
}

// ─── Bottom action buttons ───────────────────────────────────────────────────

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kSpaceXL),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (_, auth, _) {
            // ✅ __ not _
            if (auth.isLoggedIn) {
              return Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_outline, size: 20),
                      label: const Text('My Profile'),
                    ),
                  ),
                  const SizedBox(width: kSpaceMD),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onLogout,
                      icon: const Icon(Icons.logout, size: 20),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kErrorColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              );
            }

            // Guest buttons
            return Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const RegisterScreen(), // ✅ uncommented
                      );
                    },
                    child: const Text('Sign Up'),
                  ),
                ),
                const SizedBox(width: kSpaceMD),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/login');
                    },
                    child: const Text('Login'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
