import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/state/cart_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/product.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  CartController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final CartController controller = CartScope.of(context);
    if (_controller != controller) {
      _controller?.removeListener(_onCartChanged);
      _controller = controller..addListener(_onCartChanged);
    }
  }

  void _onCartChanged() => setState(() {});

  @override
  void dispose() {
    _controller?.removeListener(_onCartChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CartController? controller = _controller;
    final List<CartItem> items = controller?.items ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: SafeArea(
        child: items.isEmpty
            ? const _EmptyCart()
            : Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: items.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final CartItem item = items[index];
                        return _CartItemRow(
                          item: item,
                          onIncrement: () => controller!.updateQuantity(
                            item.product.id,
                            item.quantity + 1,
                          ),
                          onDecrement: () => controller!.updateQuantity(
                            item.product.id,
                            item.quantity - 1,
                          ),
                          onRemove: () =>
                              controller!.removeItem(item.product.id),
                        );
                      },
                    ),
                  ),
                  _OrderSummary(
                    total: controller?.totalPrice ?? 0,
                    onCheckout: () => context.push('/marketplace/checkout'),
                  ),
                ],
              ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shopping_cart_outlined,
              color: AppColors.soilInkSoft,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Your cart is empty', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Browse the marketplace to add fertilizers, pesticides, '
              'and tools.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.soilInkSoft,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => context.go('/marketplace'),
              child: const Text('Back to Marketplace'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemRow extends StatelessWidget {
  const _CartItemRow({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Product product = item.product;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.paddyGreenContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                product.imageIcon,
                color: AppColors.paddyGreenOnContainer,
                size: 26,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.priceLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.paddyGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      IconButton(
                        onPressed: onDecrement,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: AppColors.paddyGreen,
                        visualDensity: VisualDensity.compact,
                      ),
                      Text(
                        '${item.quantity}',
                        style: theme.textTheme.titleSmall,
                      ),
                      IconButton(
                        onPressed: onIncrement,
                        icon: const Icon(Icons.add_circle_outline),
                        color: AppColors.paddyGreen,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline),
              color: AppColors.alertRed,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.total, required this.onCheckout});

  final double total;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String totalLabel = 'Rs. ${total.toStringAsFixed(0)}';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surfaceRaised,
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: theme.textTheme.bodyMedium),
              Text(totalLabel, style: theme.textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: theme.textTheme.titleMedium),
              Text(
                totalLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.paddyGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: onCheckout,
            child: const Text('Proceed to Checkout'),
          ),
        ],
      ),
    );
  }
}
