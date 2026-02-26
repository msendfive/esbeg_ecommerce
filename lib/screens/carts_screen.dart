import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/carts_model.dart';
import '../models/vouchers_model.dart';
import '../providers/carts_provider.dart';
import '../providers/vouchers_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/checkout_screen.dart';
import '../utilities/constants.dart';
import '../widgets/header_widget.dart';

// ---------------------------------------------------------------------------
// CartsScreen — shopping cart with voucher support and order summary.
// Replaces: cart_page.dart  →  screens/carts_screen.dart
// ---------------------------------------------------------------------------

class CartsScreen extends StatefulWidget {
  const CartsScreen({super.key});

  @override
  State<CartsScreen> createState() => _CartsScreenState();
}

class _CartsScreenState extends State<CartsScreen> {
  // ─── STATE ─────────────────────────────────────────────────────────────────

  static const int _shipping = 15000;
  static const int _insurance = 5000;
  int _discount = 0;
  String? _appliedVoucher;

  // ─── LIFECYCLE ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartsProvider>().loadCart();
    });
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────────

  String _formatPrice(int price) =>
      'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  int _grandTotal(int subtotal) =>
      subtotal - _discount + _shipping + _insurance;

  // ─── VOUCHER SHEET ─────────────────────────────────────────────────────────

  void _showVoucherSheet(int subtotal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VoucherSheet(
        subtotal: subtotal,
        currentApplied: _appliedVoucher,
        onVoucherApplied: (code, discount) => setState(() {
          _appliedVoucher = code.isEmpty ? null : code;
          _discount = discount;
        }),
      ),
    );
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBgColor,
      appBar: const HeaderWidget(),
      body: Consumer<CartsProvider>(
        builder: (context, cart, _) {
          if (cart.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(kSpaceLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PageHeader(cart: cart),
                const SizedBox(height: kSpaceXL),

                if (!cart.hasItems)
                  _EmptyCart()
                else ...[
                  _CartItems(
                    cart: cart,
                    formatPrice: _formatPrice,
                    onDeleteTap: (item) => _showDeleteDialog(cart, item),
                  ),
                  const SizedBox(height: kSpaceLG),
                  _VoucherRow(
                    appliedVoucher: _appliedVoucher,
                    onTap: () => _showVoucherSheet(cart.subtotal),
                  ),
                  const SizedBox(height: kSpaceLG),
                  _Summary(
                    subtotal: cart.subtotal,
                    shipping: _shipping,
                    insurance: _insurance,
                    discount: _discount,
                    grandTotal: _grandTotal(cart.subtotal),
                    formatPrice: _formatPrice,
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Consumer<CartsProvider>(
        builder: (context, cart, _) => _BottomBar(cart: cart),
      ),
    );
  }

  // ─── DELETE DIALOG ─────────────────────────────────────────────────────────

  void _showDeleteDialog(CartsProvider cart, CartItem item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Item'),
        content: Text('Remove "${item.productName}" from cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              cart.removeFromCart(item.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Item removed from cart'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text('Remove', style: TextStyle(color: kErrorColor)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

// ─── Page header ────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.cart});

  final CartsProvider cart;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Shopping Cart', style: Theme.of(context).textTheme.headlineSmall),
        if (cart.hasItems)
          Text(
            '${cart.itemCount} item${cart.itemCount > 1 ? 's' : ''}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: kTextSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}

// ─── Empty cart ──────────────────────────────────────────────────────────────

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kSpace3XL),
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
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              color: kScaffoldBgColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 60,
              color: kBorderColor,
            ),
          ),
          const SizedBox(height: kSpace2XL),
          Text(
            'Your cart is empty',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: kSpaceMD),
          Text(
            "You haven't added any products yet. Start shopping to fill it up!",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: kTextSecondaryColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: kSpace2XL),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (route) => false,
              ),
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text('Start Shopping'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Cart items list ─────────────────────────────────────────────────────────

class _CartItems extends StatelessWidget {
  const _CartItems({
    required this.cart,
    required this.formatPrice,
    required this.onDeleteTap,
  });

  final CartsProvider cart;
  final String Function(int) formatPrice;
  final void Function(CartItem) onDeleteTap;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        children: cart.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              _CartItemRow(
                cart: cart,
                item: item,
                formatPrice: formatPrice,
                onDelete: () => onDeleteTap(item),
              ),
              if (index < cart.items.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: kSpaceLG),
                  child: Divider(color: kBorderColor, height: 1),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _CartItemRow extends StatelessWidget {
  const _CartItemRow({
    required this.cart,
    required this.item,
    required this.formatPrice,
    required this.onDelete,
  });

  final CartsProvider cart;
  final CartItem item;
  final String Function(int) formatPrice;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thumbnail
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: kScaffoldBgColor,
            borderRadius: BorderRadius.circular(kRadiusMD - 2),
            border: Border.all(color: kBorderColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(kRadiusMD - 3),
            child: Image.network(
              item.image,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.image_not_supported_outlined,
                color: kBorderColor,
              ),
            ),
          ),
        ),

        const SizedBox(width: kSpaceMD),

        // Info + controls
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName,
                style: Theme.of(context).textTheme.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: kSpaceXS),
              Text(
                item.variantText,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: kTextSecondaryColor),
              ),
              const SizedBox(height: kSpaceSM),
              Row(
                children: [
                  Text(
                    formatPrice(item.variantPrice),
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: kPrimaryColor),
                  ),
                  const Spacer(),
                  _QuantityControls(cart: cart, item: item),
                ],
              ),
            ],
          ),
        ),

        // Delete
        IconButton(
          icon: const Icon(Icons.delete_outline),
          iconSize: 22,
          color: kTextSecondaryColor,
          onPressed: onDelete,
        ),
      ],
    );
  }
}

