import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/categories_model.dart';
import '../models/products_model.dart';
import '../utilities/constants.dart';
import '../widgets/header_widget.dart';
import '../widgets/footer_widget.dart';
import '../widgets/filters_widget.dart';
import '../widgets/products_widget.dart';

// ---------------------------------------------------------------------------
// CategoriesScreen — product listing filtered by a specific category.
// Replaces: category_page.dart  →  screens/categories_screen.dart
// ---------------------------------------------------------------------------

class CategoriesScreen extends StatefulWidget {
  final String categoryName;
  final int categoryId;

  const CategoriesScreen({
    super.key,
    required this.categoryName,
    required this.categoryId,
  });

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  // ─── STATE ─────────────────────────────────────────────────────────────────

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
    await Future.wait([_fetchCategories(), _fetchProductCount()]);
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
      debugPrint('Category Fetch Error: $e');
    }
  }

  Future<void> _fetchProductCount() async {
    try {
      final response = await http.get(Uri.parse(kProductEndpoint));
      if (response.statusCode == 200) {
        final List raw = json.decode(response.body)['data'];
        final count = raw
            .map((e) => Product.fromJson(e))
            .where((p) => p.categoryId == widget.categoryId)
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
            _Breadcrumb(label: widget.categoryName),
            const SizedBox(height: kSpaceLG),
            _CategoryHeader(
              categoryName: widget.categoryName,
              isLoadingCount: _isLoadingCount,
              productCount: _productCount,
            ),
            const SizedBox(height: kSpaceLG),
            _SectionHeader(
              onFilterResult: (result) =>
                  setState(() => _activeFilters = result),
              filterOptions: const FiltersWidget(showBrand: true),
            ),
            const SizedBox(height: kSpaceMD),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kSpaceLG),
              child: ProductsWidget(
                categoryId: widget.categoryId,
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

// ─── Category header card ────────────────────────────────────────────────────

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({
    required this.categoryName,
    required this.isLoadingCount,
    required this.productCount,
  });

  final String categoryName;
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
          // Category name
          Text(
            categoryName,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),

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
