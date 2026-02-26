import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/brands_model.dart';
import '../models/categories_model.dart';
import '../screens/brands_screen.dart';
import '../screens/categories_screen.dart';
import '../utilities/constants.dart';
import '../widgets/header_widget.dart';
import '../widgets/footer_widget.dart';
import '../widgets/products_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ─── STATE ─────────────────────────────────────────────────────────────────

  List<Brand> _brands = [];
  bool _isBrandLoading = true;

  List<Category> _categories = [];
  bool _isCategoryLoading = true;

  // ─── BANNER ────────────────────────────────────────────────────────────────

  late PageController _bannerController;
  int _currentBanner = 0;
  final List<String> _banners = const [
    'assets/images/banner1.png',
    'assets/images/banner2.png',
    'assets/images/banner3.png',
  ];

  // ─── LIFECYCLE ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _bannerController = PageController();
    _startAutoSlide();
    _fetchBrands();
    _fetchCategories();
  }

  @override
  void dispose() {
    _bannerController.dispose();
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
      debugPrint('BRAND ERROR: $e');
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
      debugPrint('CATEGORY ERROR: $e');
      if (mounted) setState(() => _isCategoryLoading = false);
    }
  }

  // ─── BANNER AUTO-SLIDE ─────────────────────────────────────────────────────

  void _startAutoSlide() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      if (_bannerController.hasClients) {
        _currentBanner = (_currentBanner + 1) % _banners.length;
        _bannerController.animateToPage(
          _currentBanner,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
      _startAutoSlide();
    });
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
            const SizedBox(height: kSpaceXL),
            _BannerCarousel(
              banners: _banners,
              controller: _bannerController,
              currentBanner: _currentBanner,
              onPageChanged: (i) => setState(() => _currentBanner = i),
            ),
            const SizedBox(height: kSpace3XL),
            _CategorySection(
              isLoading: _isCategoryLoading,
              categories: _categories,
            ),
            const SizedBox(height: kSpace3XL),
            _BrandSection(isLoading: _isBrandLoading, brands: _brands),
            const SizedBox(height: kSpace3XL),
            _ProductSection(),
            const SizedBox(height: kSpace2XL),
            const FooterWidget(),
          ],
        ),
      ),
    );
  }
}

// ─── BANNER CAROUSEL ───────────────────────────────────────────────────────────

class _BannerCarousel extends StatelessWidget {
  const _BannerCarousel({
    required this.banners,
    required this.controller,
    required this.currentBanner,
    required this.onPageChanged,
  });

  final List<String> banners;
  final PageController controller;
  final int currentBanner;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: controller,
            itemCount: banners.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: kSpaceXL),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(kRadiusXL),
                child: Image.asset(
                  banners[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: kSpaceLG),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            banners.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: kSpaceXS),
              width: currentBanner == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: currentBanner == index ? kPrimaryColor : kBorderColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── CATEGORY SECTION ──────────────────────────────────────────────────────────

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.isLoading, required this.categories});

  final bool isLoading;
  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        kSectionHeader('Shop by Category'),
        const SizedBox(height: kSpaceLG),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: kSpaceXL),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (categories.isEmpty)
          const SizedBox.shrink()
        else
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: kSpaceXL),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Container(
                  margin: const EdgeInsets.only(right: kSpaceMD),
                  child: Material(
                    color: kPrimaryColor,
                    borderRadius: BorderRadius.circular(kRadiusMD),
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CategoriesScreen(
                            categoryName: category.name,
                            categoryId: category.id,
                          ),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(kRadiusMD),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: kSpaceXL,
                          vertical: kSpaceMD,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getCategoryIcon(category.name),
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: kSpaceSM),
                            Text(
                              category.name,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('muslim')) return Icons.mosque_outlined;
    if (lower.contains('apparel') || lower.contains('apperal')) {
      return Icons.sports_outlined;
    }
    return Icons.checkroom_outlined;
  }
}

// ─── BRAND SECTION ─────────────────────────────────────────────────────────────

class _BrandSection extends StatelessWidget {
  const _BrandSection({required this.isLoading, required this.brands});

  final bool isLoading;
  final List<Brand> brands;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        kSectionHeader('Featured Brands'),
        const SizedBox(height: kSpaceLG),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: kSpace3XL),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (brands.isEmpty)
          const SizedBox.shrink()
        else
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: kSpaceXL),
              itemCount: brands.length,
              itemBuilder: (context, index) {
                final brand = brands[index];
                return Container(
                  width: 110,
                  margin: const EdgeInsets.only(right: kSpaceMD),
                  child: Material(
                    color: kPrimaryColor,
                    borderRadius: BorderRadius.circular(kRadiusLG),
                    elevation: 0,
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BrandsScreen(brandName: brand.name),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(kRadiusLG),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: kBorderColor),
                          borderRadius: BorderRadius.circular(kRadiusLG),
                        ),
                        padding: const EdgeInsets.all(kSpaceMD),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Image.network(
                                getBrandLogoUrl(brand.imageLogo),
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => Icon(
                                  Icons.image_not_supported_outlined,
                                  color: kBorderColor,
                                  size: 32,
                                ),
                              ),
                            ),
                            const SizedBox(height: kSpaceSM),
                            Text(
                              brand.name,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: Colors.white),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ─── PRODUCT SECTION ───────────────────────────────────────────────────────────

class _ProductSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        kSectionHeader('All Products'),
        const SizedBox(height: kSpaceLG),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: kSpaceXL),
          child: ProductsWidget(),
        ),
      ],
    );
  }
}
