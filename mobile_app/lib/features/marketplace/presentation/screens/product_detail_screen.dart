import 'package:flutter/material.dart';

import '../../../../core/state/cart_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/product.dart';
import '../widgets/cart_icon_button.dart';
import '../widgets/product_image.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({required this.product, super.key});

  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  void _incrementQuantity() => setState(() => _quantity++);

  void _decrementQuantity() {
    if (_quantity > 1) setState(() => _quantity--);
  }

  void _addToCart() {
    CartScope.of(context).addItem(widget.product, _quantity);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $_quantity × ${widget.product.name} to cart'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Product product = widget.product;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: const [CartIconButton()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 200,
                width: double.infinity,
                child: ProductImage(
                  imageUrl: product.imageUrl,
                  backgroundColor: AppColors.paddyGreenContainer,
                  iconColor: AppColors.paddyGreenOnContainer,
                  borderRadius: 16,
                  iconSize: 72,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              Text(
                product.category.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.soilInkSoft,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(product.name, style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text(
                    product.priceLabel,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.paddyGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Icon(
                    Icons.star_rounded,
                    color: AppColors.turmericGold,
                    size: 18,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    product.rating.toStringAsFixed(1),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              if (product.description != null) ...[
                Text(product.description!, style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.xl),
              ],

              if (product.usageInstructions != null) ...[
                Text('How to Use', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  product.usageInstructions!,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

              if (product.warningText != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.turmericGoldContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.turmericGold),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.turmericGoldOnContainer,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          product.warningText!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.turmericGoldOnContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),

              Row(
                children: [
                  Text('Quantity', style: theme.textTheme.titleMedium),
                  const Spacer(),
                  IconButton(
                    onPressed: _decrementQuantity,
                    icon: const Icon(Icons.remove_circle_outline),
                    color: AppColors.paddyGreen,
                  ),
                  Text('$_quantity', style: theme.textTheme.titleMedium),
                  IconButton(
                    onPressed: _incrementQuantity,
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppColors.paddyGreen,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              FilledButton.icon(
                onPressed: _addToCart,
                icon: const Icon(Icons.shopping_cart_outlined),
                label: const Text('Add to Cart'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
