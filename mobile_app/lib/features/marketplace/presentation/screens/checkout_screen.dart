import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/state/cart_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

enum _PaymentMethod {
  cashOnDelivery,
  cardPayment,
  payHere;

  String get label {
    switch (this) {
      case _PaymentMethod.cashOnDelivery:
        return 'Cash on Delivery';
      case _PaymentMethod.cardPayment:
        return 'Card Payment';
      case _PaymentMethod.payHere:
        return 'PayHere';
    }
  }

  IconData get icon {
    switch (this) {
      case _PaymentMethod.cashOnDelivery:
        return Icons.local_shipping_outlined;
      case _PaymentMethod.cardPayment:
        return Icons.credit_card;
      case _PaymentMethod.payHere:
        return Icons.account_balance_wallet_outlined;
    }
  }
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  _PaymentMethod _selectedMethod = _PaymentMethod.cashOnDelivery;

  void _placeOrder(CartController controller) {
    final String orderNumber =
        'GOVI-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    // Real payment processing is backend Phase G2, out of scope here —
    // this just clears the mock cart and shows a confirmation.
    controller.clear();
    context.pushReplacement(
      '/marketplace/order-confirmation',
      extra: orderNumber,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final CartController controller = CartScope.of(context);
    final List<CartItem> items = controller.items;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Order Summary', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      for (final item in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.product.name} × ${item.quantity}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                              Text(
                                'Rs. ${item.lineTotal.toStringAsFixed(0)}',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      const Divider(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total', style: theme.textTheme.titleMedium),
                          Text(
                            'Rs. ${controller.totalPrice.toStringAsFixed(0)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.paddyGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              Text('Delivery Address', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.paddyGreen,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kumara Silva',
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '124/3 Temple Road, Anuradhapura, North '
                              'Central Province, Sri Lanka',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.soilInkSoft,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '077 123 4567',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.soilInkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              Text('Payment Method', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              for (final method in _PaymentMethod.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _PaymentMethodCard(
                    method: method,
                    selected: _selectedMethod == method,
                    onTap: () => setState(() => _selectedMethod = method),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),

              FilledButton(
                onPressed: items.isEmpty ? null : () => _placeOrder(controller),
                child: const Text('Place Order'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final _PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.paddyGreenContainer
                : AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.paddyGreen : AppColors.hairline,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                method.icon,
                color: selected
                    ? AppColors.paddyGreenOnContainer
                    : AppColors.soilInkSoft,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(method.label, style: theme.textTheme.titleSmall),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? AppColors.paddyGreen : AppColors.soilInkSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
