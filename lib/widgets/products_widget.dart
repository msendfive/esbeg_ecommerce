import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/products_model.dart';
import '../models/categories_model.dart';
import '../screens/product_detail_screen.dart';
import '../utilities/constants.dart';

// ---------------------------------------------------------------------------
// ProductsWidget — reusable product grid used on Home, Brands, Categories,
// and Search screens.
// Replaces: widgets/product_grid_section.dart  →  widgets/products_widget.dart
// ---------------------------------------------------------------------------

class ProductsWidget extends StatefulWidget {
  final String? brandName;
  final String? searchKeyword;
  final int? categoryId;
  final Map<String, dynamic>? filters;

  const ProductsWidget({
    super.key,
    this.brandName,
    this.searchKeyword,
    this.categoryId,
    this.filters,
  });

  @override
  State<ProductsWidget> createState() => _ProductsWidgetState();
}

class _ProductsWidgetState extends State<ProductsWidget> {
  // ─── STATE ─────────────────────────────────────────────────────────────────

  List<Product> _products = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  bool _hasError = false;

  // ─── LIFECYCLE ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  @override
  void didUpdateWidget(covariant ProductsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-fetch only when the active filters change
    if (widget.filters != oldWidget.filters) {
      _fetchProducts();
    }
  }

  // ─── DATA FETCHING ─────────────────────────────────────────────────────────

  Future<void> _fetchInitialData() async {
    await _fetchCategories();
    await _fetchProducts();
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

  Future<void> _fetchProducts() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      final response = await http.get(Uri.parse(kProductEndpoint));

      if (response.statusCode == 200) {
        final List raw = json.decode(response.body)['data'];
        List<Product> all = raw.map((e) => Product.fromJson(e)).toList();

        // ── Caller-context filters ──────────────────────────────────────────
        if (widget.brandName != null) {
          all = all
              .where(
                (p) => p.brand.toLowerCase() == widget.brandName!.toLowerCase(),
              )
              .toList();
        }

        if (widget.categoryId != null) {
          all = all.where((p) => p.categoryId == widget.categoryId).toList();
        }

        if (widget.searchKeyword != null &&
            widget.searchKeyword!.trim().isNotEmpty) {
          final kw = widget.searchKeyword!.toLowerCase();
          all = all
              .where(
                (p) =>
                    p.name.toLowerCase().contains(kw) ||
                    p.brand.toLowerCase().contains(kw),
              )
              .toList();
        }

        // ── Bottom-sheet filters ────────────────────────────────────────────
        if (widget.filters != null) {
          final f = widget.filters!;

          // Brand filter (used on category pages)
          if (f['brand'] != null) {
            all = all
                .where(
                  (p) =>
                      p.brand.toLowerCase() ==
                      (f['brand'] as String).toLowerCase(),
                )
                .toList();
          }

          // Category filter (used on brand pages)
          if (f['category'] != null) {
            final filterCategoryName = (f['category'] as String).toLowerCase();
            all = all
                .where(
                  (p) =>
                      _getCategoryName(p.categoryId).toLowerCase() ==
                      filterCategoryName,
                )
                .toList();
          }

          // Size filter
          if (f['size'] != null) {
            final selectedSize = (f['size'] as String).toUpperCase();
            all = all
                .where(
                  (p) => p.variantsJson.any(
                    (v) =>
                        (v['size']?.toString().toUpperCase() ?? '') ==
                        selectedSize,
                  ),
                )
                .toList();
          }

          // Color filter
          if (f['color'] != null) {
            final selectedColor = (f['color'] as String).toLowerCase();
            all = all
                .where(
                  (p) => p.variantsJson.any(
                    (v) =>
                        (v['color']?.toString().toLowerCase() ?? '') ==
                        selectedColor,
                  ),
                )
                .toList();
          }

          // Price-range filter
          final minPrice = f['minPrice'] as int? ?? 0;
          final maxPrice = f['maxPrice'] as int? ?? double.maxFinite.toInt();
          all = all.where((p) {
            if (p.price >= minPrice && p.price <= maxPrice) return true;
            return p.variantsJson.any((v) {
              final vPrice =
                  double.tryParse(v['price']?.toString() ?? '0') ?? 0;
              return vPrice >= minPrice && vPrice <= maxPrice;
            });
          }).toList();
        }

        if (mounted) {
          setState(() {
            _products = all;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Product Fetch Error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────────

  String _getCategoryName(int categoryId) {
    return _categories
        .firstWhere(
          (c) => c.id == categoryId,
          orElse: () => Category(id: 0, name: 'Unknown'),
        )
        .name;
  }

  String _formatPrice(double price) {
    return 'Rp ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // ── Loading ──────────────────────────────────────────────────────────────
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // ── Error ────────────────────────────────────────────────────────────────
    if (_hasError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.wifi_off_outlined,
                size: 60,
                color: kBorderColor,
              ),
              const SizedBox(height: kSpaceLG),
              Text(
                'Failed to load products',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: kTextSecondaryColor),
              ),
              const SizedBox(height: kSpaceMD),
              TextButton.icon(
                onPressed: _fetchProducts,
                icon: const Icon(Icons.refresh, color: kPrimaryColor),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    // ── Empty ────────────────────────────────────────────────────────────────
    if (_products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'No products found',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: kTextSecondaryColor),
          ),
        ),
      );
    }

    // ── Grid ─────────────────────────────────────────────────────────────────
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.58,
        crossAxisSpacing: kSpaceMD,
        mainAxisSpacing: kSpaceMD,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) => _ProductCard(
        product: _products[index],
        categoryName: _getCategoryName(_products[index].categoryId),
        formattedPrice: _formatPrice(_products[index].price),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ProductCard — single card in the product grid.
// Extracted from the State to keep build() clean and allow const construction.
// ---------------------------------------------------------------------------

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.categoryName,
    required this.formattedPrice,
  });

