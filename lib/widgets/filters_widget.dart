import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/brands_model.dart';
import '../models/categories_model.dart';
import '../models/products_model.dart';
import '../utilities/constants.dart';

// ---------------------------------------------------------------------------
// FiltersWidget — bottom sheet for filtering products by brand, category,
// size, color, and price range.
// Replaces: widgets/global_filter_bottom_sheet.dart → widgets/filters_widget.dart
// ---------------------------------------------------------------------------

class FiltersWidget extends StatefulWidget {
  final bool showBrand;
  final bool showCategory;

  const FiltersWidget({
    super.key,
    this.showBrand = false,
    this.showCategory = false,
  });

  @override
  State<FiltersWidget> createState() => _FiltersWidgetState();
}

class _FiltersWidgetState extends State<FiltersWidget> {
  // ─── FILTER SELECTION STATE ────────────────────────────────────────────────

  String? _selectedBrand;
  String? _selectedCategory;
  String? _selectedSize;
  String? _selectedColor;
  RangeValues _priceRange = const RangeValues(0, 1000000);

  // ─── DATA ──────────────────────────────────────────────────────────────────

  List<Brand> _brands = [];
  List<Category> _categories = [];
  List<String> _sizes = [];
  List<String> _colors = [];
  double _minPrice = 0;
  double _maxPrice = 1000000;

  bool _isLoading = true;

