import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/user_profile.dart';

// Desaturated, feature-local tones for the Cancelled badge — deliberately
// not AppColors.alertRed*, so a cancelled order doesn't visually read as
// a real error state elsewhere in the app.
const Color _cancelledBadgeBackground = Color(0xFFE8E1DE);
const Color _cancelledBadgeForeground = Color(0xFF6B5D5A);

(Color background, Color foreground) _statusColors(OrderStatus status) {
  switch (status) {
    case OrderStatus.delivered:
      return (AppColors.paddyGreenContainer, AppColors.paddyGreenOnContainer);
    case OrderStatus.processing:
      return (
        AppColors.turmericGoldContainer,
        AppColors.turmericGoldOnContainer,
      );
    case OrderStatus.cancelled:
      return (_cancelledBadgeBackground, _cancelledBadgeForeground);
  }
}

class OrderCard extends StatelessWidget {
  const OrderCard({required this.order, super.key});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final (Color badgeBackground, Color badgeForeground) = _statusColors(
      order.status,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.monsoonTealContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: AppColors.monsoonTealOnContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.orderNumber, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    '${order.dateLabel} · ${order.itemCountLabel}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  order.totalLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.paddyGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.status.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: badgeForeground,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
