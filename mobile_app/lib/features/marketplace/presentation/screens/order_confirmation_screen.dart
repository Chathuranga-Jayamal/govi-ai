import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({required this.orderNumber, super.key});

  final String orderNumber;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.paddyGreenContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.paddyGreen,
                    size: 52,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Order Placed!', style: theme.textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Your order has been placed successfully. You\'ll '
                  'receive a call to confirm delivery details.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.soilInkSoft,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.turmericGoldContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Order #$orderNumber',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.turmericGoldOnContainer,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: () => context.go('/marketplace'),
                  child: const Text('Back to Marketplace'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