  // ─── LIFECYCLE ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fetchFilterData();
  }

  // ─── DATA FETCHING ─────────────────────────────────────────────────────────

  Future<void> _fetchFilterData() async {
    try {
      await Future.wait([
        if (widget.showBrand) _fetchBrands(),
        if (widget.showCategory) _fetchCategories(),
        _fetchProductVariants(),
      ]);

      if (mounted) {
        setState(() {
          _priceRange = RangeValues(0, _maxPrice);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Filter Data Fetch Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchBrands() async {
    final response = await http.get(Uri.parse(kBrandEndpoint));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body)['data'];
      if (mounted) {
        setState(() {
          _brands = data.map((e) => Brand.fromJson(e)).toList();
        });
      }
    }
  }

  Future<void> _fetchCategories() async {
    final response = await http.get(Uri.parse(kCategoryEndpoint));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body)['data'];
      if (mounted) {
        setState(() {
          _categories = data.map((e) => Category.fromJson(e)).toList();
        });
      }
    }
  }

  Future<void> _fetchProductVariants() async {
    final response = await http.get(Uri.parse(kProductEndpoint));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body)['data'];
      final products = data.map((e) => Product.fromJson(e)).toList();

      final Set<String> sizeSet = {};
      final Set<String> colorSet = {};
      double highest = 0;

      for (final product in products) {
        if (product.price > highest) highest = product.price;

        for (final v in product.variantsJson) {
          final size = v['size']?.toString().trim() ?? '';
          final color = v['color']?.toString().trim() ?? '';
          if (size.isNotEmpty) sizeSet.add(size);
          if (color.isNotEmpty) colorSet.add(color);

          final vPrice = double.tryParse(v['price']?.toString() ?? '0') ?? 0;
          if (vPrice > highest) highest = vPrice;
        }
      }

      if (mounted) {
        setState(() {
          _sizes = sizeSet.toList()..sort(_sizeComparator);
          _colors = colorSet.toList()..sort();
          _maxPrice = _roundUpPrice(highest);
          _minPrice = 0;
        });
      }
    }
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────────

  /// Round up to the nearest 100 000 for a cleaner price slider.
  double _roundUpPrice(double price) {
    if (price == 0) return 1000000;
    return ((price / 100000).ceil() * 100000).toDouble();
  }

  /// Order XS → S → M → L → XL → XXL → XXXL; anything else alphabetically.
  int _sizeComparator(String a, String b) {
    const order = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'];
    final ai = order.indexOf(a.toUpperCase());
    final bi = order.indexOf(b.toUpperCase());
    if (ai != -1 && bi != -1) return ai.compareTo(bi);
    if (ai != -1) return -1;
    if (bi != -1) return 1;
    return a.compareTo(b);
  }

  bool get _hasAnyFilter =>
      _selectedBrand != null ||
      _selectedCategory != null ||
      _selectedSize != null ||
      _selectedColor != null ||
      _priceRange != RangeValues(0, _maxPrice);

  String _formatPrice(int price) =>
      'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  void _resetAll() => setState(() {
    _selectedBrand = null;
    _selectedCategory = null;
    _selectedSize = null;
    _selectedColor = null;
    _priceRange = RangeValues(0, _maxPrice);
  });

  // ─── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: kScaffoldBgColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(kRadiusXL + 8),
        ),
      ),
      child: Column(
        children: [
          _TopBar(
            hasAnyFilter: _hasAnyFilter && !_isLoading,
            onReset: _resetAll,
          ),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: kSpaceLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: kSpaceLG),

                    // Brand filter (shown on category pages)
                    if (widget.showBrand) ...[
                      _FilterCard(
                        title: 'Brand',
                        selected: _selectedBrand,
                        onClear: () => setState(() => _selectedBrand = null),
                        isEmpty: _brands.isEmpty,
                        child: _brands.isEmpty
                            ? const _EmptyOption('No brands available')
                            : _Chips(
                                items: _brands.map((b) => b.name).toList(),
                                selected: _selectedBrand,
                                onTap: (val) => setState(
                                  () => _selectedBrand = _selectedBrand == val
                                      ? null
                                      : val,
                                ),
                              ),
                      ),
                      const SizedBox(height: kSpaceMD),
                    ],

                    // Category filter (shown on brand pages)
                    if (widget.showCategory) ...[
                      _FilterCard(
                        title: 'Category',
                        selected: _selectedCategory,
                        onClear: () => setState(() => _selectedCategory = null),
                        isEmpty: _categories.isEmpty,
                        child: _categories.isEmpty
                            ? const _EmptyOption('No categories available')
                            : _Chips(
                                items: _categories.map((c) => c.name).toList(),
                                selected: _selectedCategory,
                                onTap: (val) => setState(
                                  () => _selectedCategory =
                                      _selectedCategory == val ? null : val,
                                ),
                              ),
                      ),
                      const SizedBox(height: kSpaceMD),
                    ],

                    // Size filter
                    _FilterCard(
                      title: 'Select Size',
                      selected: _selectedSize,
                      onClear: () => setState(() => _selectedSize = null),
                      isEmpty: _sizes.isEmpty,
                      child: _sizes.isEmpty
                          ? const _EmptyOption('No sizes available')
                          : _SizeChips(
                              sizes: _sizes,
                              selectedSize: _selectedSize,
                              onTap: (val) => setState(
                                () => _selectedSize = _selectedSize == val
                                    ? null
                                    : val,
                              ),
                            ),
                    ),

                    const SizedBox(height: kSpaceMD),

                    // Color filter
                    _FilterCard(
                      title: 'Color',
                      selected: _selectedColor,
                      onClear: () => setState(() => _selectedColor = null),
                      isEmpty: _colors.isEmpty,
                      child: _colors.isEmpty
                          ? const _EmptyOption('No colors available')
                          : _Chips(
                              items: _colors,
                              selected: _selectedColor,
                              onTap: (val) => setState(
                                () => _selectedColor = _selectedColor == val
                                    ? null
                                    : val,
                              ),
                            ),
                    ),

                    const SizedBox(height: kSpaceMD),

                    // Price range
                    _PriceSection(
                      priceRange: _priceRange,
                      maxPrice: _maxPrice,
                      formatPrice: _formatPrice,
                      onChanged: (values) =>
                          setState(() => _priceRange = values),
                    ),

                    const SizedBox(height: kSpace3XL),
                  ],
                ),
              ),
            ),
          _BottomButtons(
            isLoading: _isLoading,
            onReset: _resetAll,
            onApply: () => Navigator.pop(context, {
              'brand': _selectedBrand,
              'category': _selectedCategory,
              'size': _selectedSize,
              'color': _selectedColor,
              'minPrice': _priceRange.start.round(),
              'maxPrice': _priceRange.end.round(),
            }),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

// ─── Top bar ────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.hasAnyFilter, required this.onReset});

  final bool hasAnyFilter;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        kSpaceXL,
        kSpaceLG,
        kSpaceXL,
        kSpaceLG,
      ),
      decoration: const BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(kRadiusXL + 8),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: kBorderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: kSpaceLG),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filter', style: Theme.of(context).textTheme.titleLarge),
              if (hasAnyFilter)
                GestureDetector(
                  onTap: onReset,
                  child: Text(
                    'Reset all',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: kTextSecondaryColor,
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

// ─── Filter card wrapper ─────────────────────────────────────────────────────

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.title,
    required this.child,
    this.selected,
    this.onClear,
    this.isEmpty = false,
  });

  final String title;
  final Widget child;
  final String? selected;
  final VoidCallback? onClear;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              if (selected != null && onClear != null && !isEmpty)
                GestureDetector(
                  onTap: onClear,
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
          child,
        ],
      ),
    );
  }
}

