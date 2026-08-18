import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/product.dart';
import '../widgets/cart_icon_button.dart';
import '../widgets/product_card.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  ProductCategory? _selectedCategory;

  static final List<Product> _bestSellers = mockProducts
      .where((product) => product.isBestSeller)
      .toList();

  List<Product> get _filteredProducts {
    if (_selectedCategory == null) return mockProducts;
    return mockProducts
        .where((product) => product.category == _selectedCategory)
        .toList();
  }

  void _openProduct(Product product) {
    context.push('/marketplace/product', extra: product);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Text('Marketplace', style: theme.textTheme.headlineSmall),
                    const Spacer(),
                    const CartIconButton(),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    Text('Best Sellers', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 196,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _bestSellers.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final Product product = _bestSellers[index];
                          return SizedBox(
                            width: 156,
                            child: ProductCard(
                              product: product,
                              onTap: () => _openProduct(product),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('All Products', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _selectedCategory == null,
                          onSelected: (_) {
                            setState(() => _selectedCategory = null);
                          },
                        ),
                        for (final category in ProductCategory.values)
                          ChoiceChip(
                            label: Text(category.label),
                            selected: _selectedCategory == category,
                            onSelected: (_) {
                              setState(() => _selectedCategory = category);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final Product product = _filteredProducts[index];
                  return ProductCard(
                    product: product,
                    onTap: () => _openProduct(product),
                  );
                }, childCount: _filteredProducts.length),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.only(bottom: AppSpacing.lg),
            ),
          ],
        ),
      ),
    );
  }
}
