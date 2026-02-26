import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/carts_model.dart';
import '../providers/carts_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/brands_screen.dart';
import '../screens/categories_screen.dart';
import '../utilities/constants.dart';
import '../widgets/header_widget.dart';
import '../widgets/footer_widget.dart';

// ---------------------------------------------------------------------------
// ProductDetailScreen — full product detail with variant selection and cart.
// Replaces: product_detail_page.dart  →  screens/product_detail_screen.dart
// ---------------------------------------------------------------------------

// ─── ProductVariant model ────────────────────────────────────────────────────
// Kept in this file; move to models/ when the API model layer is extended.

class ProductVariant {
  final int variantId;
  final String color;
  final String size;
  final double price;
  final int stock;

  const ProductVariant({
    required this.variantId,
    required this.color,
    required this.size,
    required this.price,
    required this.stock,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
    variantId: json['variant_id'] as int,
    color: json['color'] as String? ?? '',
    size: json['size'] as String? ?? '',
    price: double.tryParse(json['price'].toString()) ?? 0,
    stock: json['stock'] as int? ?? 0,
  );
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class ProductDetailScreen extends StatefulWidget {
  final String productName;
  final String image; // full URL
  final int price; // base price
  final String brand;
  final int categoryId;
  final String categoryName;
  final String? description;
  final List<Map<String, dynamic>> variantsJson;

  const ProductDetailScreen({
    super.key,
    required this.productName,
    required this.image,
    required this.price,
    required this.brand,
    required this.categoryId,
    required this.categoryName,
    this.description,
    this.variantsJson = const [],
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  // ─── STATE ─────────────────────────────────────────────────────────────────

  late final List<ProductVariant> _variants;
  final PageController _pageController = PageController();
  late final TextEditingController _quantityController;

  int _selectedImageIndex = 0;
  String? _selectedSize;
  String? _selectedColor;
  int _quantity = 1;

  // ─── LIFECYCLE ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _variants = widget.variantsJson
        .map((e) => ProductVariant.fromJson(e))
        .toList();
    _quantityController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  // ─── VARIANT HELPERS ───────────────────────────────────────────────────────

  bool get _hasVariants => _variants.isNotEmpty;

  List<String> get _sizes {
    final seen = <String>{};
    return _variants.where((v) => seen.add(v.size)).map((v) => v.size).toList();
  }

  List<String> get _colors {
    final seen = <String>{};
    return _variants
        .where((v) => seen.add(v.color))
        .map((v) => v.color)
        .toList();
  }

  ProductVariant? get _selectedVariant {
    if (_selectedSize == null || _selectedColor == null) return null;
    try {
      return _variants.firstWhere(
        (v) => v.size == _selectedSize && v.color == _selectedColor,
      );
    } catch (_) {
      return null;
    }
  }

  int get _currentStock => _selectedVariant?.stock ?? 0;
  int get _activePrice =>
      _selectedVariant != null ? _selectedVariant!.price.toInt() : widget.price;

  int _stockForSize(String size) {
    if (_selectedColor != null) {
      try {
        return _variants
            .firstWhere((v) => v.size == size && v.color == _selectedColor)
            .stock;
      } catch (_) {
        return 0;
      }
    }
    return _variants.any((v) => v.size == size && v.stock > 0) ? 1 : 0;
  }

  int _stockForColor(String color) {
    if (_selectedSize != null) {
      try {
        return _variants
            .firstWhere((v) => v.size == _selectedSize && v.color == color)
            .stock;
      } catch (_) {
        return 0;
      }
    }
    return _variants.any((v) => v.color == color && v.stock > 0) ? 1 : 0;
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────────

  String _formatPrice(int price) =>
      'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  Widget _buildImage(String url, {BoxFit fit = BoxFit.contain}) {
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: fit,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            color: kScaffoldBgColor,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
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
      );
    }
    return Image.asset(url, fit: fit);
  }

  void _updateQuantity(int value, int maxStock) {
    final clamped = value.clamp(1, maxStock.clamp(1, 9999));
    setState(() {
      _quantity = clamped;
      _quantityController
        ..text = clamped.toString()
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: clamped.toString().length),
        );
    });
  }

