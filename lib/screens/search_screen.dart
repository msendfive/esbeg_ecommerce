import 'package:flutter/material.dart';

import '../utilities/constants.dart';
import '../widgets/header_widget.dart';
import '../widgets/footer_widget.dart';
import '../widgets/products_widget.dart';

// ---------------------------------------------------------------------------
// SearchScreen — displays product search results for a given keyword.
// Replaces: product_search_page.dart  →  screens/search_screen.dart
// ---------------------------------------------------------------------------

class SearchScreen extends StatelessWidget {
  final String keyword;

  const SearchScreen({super.key, required this.keyword});

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

            // Breadcrumb: Home › Search
            _Breadcrumb(),

            const SizedBox(height: kSpaceLG),

            // Logo banner card
            _LogoBanner(),

            const SizedBox(height: kSpace2XL),

            // "Search Results" heading + keyword subtitle
            _TitleSection(keyword: keyword),

            const SizedBox(height: kSpaceLG),

            // Product grid filtered by keyword
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kSpaceLG),
              child: ProductsWidget(searchKeyword: keyword),
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: kTextSecondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
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
            'Search',
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

// ─── Logo banner ────────────────────────────────────────────────────────────

class _LogoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 120,
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
      alignment: Alignment.center,
      child: Image.asset(kEsbegLogo, height: 60, fit: BoxFit.contain),
    );
  }
}

// ─── Title section ───────────────────────────────────────────────────────────

class _TitleSection extends StatelessWidget {
  const _TitleSection({required this.keyword});

  final String keyword;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpaceLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Search Results', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: kSpaceXS),
          Text(
            'Showing results for "$keyword"',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: kTextSecondaryColor),
          ),
        ],
      ),
    );
  }
}
