import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/product_repository.dart';
import '../../domain/product.dart';
import '../widgets/cart_icon_button.dart';
import '../widgets/product_card.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductRepository _productRepository = ProductRepository();

  ProductCategory? _selectedCategory;

  // Best Sellers always reflects the full catalog and is fetched once —
  // unaffected by the category chips below, matching the previous
  // mock-data behavior where it never moved when filtering.
  List<Product>? _bestSellers;
  String? _bestSellersError;

  // The grid is re-fetched from the server every time a category chip is
  // tapped (server-side filtering), per the real query param replacing
  // the old local in-memory filter.
  List<Product>? _gridProducts;
  bool _isLoadingGrid = true;
  String? _gridError;

  @override
  void initState() {
    super.initState();
    _loadBestSellers();
    _loadGrid();
  }

  Future<void> _loadBestSellers() async {
    setState(() => _bestSellersError = null);
    try {
      final List<Product> products = await _productRepository.getProducts(
        bestSeller: true,
      );
      if (!mounted) return;
      setState(() => _bestSellers = products);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _bestSellersError = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _bestSellersError = 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> _loadGrid() async {
    setState(() {
      _isLoadingGrid = true;
      _gridError = null;
    });
    try {
      final List<Product> products = await _productRepository.getProducts(
        category: _selectedCategory,
      );
      if (!mounted) return;
      setState(() {
        _gridProducts = products;
        _isLoadingGrid = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _gridError = error.message;
        _isLoadingGrid = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _gridError = 'Something went wrong. Please try again.';
        _isLoadingGrid = false;
      });
    }
  }

  void _selectCategory(ProductCategory? category) {
    setState(() => _selectedCategory = category);
    _loadGrid();
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
                    SizedBox(height: 196, child: _buildBestSellers()),
                    const SizedBox(height: AppSpacing.lg),
                    Text('All Products', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _selectedCategory == null,
                          onSelected: (_) => _selectCategory(null),
                        ),
                        for (final category in ProductCategory.values)
                          ChoiceChip(
                            label: Text(category.label),
                            selected: _selectedCategory == category,
                            onSelected: (_) => _selectCategory(category),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
            ..._buildGridSlivers(),
            const SliverPadding(
              padding: EdgeInsets.only(bottom: AppSpacing.lg),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBestSellers() {
    if (_bestSellersError != null) {
      return _InlineRetry(
        message: _bestSellersError!,
        onRetry: _loadBestSellers,
      );
    }
    final List<Product>? bestSellers = _bestSellers;
    if (bestSellers == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (bestSellers.isEmpty) {
      return const Center(child: Text('No best sellers right now.'));
    }
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: bestSellers.length,
      separatorBuilder: (context, index) =>
          const SizedBox(width: AppSpacing.sm),
      itemBuilder: (context, index) {
        final Product product = bestSellers[index];
        return SizedBox(
          width: 156,
          child: ProductCard(product: product, onTap: () => _openProduct(product)),
        );
      },
    );
  }

  List<Widget> _buildGridSlivers() {
    if (_isLoadingGrid) {
      return [
        const SliverPadding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xl * 2),
          sliver: SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ];
    }
    if (_gridError != null) {
      return [
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          sliver: SliverToBoxAdapter(
            child: _InlineRetry(message: _gridError!, onRetry: _loadGrid),
          ),
        ),
      ];
    }
    final List<Product> products = _gridProducts ?? const [];
    if (products.isEmpty) {
      return [
        const SliverPadding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xl * 2),
          sliver: SliverToBoxAdapter(
            child: Center(child: Text('No products found.')),
          ),
        ),
      ];
    }
    return [
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
            final Product product = products[index];
            return ProductCard(product: product, onTap: () => _openProduct(product));
          }, childCount: products.length),
        ),
      ),
    ];
  }
}

class _InlineRetry extends StatelessWidget {
  const _InlineRetry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.alertRed,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
