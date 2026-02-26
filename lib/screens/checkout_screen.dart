import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/carts_model.dart';
import '../providers/carts_provider.dart';
import '../utilities/constants.dart';
import '../widgets/header_widget.dart';

// ---------------------------------------------------------------------------
// CheckoutScreen — order review and payment screen.
// Replaces: checkout_page.dart  →  screens/checkout_screen.dart
// ---------------------------------------------------------------------------

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  static const int _shipping = 15000;
  static const int _insurance = 5000;

  String _formatPrice(int price) =>
      'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBgColor,
      appBar: const HeaderWidget(),
      body: Consumer<CartsProvider>(
        builder: (_, cart, _) {
          if (cart.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(kSpaceLG),
            child: Column(
              children: [
                const _AddressCard(),
                const SizedBox(height: kSpaceLG),
                _ShippingCard(formatPrice: _formatPrice, shipping: _shipping),
                const SizedBox(height: kSpaceLG),
                _ProductsCard(cart: cart, formatPrice: _formatPrice),
                const SizedBox(height: kSpaceLG),
                _SummaryCard(
                  cart: cart,
                  shipping: _shipping,
                  insurance: _insurance,
                  formatPrice: _formatPrice,
                ),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Consumer<CartsProvider>(
        builder: (context, cart, _) => _BottomPayBar(
          cart: cart,
          shipping: _shipping,
          insurance: _insurance,
          formatPrice: _formatPrice,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

// ─── Shared card wrapper ────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
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
    child: child,
  );
}

// ─── Address card ────────────────────────────────────────────────────────────

class _AddressCard extends StatelessWidget {
  const _AddressCard();

  @override
  Widget build(BuildContext context) => _Card(
    child: Row(
      children: [
        const Icon(Icons.location_on_outlined, color: kPrimaryColor),
        const SizedBox(width: kSpaceMD),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Shipping Address',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: kSpaceXS),
              Text(
                'Msend Five\nPamanukan, Jawa Barat\n0812-XXXX-XXXX',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: kBorderColor),
      ],
    ),
  );
}

// ─── Shipping method card ────────────────────────────────────────────────────

class _ShippingCard extends StatelessWidget {
  const _ShippingCard({required this.formatPrice, required this.shipping});

  final String Function(int) formatPrice;
  final int shipping;

  @override
  Widget build(BuildContext context) => _Card(
    child: Row(
      children: [
        const Icon(Icons.local_shipping_outlined, color: kPrimaryColor),
        const SizedBox(width: kSpaceMD),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Shipping Method',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: kSpaceXS),
              Text(
                'Regular Delivery (2–4 days)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Text(
          formatPrice(shipping),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: kPrimaryColor),
        ),
      ],
    ),
  );
}

// ─── Products list card ──────────────────────────────────────────────────────

class _ProductsCard extends StatelessWidget {
  const _ProductsCard({required this.cart, required this.formatPrice});

  final CartsProvider cart;
  final String Function(int) formatPrice;

  @override
  Widget build(BuildContext context) => _Card(
    child: Column(
      children: cart.items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: kSpaceLG),
              child: _ProductRow(item: item, formatPrice: formatPrice),
            ),
          )
          .toList(),
    ),
  );
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.item, required this.formatPrice});

  final CartItem item;
  final String Function(int) formatPrice;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: kScaffoldBgColor,
          borderRadius: BorderRadius.circular(kRadiusMD - 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kRadiusMD - 2),
          child: Image.network(item.image, fit: BoxFit.contain),
        ),
      ),
      const SizedBox(width: kSpaceMD),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.productName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: kSpaceXS),
            Text(
              item.variantText,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: kTextSecondaryColor),
            ),
            const SizedBox(height: kSpaceXS + 2),
            Text(
              '${item.quantity} × ${formatPrice(item.variantPrice)}',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: kPrimaryColor),
            ),
          ],
        ),
      ),
    ],
  );
}

// ─── Order summary card ──────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.cart,
    required this.shipping,
    required this.insurance,
    required this.formatPrice,
  });

  final CartsProvider cart;
  final int shipping;
  final int insurance;
  final String Function(int) formatPrice;

  @override
  Widget build(BuildContext context) {
    final grandTotal =
        cart.subtotal + shipping + insurance - cart.voucherDiscount;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Summary', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: kSpaceLG),

          _SummaryRow(label: 'Subtotal', value: formatPrice(cart.subtotal)),
          _SummaryRow(label: 'Shipping', value: formatPrice(shipping)),
          _SummaryRow(label: 'Insurance', value: formatPrice(insurance)),

          if (cart.voucherDiscount > 0)
            _SummaryRow(
              label: 'Voucher (${cart.voucherCode})',
              value: '− ${formatPrice(cart.voucherDiscount)}',
              valueColor: Colors.green.shade700,
            ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: kSpaceMD),
            child: Divider(color: kBorderColor),
          ),

          _SummaryRow(
            label: 'Grand Total',
            value: formatPrice(grandTotal),
            bold: true,
            fontSize: 20,
            valueColor: kPrimaryColor,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.fontSize,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool bold;
  final double? fontSize;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.only(bottom: kSpaceSM + 2),
      child: Row(
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
      ),
    );
  }
}

// ─── Bottom pay bar ──────────────────────────────────────────────────────────

class _BottomPayBar extends StatelessWidget {
  const _BottomPayBar({
    required this.cart,
    required this.shipping,
    required this.insurance,
    required this.formatPrice,
  });

  final CartsProvider cart;
  final int shipping;
  final int insurance;
  final String Function(int) formatPrice;

  @override
  Widget build(BuildContext context) {
    final total = cart.subtotal + shipping + insurance - cart.voucherDiscount;

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
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total Payment',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    formatPrice(total),
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: kPrimaryColor),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ElevatedButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Proceed to Payment')),
                ),
                child: const Text('Pay Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