  void _showSizeGuide() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: kSurfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(kSpace2XL)),
        ),
        padding: const EdgeInsets.all(kSpaceXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: kSpaceXL),
              decoration: BoxDecoration(
                color: kBorderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Size Guide',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: kSpaceSM),
            ClipRRect(
              borderRadius: BorderRadius.circular(kRadiusMD),
              child: Image.asset(
                kSizeGuideImage,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Container(
                  height: 200,
                  color: kScaffoldBgColor,
                  child: const Center(child: Text('Image not found')),
                ),
              ),
            ),
            const SizedBox(height: kSpace3XL),
          ],
        ),
      ),
    );
  }

  void _addToCart() {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    context.read<CartsProvider>().addToCart(
      CartItem(
        productName: widget.productName,
        image: widget.image,
        basePrice: widget.price,
        brand: widget.brand,
        categoryId: widget.categoryId,
        categoryName: widget.categoryName,
        size: _selectedSize,
        color: _selectedColor,
        variantId: _selectedVariant?.variantId,
        variantPrice: _activePrice,
        quantity: _quantity,
      ),
    );

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 700),
          margin: const EdgeInsets.all(kSpaceLG),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusMD),
          ),
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: kSpaceMD),
              Expanded(
                child: Text(
                  'Added $_quantity ${_quantity > 1 ? 'items' : 'item'} to cart',
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green.shade600,
        ),
      );

    setState(() {
      _selectedSize = null;
      _selectedColor = null;
      _quantity = 1;
      _quantityController.text = '1';
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
            const SizedBox(height: kSpaceSM),
            _Breadcrumb(
              brand: widget.brand,
              categoryId: widget.categoryId,
              categoryName: widget.categoryName,
              productName: widget.productName,
            ),
            const SizedBox(height: kSpaceLG),
            _ProductImage(image: widget.image, buildImage: _buildImage),
            const SizedBox(height: kSpaceLG),
            _ThumbnailRow(
              image: widget.image,
              buildImage: _buildImage,
              selected: _selectedImageIndex,
              onTap: (i) => setState(() => _selectedImageIndex = i),
            ),
            const SizedBox(height: kSpace2XL),
            _ProductInfo(
              productName: widget.productName,
              categoryName: widget.categoryName,
              brand: widget.brand,
              activePrice: _activePrice,
              hasVariants: _hasVariants,
              selectedSize: _selectedSize,
              selectedColor: _selectedColor,
              currentStock: _currentStock,
              formatPrice: _formatPrice,
            ),
            const SizedBox(height: kSpace2XL),
            _RatingSection(),
            if (_hasVariants) ...[
              const SizedBox(height: kSpace2XL),
              _SizeSelector(
                sizes: _sizes,
                selectedSize: _selectedSize,
                stockForSize: _stockForSize,
                onShowGuide: _showSizeGuide,
                onSelect: (size) => setState(() {
                  _selectedSize = _selectedSize == size ? null : size;
                  _quantity = 1;
                  _quantityController.text = '1';
                }),
              ),
              const SizedBox(height: kSpace2XL),
              _ColorSelector(
                colors: _colors,
                selectedColor: _selectedColor,
                stockForColor: _stockForColor,
                onSelect: (color) => setState(() {
                  _selectedColor = _selectedColor == color ? null : color;
                  _quantity = 1;
                  _quantityController.text = '1';
                }),
              ),
            ],
            const SizedBox(height: kSpace2XL),
            _QuantitySelector(
              hasVariants: _hasVariants,
              selectedSize: _selectedSize,
              selectedColor: _selectedColor,
              currentStock: _currentStock,
              quantity: _quantity,
              controller: _quantityController,
              onUpdate: _updateQuantity,
            ),
            const SizedBox(height: kSpace2XL),
            _DescriptionCard(description: widget.description),
            const SizedBox(height: 100),
            const FooterWidget(),
          ],
        ),
      ),
      bottomNavigationBar: _BottomBar(
        hasVariants: _hasVariants,
        selectedSize: _selectedSize,
        selectedColor: _selectedColor,
        currentStock: _currentStock,
        addToCart: _addToCart,
        onBuyNow: () {
          _addToCart();
          Navigator.pushNamed(context, '/cart');
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

// ─── Breadcrumb ─────────────────────────────────────────────────────────────

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({
    required this.brand,
    required this.categoryId,
    required this.categoryName,
    required this.productName,
  });

  final String brand;
  final int categoryId;
  final String categoryName;
  final String productName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kSpaceLG,
        vertical: kSpaceMD,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(
              Icons.home_outlined,
              size: 16,
              color: kTextSecondaryColor,
            ),
            const SizedBox(width: kSpaceXS),
            _Item(
              label: 'Home',
              isFirst: true,
              onTap: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
            ),
            _Sep(),
            _Item(
              label: categoryName,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategoriesScreen(
                    categoryId: categoryId,
                    categoryName: categoryName,
                  ),
                ),
              ),
            ),
            _Sep(),
            _Item(
              label: brand,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BrandsScreen(brandName: brand),
                ),
              ),
            ),
            _Sep(),
            Text(
              productName,
              style: const TextStyle(
                fontSize: 8,
                color: kTextPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.label, this.isFirst = false, this.onTap});

  final String label;
  final bool isFirst;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: isFirst ? kTextSecondaryColor : kPrimaryColor,
          fontWeight: isFirst ? FontWeight.normal : FontWeight.w500,
        ),
      ),
    );
  }
}