// ─── Empty option ────────────────────────────────────────────────────────────

class _EmptyOption extends StatelessWidget {
  const _EmptyOption(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kSpaceXL),
      child: Center(
        child: Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: kTextSecondaryColor),
        ),
      ),
    );
  }
}

// ─── Generic wrap chips ──────────────────────────────────────────────────────

class _Chips extends StatelessWidget {
  const _Chips({
    required this.items,
    required this.selected,
    required this.onTap,
  });

  final List<String> items;
  final String? selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: kSpaceSM + 2,
      runSpacing: kSpaceSM + 2,
      children: items.map((item) {
        final isSelected = selected == item;
        return GestureDetector(
          onTap: () => onTap(item),
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
              item,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? kPrimaryColor : kTextPrimaryColor,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Size chips (equal-width row) ────────────────────────────────────────────

class _SizeChips extends StatelessWidget {
  const _SizeChips({
    required this.sizes,
    required this.selectedSize,
    required this.onTap,
  });

  final List<String> sizes;
  final String? selectedSize;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: sizes.asMap().entries.map((entry) {
        final i = entry.key;
        final size = entry.value;
        final isSelected = selectedSize == size;
        final isLast = i == sizes.length - 1;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : kSpaceSM + 2),
            child: GestureDetector(
              onTap: () => onTap(size),
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
        );
      }).toList(),
    );
  }
}

// ─── Price range section ─────────────────────────────────────────────────────

class _PriceSection extends StatelessWidget {
  const _PriceSection({
    required this.priceRange,
    required this.maxPrice,
    required this.formatPrice,
    required this.onChanged,
  });

  final RangeValues priceRange;
  final double maxPrice;
  final String Function(int) formatPrice;
  final ValueChanged<RangeValues> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text('Price Range', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: kSpaceLG),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PriceLabel(text: formatPrice(priceRange.start.round())),
              _PriceLabel(text: formatPrice(priceRange.end.round())),
            ],
          ),
          const SizedBox(height: kSpaceSM),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              rangeThumbShape: const RoundRangeSliderThumbShape(
                enabledThumbRadius: 10,
              ),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              activeTrackColor: kPrimaryColor,
              inactiveTrackColor: kBorderColor,
              thumbColor: kPrimaryColor,
              overlayColor: kPrimaryColor.withValues(alpha: 0.12),
            ),
            child: RangeSlider(
              values: priceRange,
              min: 0,
              max: maxPrice,
              divisions: maxPrice > 0 ? (maxPrice / 50000).round() : 20,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceLabel extends StatelessWidget {
  const _PriceLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kSpaceMD,
        vertical: kSpaceXS + 2,
      ),
      decoration: BoxDecoration(
        color: kScaffoldBgColor,
        borderRadius: BorderRadius.circular(kRadiusSM),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: kPrimaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Bottom action buttons ───────────────────────────────────────────────────

class _BottomButtons extends StatelessWidget {
  const _BottomButtons({
    required this.isLoading,
    required this.onReset,
    required this.onApply,
  });

  final bool isLoading;
  final VoidCallback onReset;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        kSpaceLG,
        kSpaceMD,
        kSpaceLG,
        kSpace2XL,
      ),
      decoration: const BoxDecoration(
        color: kSurfaceColor,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Reset button
            Expanded(
              child: OutlinedButton(
                onPressed: isLoading ? null : onReset,
                child: const Text('Reset'),
              ),
            ),
            const SizedBox(width: kSpaceMD),
            // Apply button
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: isLoading ? null : onApply,
                child: const Text('Apply Filter'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