// ─── Quantity controls ───────────────────────────────────────────────────────

class _QuantityControls extends StatelessWidget {
  const _QuantityControls({required this.cart, required this.item});

  final CartsProvider cart;
  final CartItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kScaffoldBgColor,
        borderRadius: BorderRadius.circular(kRadiusSM),
        border: Border.all(color: kBorderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyButton(
            icon: Icons.remove,
            onTap: () => cart.decreaseQuantity(item.id),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kSpaceMD),
            child: Text(
              '${item.quantity}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          _QtyButton(
            icon: Icons.add,
            onTap: () => cart.increaseQuantity(item.id),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(kSpaceXS + 2),
        child: Icon(icon, size: 16, color: kTextSecondaryColor),
      ),
    );
  }
}

// ─── Voucher row ─────────────────────────────────────────────────────────────

class _VoucherRow extends StatelessWidget {
  const _VoucherRow({required this.appliedVoucher, required this.onTap});

  final String? appliedVoucher;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(kRadiusLG),
      onTap: onTap,
      child: Container(
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
            const Icon(
              Icons.local_offer_outlined,
              color: kPrimaryColor,
              size: 22,
            ),
            const SizedBox(width: kSpaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appliedVoucher != null
                        ? 'Voucher Applied'
                        : 'Apply Voucher',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: appliedVoucher != null
                          ? kPrimaryColor
                          : kTextPrimaryColor,
                    ),
                  ),
                  if (appliedVoucher != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      appliedVoucher!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: kBorderColor, size: 22),
          ],
        ),
      ),
    );
  }
}

// ─── Order summary ───────────────────────────────────────────────────────────

class _Summary extends StatelessWidget {
  const _Summary({
    required this.subtotal,
    required this.shipping,
    required this.insurance,
    required this.discount,
    required this.grandTotal,
    required this.formatPrice,
  });