  final Product product;
  final String categoryName;
  final String formattedPrice;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kSurfaceColor,
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusLG),
        side: const BorderSide(color: kPrimaryColor, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(kRadiusLG),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(
              productName: product.name,
              image: '$kBaseUrl${product.image}',
              price: product.price.toInt(),
              brand: product.brand,
              categoryId: product.categoryId,
              categoryName: categoryName,
              description: product.description,
              variantsJson: product.variantsJson,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Product image ───────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(kRadiusLG),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: product.image.isNotEmpty
                        ? Image.network(
                            '$kBaseUrl${product.image}',
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                            loadingBuilder: (_, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: kScaffoldBgColor,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, _, _) => Container(
                              color: kScaffoldBgColor,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: kBorderColor,
                                size: 40,
                              ),
                            ),
                          )
                        : Container(
                            color: kScaffoldBgColor,
                            child: const Icon(
                              Icons.image_outlined,
                              color: kBorderColor,
                              size: 40,
                            ),
                          ),
                  ),
                ),

                // "NEW" badge
                if (product.isNew)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kSpaceMD,
                        vertical: kSpaceXS + 2,
                      ),
                      decoration: const BoxDecoration(
                        color: kPrimaryColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(kRadiusLG),
                          bottomRight: Radius.circular(kRadiusMD),
                        ),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // ── Product info ────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(kSpaceMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category & brand pills
                    Wrap(
                      spacing: kSpaceXS,
                      runSpacing: kSpaceXS,
                      children: [
                        _Pill(label: categoryName),
                        _Pill(label: product.brand),
                      ],
                    ),

                    const SizedBox(height: kSpaceSM + 2),

                    // Product name
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: kSpaceSM + 2),

                    // Price
                    Text(
                      formattedPrice,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _Pill — small category / brand label on each product card.
// ---------------------------------------------------------------------------

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kSpaceSM + 2,
        vertical: kSpaceXS,
      ),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(kRadiusSM - 3),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
