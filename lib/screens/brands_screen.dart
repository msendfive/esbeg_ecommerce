import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/brands_model.dart';
import '../models/categories_model.dart';
import '../models/products_model.dart';
import '../utilities/constants.dart';
import '../widgets/header_widget.dart';
import '../widgets/footer_widget.dart';
import '../widgets/filters_widget.dart';
import '../widgets/products_widget.dart';

// ---------------------------------------------------------------------------
// BrandsScreen — product listing filtered by a specific brand.
// Replaces: brand_page.dart  →  screens/brands_screen.dart
// ---------------------------------------------------------------------------

class BrandsScreen extends StatefulWidget {
  final String brandName;

  const BrandsScreen({super.key, required this.brandName});

  @override
  State<BrandsScreen> createState() => _BrandsScreenState();
}

class _BrandsScreenState extends State<BrandsScreen> {
  // ─── STATE ─────────────────────────────────────────────────────────────────
  // NOTE: These were incorrectly declared as global variables in the original
  // file. They are now proper instance fields of the State class.

  Brand? _currentBrand;
  bool _isLoadingBrand = true;

  int _productCount = 0;
  bool _isLoadingCount = true;

  List<Category> _categories = [];
  Map<String, dynamic>? _activeFilters;

  // ─── LIFECYCLE ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  // ─── DATA FETCHING ─────────────────────────────────────────────────────────

  Future<void> _fetchInitialData() async {
    await Future.wait([
      _fetchBrandDetails(),
      _fetchCategories(),
      _fetchProductCount(),
    ]);
  }

  Future<void> _fetchBrandDetails() async {
    try {
      final response = await http.get(Uri.parse(kBrandEndpoint));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body)['data'];
        final brandList = data.map((e) => Brand.fromJson(e)).toList();

        final match = brandList.firstWhere(
          (b) => b.name.toUpperCase() == widget.brandName.toUpperCase(),
          orElse: () => throw Exception('Brand not found'),
        );

        if (mounted) {
          setState(() {
            _currentBrand = match;
            _isLoadingBrand = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Brand Detail Error: $e');
      if (mounted) setState(() => _isLoadingBrand = false);
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
          });
        }
      }
    } catch (e) {
      debugPrint('Category Error: $e');
    }
  }

  Future<void> _fetchProductCount() async {
    try {
      final response = await http.get(Uri.parse(kProductEndpoint));
      if (response.statusCode == 200) {
        final List raw = json.decode(response.body)['data'];
        final products = raw.map((e) => Product.fromJson(e)).toList();
        final count = products
            .where(
              (p) => p.brand.toUpperCase() == widget.brandName.toUpperCase(),
            )
            .length;

        if (mounted) {
          setState(() {
            _productCount = count;
            _isLoadingCount = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Product Count Error: $e');
      if (mounted) setState(() => _isLoadingCount = false);
    }
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBgColor,
      appBar: const HeaderWidget(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: kSpaceSM),
            _Breadcrumb(label: widget.brandName),
            const SizedBox(height: kSpaceLG),
            _BrandHeader(
              brandName: widget.brandName,
              currentBrand: _currentBrand,
              isLoadingBrand: _isLoadingBrand,
              isLoadingCount: _isLoadingCount,
              productCount: _productCount,
            ),
            const SizedBox(height: kSpaceLG),
            _SectionHeader(
              onFilterResult: (result) =>
                  setState(() => _activeFilters = result),
              filterOptions: const FiltersWidget(showCategory: true),
            ),
            const SizedBox(height: kSpaceMD),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kSpaceLG),
              child: ProductsWidget(
                brandName: widget.brandName,
                filters: _activeFilters,
              ),
            ),
            const SizedBox(height: kSpaceLG),
            const FooterWidget(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

// ─── Breadcrumb ─────────────────────────────────────────────────────────────

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpaceLG),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/',
              (route) => false,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.home_outlined,
                  size: 16,
                  color: kTextSecondaryColor,
                ),
                const SizedBox(width: kSpaceXS),
                Text(
                  'Home',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: kTextSecondaryColor),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: kSpaceSM),
            child: Icon(
              Icons.chevron_right,
              size: 16,
              color: kTextSecondaryColor,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: kPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Brand header card ───────────────────────────────────────────────────────

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({
    required this.brandName,
    required this.currentBrand,
    required this.isLoadingBrand,
    required this.isLoadingCount,
    required this.productCount,
  });

  final String brandName;
  final Brand? currentBrand;
  final bool isLoadingBrand;
  final bool isLoadingCount;
  final int productCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: kSpace2XL,
        horizontal: kSpaceLG,
      ),
      margin: const EdgeInsets.symmetric(horizontal: kSpaceLG),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(kRadiusLG),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo container
          Container(
            padding: const EdgeInsets.all(kSpaceLG),
            decoration: BoxDecoration(
              color: kPrimaryColor,
              borderRadius: BorderRadius.circular(kRadiusMD),
              border: Border.all(color: kBorderColor),
            ),
            child: isLoadingBrand
                ? const SizedBox(
                    height: 60,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : currentBrand != null
                ? Image.network(
                    getBrandLogoUrl(currentBrand!.imageLogo),
                    height: 60,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.image_not_supported_outlined,
                      size: 40,
                      color: kBorderColor,
                    ),
                  )
                : const Icon(
                    Icons.business_outlined,
                    size: 40,
                    color: kBorderColor,
                  ),
          ),

          const SizedBox(height: kSpaceLG),

          // Brand name
          Text(brandName, style: Theme.of(context).textTheme.headlineSmall),

          const SizedBox(height: kSpaceMD),

          // Product count pill
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: kSpaceMD,
              vertical: kSpaceXS + 2,
            ),
            decoration: BoxDecoration(
              color: kScaffoldBgColor,
              borderRadius: BorderRadius.circular(kRadiusXL),
            ),
            child: Text(
              isLoadingCount ? 'Loading...' : '$productCount Products',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: kTextSecondaryColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section header (title + filter button) ──────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.onFilterResult,
    required this.filterOptions,
  });

  final ValueChanged<Map<String, dynamic>?> onFilterResult;
  final Widget filterOptions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpaceLG),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('All Products', style: Theme.of(context).textTheme.titleLarge),
          TextButton.icon(
            onPressed: () async {
              final result = await showModalBottomSheet<Map<String, dynamic>>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => filterOptions,
              );
              onFilterResult(result);
            },
            icon: const Icon(Icons.tune, size: 18, color: kTextSecondaryColor),
            label: Text(
              'Filter',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: kTextSecondaryColor),
            ),
          ),
        ],
      ),
    );
  }
}
