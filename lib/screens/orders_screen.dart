import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/orders_model.dart';
import '../providers/orders_provider.dart';
import '../providers/auth_provider.dart';
import '../utilities/constants.dart';
import '../widgets/header_widget.dart';

// ---------------------------------------------------------------------------
// OrdersScreen
// ---------------------------------------------------------------------------

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        context.read<OrdersProvider>().loadOrders(token);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatPrice(int price) =>
      'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBgColor,
      appBar: const HeaderWidget(),
      body: Column(
        children: [
          _PageHeader(),
          _TabBar(controller: _tabController),
          Expanded(
            child: Consumer<OrdersProvider>(
              builder: (context, op, _) {
                if (op.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (op.error != null) {
                  return _ErrorState(
                    message: op.error!,
                    onRetry: () {
                      final token = context.read<AuthProvider>().token;
                      if (token != null) op.loadOrders(token);
                    },
                  );
                }
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _OrderList(
                      orders: op.activeOrders,
                      emptyMessage: 'No active orders',
                      formatPrice: _formatPrice,
                    ),
                    _OrderList(
                      orders: op.completedOrders,
                      emptyMessage: 'No completed orders',
                      formatPrice: _formatPrice,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _PageHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(kSpaceLG, kSpaceLG, kSpaceLG, 0),
    child: Row(
      children: [
        Text('My Orders', style: Theme.of(context).textTheme.headlineSmall),
        const Spacer(),
        Consumer<OrdersProvider>(
          builder: (_, op, _c) => op.hasOrders
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kSpaceMD,
                    vertical: kSpaceXS,
                  ),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(kRadiusSM),
                  ),
                  child: Text(
                    '${op.orders.length} order${op.orders.length != 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    ),
  );
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: kSpaceLG,
      vertical: kSpaceMD,
    ),
    child: Container(
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(kRadiusMD),
        border: Border.all(color: kBorderColor),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: kPrimaryColor,
          borderRadius: BorderRadius.circular(kRadiusMD - 2),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: kTextSecondaryColor,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Active'),
          Tab(text: 'Completed'),
        ],
      ),
    ),
  );
}

class _OrderList extends StatelessWidget {
  const _OrderList({
    required this.orders,
    required this.emptyMessage,
    required this.formatPrice,
  });

  final List<Order> orders;
  final String emptyMessage;
  final String Function(int) formatPrice;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) return _EmptyState(message: emptyMessage);
    return ListView.separated(
      padding: const EdgeInsets.all(kSpaceLG),
      itemCount: orders.length,
      separatorBuilder: (_, _i) => const SizedBox(height: kSpaceMD),
      itemBuilder: (_, i) =>
          _OrderCard(order: orders[i], formatPrice: formatPrice),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.formatPrice});

  final Order order;
  final String Function(int) formatPrice;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // ── Header ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(kSpaceLG),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderCode,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: kSpaceXS),
                      Text(
                        _formatDate(order.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: kTextSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: order.status),
              ],
            ),
          ),

          Divider(color: kBorderColor, height: 1),

          // ── Items preview ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(kSpaceLG),
            child: Column(
              children: [
                ...order.items.take(2).map((item) => _ItemRow(item: item)),
                if (order.items.length > 2)
                  Padding(
                    padding: const EdgeInsets.only(top: kSpaceSM),
                    child: Text(
                      '+${order.items.length - 2} more item${order.items.length - 2 > 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: kTextSecondaryColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Divider(color: kBorderColor, height: 1),

          // ── Footer ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(kSpaceLG),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${order.itemCount} item${order.itemCount != 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: kTextSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Total',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: kTextSecondaryColor,
                      ),
                    ),
                  ],
                ),
                Text(
                  formatPrice(order.grandTotal),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});
  final OrderItem item;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: kSpaceSM),
    child: Row(
      children: [
        // thumbnail
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: kScaffoldBgColor,
            borderRadius: BorderRadius.circular(kRadiusSM),
            border: Border.all(color: kBorderColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(kRadiusSM - 1),
            child: item.image.isNotEmpty
                ? Image.network(
                    item.image,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.image_not_supported_outlined,
                      size: 20,
                      color: kBorderColor,
                    ),
                  )
                : const Icon(
                    Icons.image_not_supported_outlined,
                    size: 20,
                    color: kBorderColor,
                  ),
          ),
        ),
        const SizedBox(width: kSpaceMD),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                item.variantText,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: kTextSecondaryColor),
              ),
            ],
          ),
        ),
        Text(
          'x${item.quantity}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: kTextSecondaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      OrderStatus.pending => (Colors.orange.shade50, Colors.orange.shade700),
      OrderStatus.processing => (Colors.blue.shade50, Colors.blue.shade700),
      OrderStatus.shipped => (Colors.purple.shade50, Colors.purple.shade700),
      OrderStatus.delivered => (Colors.green.shade50, Colors.green.shade700),
      OrderStatus.cancelled => (Colors.red.shade50, Colors.red.shade700),
      OrderStatus.unknown => (kScaffoldBgColor, kTextSecondaryColor),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kSpaceMD,
        vertical: kSpaceXS,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(kRadiusSM),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: const BoxDecoration(
            color: kScaffoldBgColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: kBorderColor,
          ),
        ),
        const SizedBox(height: kSpace2XL),
        Text(message, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: kSpaceSM),
        Text(
          'Your orders will appear here',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: kTextSecondaryColor),
        ),
      ],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(kSpace3XL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: kErrorColor),
          const SizedBox(height: kSpaceLG),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: kTextSecondaryColor),
          ),
          const SizedBox(height: kSpace2XL),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    ),
  );
}