class _Sep extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 2),
    child: Icon(Icons.chevron_right, size: 16, color: kTextSecondaryColor),
  );
}

// ─── Product image ───────────────────────────────────────────────────────────

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.image, required this.buildImage});

  final String image;
  final Widget Function(String, {BoxFit fit}) buildImage;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: kSpaceLG),
    decoration: BoxDecoration(
      color: kSurfaceColor,
      borderRadius: BorderRadius.circular(kRadiusLG),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(kRadiusLG),
      child: AspectRatio(aspectRatio: 1, child: buildImage(image)),
    ),
  );
}

// ─── Thumbnail row ───────────────────────────────────────────────────────────

class _ThumbnailRow extends StatelessWidget {
  const _ThumbnailRow({
    required this.image,
    required this.buildImage,
    required this.selected,
    required this.onTap,
  });

  final String image;
  final Widget Function(String, {BoxFit fit}) buildImage;
  final int selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 72,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: kSpaceLG),
      itemCount: 1,
      itemBuilder: (_, i) {
        final isSelected = selected == i;
        return GestureDetector(
          onTap: () => onTap(i),
          child: Container(
            width: 72,
            margin: const EdgeInsets.only(right: kSpaceMD),
            decoration: BoxDecoration(
              color: kSurfaceColor,
              borderRadius: BorderRadius.circular(kRadiusMD - 2),
              border: Border.all(
                color: isSelected ? kPrimaryColor : kBorderColor,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: kPrimaryColor.withValues(alpha: 0.20),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(kRadiusMD - 3),
              child: buildImage(image),
            ),
          ),
        );
      },
    ),
  );
}

// ─── Product info card ───────────────────────────────────────────────────────

class _ProductInfo extends StatelessWidget {
  const _ProductInfo({
    required this.productName,
    required this.categoryName,
    required this.brand,
    required this.activePrice,
    required this.hasVariants,
    required this.selectedSize,
    required this.selectedColor,
    required this.currentStock,
    required this.formatPrice,
  });

  final String productName;
  final String categoryName;
  final String brand;
  final int activePrice;
  final bool hasVariants;
  final String? selectedSize;
  final String? selectedColor;
  final int currentStock;
  final String Function(int) formatPrice;