  final int subtotal;
  final int shipping;
  final int insurance;
  final int discount;
  final int grandTotal;
  final String Function(int) formatPrice;

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
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 22,
                color: kTextSecondaryColor,
              ),
              const SizedBox(width: kSpaceSM),
              Text(
                'Order Summary',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: kSpaceXL),
          _Row(label: 'Subtotal', value: formatPrice(subtotal)),
          const SizedBox(height: kSpaceMD),
          _Row(label: 'Shipping', value: formatPrice(shipping)),
          const SizedBox(height: kSpaceMD),
          _Row(label: 'Shipping Insurance', value: formatPrice(insurance)),
          const SizedBox(height: kSpaceMD),
          _Row(
            label: 'Voucher Discount',
            value: discount > 0 ? '-${formatPrice(discount)}' : formatPrice(0),
            valueColor: discount > 0 ? Colors.green.shade700 : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: kSpaceLG),
            child: Divider(color: kBorderColor, thickness: 1),
          ),
          _Row(
            label: 'Grand Total',
            value: formatPrice(grandTotal),
            bold: true,
            valueColor: kPrimaryColor,
            fontSize: 20,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
    this.fontSize,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: base?.copyWith(
            fontSize: fontSize,
            color: kTextSecondaryColor,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: base?.copyWith(
            fontSize: fontSize,
            color: valueColor ?? kTextPrimaryColor,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Bottom action bar ───────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.cart});

  final CartsProvider cart;

  @override
  Widget build(BuildContext context) {
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
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              final auth = context.read<AuthProvider>();
              if (!auth.isLoggedIn) {
                Navigator.pushNamed(context, '/login');
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CheckoutScreen()),
              );
            },
            child: Text(
              cart.hasItems
                  ? 'Checkout (${cart.itemCount} ${cart.itemCount > 1 ? 'items' : 'item'})'
                  : 'Checkout (0 items)',
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _VoucherSheet — bottom sheet for selecting / entering a voucher code.
// ---------------------------------------------------------------------------

class _VoucherSheet extends StatefulWidget {
  const _VoucherSheet({
    required this.subtotal,
    required this.onVoucherApplied,
    this.currentApplied,
  });

  final int subtotal;
  final void Function(String code, int discount) onVoucherApplied;
  final String? currentApplied;

  @override
  State<_VoucherSheet> createState() => _VoucherSheetState();
}

class _VoucherSheetState extends State<_VoucherSheet> {
  final TextEditingController _codeController = TextEditingController();
  String? _selectedCode;

  @override
  void initState() {
    super.initState();
    _selectedCode = widget.currentApplied;

    Future.microtask(() {
      if (!mounted) return;
      final token = context.read<AuthProvider>().token;
      if (token != null && token.isNotEmpty) {
        context.read<VouchersProvider>().loadVouchers(token);
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────────

  String _formatPrice(int price) =>
      'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  void _applyCode() {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    final vouchers = context.read<VouchersProvider>().vouchers;
    final match = vouchers.where((v) => v.code == code).firstOrNull;

    if (match == null) {
      _showSnack('Voucher code not found', isError: true);
      return;
    }
    if (match.isExpired) {
      _showSnack('This voucher has expired', isError: true);
      return;
    }

    setState(() => _selectedCode = code);
    _codeController.clear();
    FocusScope.of(context).unfocus();
  }

  void _applySelected() {
    if (_selectedCode == null) return;

    final voucher = context.read<VouchersProvider>().vouchers.firstWhere(
      (v) => v.code == _selectedCode,
    );

    if (widget.subtotal < voucher.minOrder) {
      _showSnack(
        'Minimum purchase ${_formatPrice(voucher.minOrder.toInt())} required',
        isWarning: true,
      );
      return;
    }

    int discount = 0;
    if (voucher.type == DiscountType.percentage) {
      discount = (widget.subtotal * voucher.value / 100).round();
      if (voucher.maxDiscount != null && discount > voucher.maxDiscount!) {
        discount = voucher.maxDiscount!.toInt();
      }
    } else {
      discount = voucher.value.toInt();
    }

    context.read<CartsProvider>().applyVoucher(
      code: _selectedCode!,
      discount: discount,
    );

    widget.onVoucherApplied(_selectedCode!, discount);
    Navigator.pop(context);
    _showSnack('Voucher "$_selectedCode" applied!', isSuccess: true);
  }

  void _reset() {
    setState(() => _selectedCode = null);
    widget.onVoucherApplied('', 0);
    Navigator.pop(context);
  }

  void _showSnack(
    String msg, {
    bool isError = false,
    bool isWarning = false,
    bool isSuccess = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError
            ? kErrorColor
            : isWarning
            ? Colors.orange.shade700
            : isSuccess
            ? Colors.green.shade700
            : null,
      ),
    );
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kScaffoldBgColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(kSpace2XL)),
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Padding(
          padding: EdgeInsets.only(
            left: kSpaceXL,
            right: kSpaceXL,
            top: kSpaceXL,
            bottom: MediaQuery.of(context).viewInsets.bottom + kSpaceXL,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: kBorderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: kSpaceLG),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Use Voucher',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: kScaffoldBgColor,
                      padding: const EdgeInsets.all(kSpaceSM),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: kSpaceXL),

              // Code input + apply
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        hintText: 'Enter voucher code',
                      ),
                    ),
                  ),
                  const SizedBox(width: kSpaceMD),
                  ElevatedButton(
                    onPressed: _applyCode,
                    child: const Text('Apply'),
                  ),
                ],
              ),
              const SizedBox(height: kSpace2XL),

              // OR divider
              Row(
                children: [
                  Expanded(child: Divider(color: kBorderColor)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: kSpaceMD),
                    child: Text(
                      'OR',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: kTextSecondaryColor,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: kBorderColor)),
                ],
              ),
              const SizedBox(height: kSpaceXL),

              Text(
                'Available Vouchers',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: kSpaceMD),

              // Voucher list
              Expanded(
                child: Consumer<VouchersProvider>(
                  builder: (_, vp, _) {
                    if (vp.loading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (vp.vouchers.isEmpty) {
                      return Center(
                        child: Text(
                          'No vouchers available',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: kTextSecondaryColor),
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      itemCount: vp.vouchers.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: kSpaceMD),
                      itemBuilder: (_, i) {
                        final v = vp.vouchers[i];
                        return _VoucherCard(
                          voucher: v,
                          isSelected: _selectedCode == v.code,
                          onTap: () => setState(
                            () => _selectedCode = _selectedCode == v.code
                                ? null
                                : v.code,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: kSpaceLG),

              // Bottom buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reset,
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: kSpaceMD),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _selectedCode != null ? _applySelected : null,
                      child: Text(
                        _selectedCode != null
                            ? 'Apply Voucher'
                            : 'Select a Voucher',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Voucher card ────────────────────────────────────────────────────────────

class _VoucherCard extends StatelessWidget {
  const _VoucherCard({
    required this.voucher,
    required this.isSelected,
    required this.onTap,
  });

  final Voucher voucher;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isExpired = voucher.isExpired;

    final List<Color> badgeColors = voucher.type == DiscountType.percentage
        ? [Colors.orange.shade400, Colors.deepOrange.shade600]
        : [Colors.blue.shade400, Colors.indigo.shade600];

    final String valueLabel = voucher.type == DiscountType.percentage
        ? '${voucher.value.toInt()}%'
        : 'Rp ${voucher.value.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

    final diff = voucher.endAt.difference(DateTime.now());
    final String expiry = isExpired
        ? 'Expired'
        : diff.inDays > 0
        ? 'Expires in ${diff.inDays}d'
        : 'Expires in ${diff.inHours}h';

    return Opacity(
      opacity: isExpired ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: isExpired ? null : onTap,
        child: Container(
          decoration: BoxDecoration(
            color: kSurfaceColor,
            borderRadius: BorderRadius.circular(kRadiusLG),
            border: Border.all(
              color: isSelected ? kPrimaryColor : kBorderColor,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? kPrimaryColor.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Left badge
              Container(
                width: 72,
                padding: const EdgeInsets.symmetric(vertical: kSpaceXL),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isExpired
                        ? [Colors.grey.shade400, Colors.grey.shade600]
                        : badgeColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(kRadiusLG - 2),
                    bottomLeft: Radius.circular(kRadiusLG - 2),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      voucher.type == DiscountType.percentage
                          ? Icons.percent_outlined
                          : Icons.local_offer_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(height: kSpaceXS + 2),
                    Text(
                      valueLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Dashed separator
              Column(
                children: List.generate(
                  6,
                  (_) => Container(
                    width: 1,
                    height: 6,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: kBorderColor,
                  ),
                ),
              ),

              // Right content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kSpaceMD,
                    vertical: kSpaceMD,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              voucher.title,
                              style: Theme.of(context).textTheme.titleSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: kPrimaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: kSpaceXS),
                      Text(
                        voucher.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: kSpaceSM),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: kSpaceSM,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: kScaffoldBgColor,
                              borderRadius: BorderRadius.circular(kSpaceXS + 2),
                            ),
                            child: Text(
                              voucher.code,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            expiry,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: isExpired
                                      ? kErrorColor
                                      : kTextSecondaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
