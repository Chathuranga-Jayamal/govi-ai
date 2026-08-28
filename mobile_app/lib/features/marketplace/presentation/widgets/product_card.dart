import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/product.dart';
import 'product_image.dart';

(Color container, Color onContainer) _categoryColors(ProductCategory category) {
  switch (category) {
    case ProductCategory.fertilizer:
      return (AppColors.paddyGreenContainer, AppColors.paddyGreenOnContainer);
    case ProductCategory.pesticide:
      return (AppColors.monsoonTealContainer, AppColors.monsoonTealOnContainer);
    case ProductCategory.tools:
      return (
        AppColors.turmericGoldContainer,
        AppColors.turmericGoldOnContainer,
      );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({required this.product, required this.onTap, super.key});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final (Color container, Color onContainer) = _categoryColors(
      product.category,
    );

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.4,
                    child: ProductImage(
                      imageUrl: product.imageUrl,
                      backgroundColor: container,
                      iconColor: onContainer,
                      borderRadius: 12,
                      iconSize: 32,
                    ),
                  ),
                  if (product.isBestSeller)
                    Positioned(
                      top: AppSpacing.xs,
                      left: AppSpacing.xs,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm - 2,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.paddyGreen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Best Seller',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.riceHusk,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 2),
              Text(
                product.priceLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.paddyGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: AppColors.turmericGold,
                    size: 16,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    product.rating.toStringAsFixed(1),
                    style: theme.textTheme.bodySmall,
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