  @override
  Widget build(BuildContext context) {
    final variantFullySelected = selectedSize != null && selectedColor != null;

    String stockLabel;
    Color stockLabelColor;
    Color stockBgColor;

    if (!hasVariants) {
      stockLabel = 'In Stock';
      stockLabelColor = Colors.green.shade700;
      stockBgColor = Colors.green.shade50;
    } else if (!variantFullySelected) {
      stockLabel = 'Select options';
      stockLabelColor = kTextSecondaryColor;
      stockBgColor = kScaffoldBgColor;
    } else if (currentStock > 0) {
      stockLabel = 'Stock: $currentStock';
      stockLabelColor = Colors.green.shade700;
      stockBgColor = Colors.green.shade50;
    } else {
      stockLabel = 'Out of Stock';
      stockLabelColor = kErrorColor;
      stockBgColor = Colors.red.shade50;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: kSpaceLG),
      padding: const EdgeInsets.all(kSpaceXL),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category · Brand
          Row(
            children: [
              Text(
                categoryName.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: kTextSecondaryColor,
                  letterSpacing: 1.2,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: kSpaceSM),
                child: Text('•', style: TextStyle(color: kBorderColor)),
              ),
              Text(
                brand.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: kPrimaryColor,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: kSpaceMD),

          // Product name
          Text(productName, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: kSpaceLG),

          // Price + stock badge
          Row(
            children: [
              Text(
                formatPrice(activePrice),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: kPrimaryColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: kSpaceMD,
                  vertical: kSpaceXS + 2,
                ),
                decoration: BoxDecoration(
                  color: stockBgColor,
                  borderRadius: BorderRadius.circular(kRadiusSM),
                ),
                child: Text(
                  stockLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: stockLabelColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Rating section ──────────────────────────────────────────────────────────

class _RatingSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: kSpaceLG),
    padding: const EdgeInsets.all(kSpaceLG),
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
    child: Row(
      children: [
        Icon(Icons.star, color: Colors.amber.shade600, size: 24),
        const SizedBox(width: kSpaceSM),
        Text('0.0', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(width: kSpaceSM),
        Text(
          '(0 reviews)',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: kTextSecondaryColor),
        ),
        const Spacer(),
        TextButton(onPressed: () {}, child: const Text('See all')),
      ],
    ),
  );
}

// ─── Size selector ───────────────────────────────────────────────────────────

class _SizeSelector extends StatelessWidget {
  const _SizeSelector({
    required this.sizes,
    required this.selectedSize,
    required this.stockForSize,
    required this.onShowGuide,
    required this.onSelect,
  });

  final List<String> sizes;
  final String? selectedSize;
  final int Function(String) stockForSize;
  final VoidCallback onShowGuide;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: kSpaceLG),
    padding: const EdgeInsets.all(kSpaceXL),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Select Size', style: Theme.of(context).textTheme.titleMedium),
            if (selectedSize != null)
              GestureDetector(
                onTap: () => onSelect(selectedSize!),
                child: Text(
                  'Clear',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: kTextSecondaryColor),
                ),
              ),
            TextButton(onPressed: onShowGuide, child: const Text('Size Guide')),
          ],
        ),
        const SizedBox(height: kSpaceMD),
        Row(
          children: sizes.asMap().entries.map((entry) {
            final i = entry.key;
            final size = entry.value;
            final isSelected = selectedSize == size;
            final outOfStock = stockForSize(size) == 0;
            final isLast = i == sizes.length - 1;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: isLast ? 0 : kSpaceMD),
                child: GestureDetector(
                  onTap: outOfStock ? null : () => onSelect(size),
                  child: Opacity(
                    opacity: outOfStock ? 0.35 : 1.0,
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? kPrimaryColor : kScaffoldBgColor,
                        border: Border.all(
                          color: isSelected ? kPrimaryColor : kBorderColor,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(kRadiusMD - 2),
                      ),
                      child: Text(
                        size,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: isSelected ? Colors.white : kTextPrimaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );
}

// ─── Color selector ──────────────────────────────────────────────────────────

class _ColorSelector extends StatelessWidget {
  const _ColorSelector({
    required this.colors,
    required this.selectedColor,
    required this.stockForColor,
    required this.onSelect,
  });

  final List<String> colors;
  final String? selectedColor;
  final int Function(String) stockForColor;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: kSpaceLG),
    padding: const EdgeInsets.all(kSpaceXL),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Color', style: Theme.of(context).textTheme.titleMedium),
            if (selectedColor != null)
              GestureDetector(
                onTap: () => onSelect(selectedColor!),
                child: Text(
                  'Clear',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: kTextSecondaryColor),
                ),
              ),
          ],
        ),
        const SizedBox(height: kSpaceMD),
        Wrap(
          spacing: kSpaceMD,
          runSpacing: kSpaceMD,
          children: colors.map((color) {
            final isSelected = selectedColor == color;
            final outOfStock = stockForColor(color) == 0;

            return GestureDetector(
              onTap: outOfStock ? null : () => onSelect(color),
              child: Opacity(
                opacity: outOfStock ? 0.35 : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kSpaceXL - 2,
                    vertical: kSpaceSM + 2,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? kPrimaryColor.withValues(alpha: 0.08)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? kPrimaryColor : kBorderColor,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(kRadiusMD - 2),
                  ),
                  child: Text(
                    color,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected ? kPrimaryColor : kTextPrimaryColor,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );
}

// ─── Quantity selector ───────────────────────────────────────────────────────

class _QuantitySelector extends StatelessWidget {
  const _QuantitySelector({
    required this.hasVariants,
    required this.selectedSize,
    required this.selectedColor,
    required this.currentStock,
    required this.quantity,
    required this.controller,
    required this.onUpdate,
  });

  final bool hasVariants;
  final String? selectedSize;
  final String? selectedColor;
  final int currentStock;
  final int quantity;
  final TextEditingController controller;
  final void Function(int, int) onUpdate;

  @override
  Widget build(BuildContext context) {
    final bothSelected =
        !hasVariants || (selectedSize != null && selectedColor != null);
    final maxStock = hasVariants ? currentStock : 99;
    final canDecrease = bothSelected && maxStock > 0 && quantity > 1;
    final canIncrease = bothSelected && maxStock > 0 && quantity < maxStock;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: kSpaceLG),
      padding: const EdgeInsets.all(kSpaceXL),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quantity', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: kSpaceXS),
              Text(
                !bothSelected
                    ? 'Select size & color first'
                    : maxStock > 0
                    ? '$maxStock available'
                    : 'Out of stock',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: !bothSelected
                      ? kBorderColor
                      : maxStock > 0
                      ? Colors.green.shade600
                      : kErrorColor,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _QtyBtn(
                icon: Icons.remove,
                enabled: canDecrease,
                onTap: () => onUpdate(quantity - 1, maxStock),
              ),
              SizedBox(
                width: 60,
                child: TextField(
                  controller: controller,
                  enabled: bothSelected && maxStock > 0,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: bothSelected ? kTextPrimaryColor : kBorderColor,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (v) {
                    if (v.isEmpty) return;
                    final parsed = int.tryParse(v);
                    if (parsed != null && parsed > 0) {
                      onUpdate(parsed, maxStock);
                    }
                  },
                  onSubmitted: (v) {
                    final parsed = int.tryParse(v);
                    if (parsed == null || parsed < 1) onUpdate(1, maxStock);
                  },
                ),
              ),
              _QtyBtn(
                icon: Icons.add,
                enabled: canIncrease,
                onTap: () => onUpdate(quantity + 1, maxStock),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: enabled ? kScaffoldBgColor : kScaffoldBgColor,
        borderRadius: BorderRadius.circular(kRadiusSM),
        border: Border.all(color: enabled ? kBorderColor : kScaffoldBgColor),
      ),
      child: Icon(
        icon,
        size: 20,
        color: enabled ? kTextSecondaryColor : kBorderColor,
      ),
    ),
  );
}

// ─── Description card ────────────────────────────────────────────────────────

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({required this.description});

  final String? description;

  @override
  Widget build(BuildContext context) {
    final text = (description != null && description!.isNotEmpty)
        ? description!
        : 'No description available for this product.';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: kSpaceLG),
      padding: const EdgeInsets.all(kSpaceXL),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Description', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: kSpaceMD),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: kTextSecondaryColor,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom action bar ───────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.hasVariants,
    required this.selectedSize,
    required this.selectedColor,
    required this.currentStock,
    required this.addToCart,
    required this.onBuyNow,
  });

  final bool hasVariants;
  final String? selectedSize;
  final String? selectedColor;
  final int currentStock;
  final VoidCallback addToCart;
  final VoidCallback onBuyNow;

  @override
  Widget build(BuildContext context) {
    final canBuy =
        !hasVariants ||
        (selectedSize != null && selectedColor != null && currentStock > 0);

    void prompt() => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Please select size and color first'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.orange.shade700,
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(
        kSpaceLG,
        kSpaceMD,
        kSpaceLG,
        kSpace2XL,
      ),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: canBuy ? addToCart : prompt,
                icon: const Icon(Icons.shopping_bag_outlined, size: 20),
                label: const Text('Add to Cart'),
              ),
            ),
            const SizedBox(width: kSpaceMD),
            Expanded(
              child: ElevatedButton(
                onPressed: canBuy ? onBuyNow : prompt,
                child: const Text('Buy Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
