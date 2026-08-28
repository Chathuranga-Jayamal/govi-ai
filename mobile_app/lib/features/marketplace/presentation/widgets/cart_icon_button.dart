import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/state/cart_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class CartIconButton extends StatefulWidget {
  const CartIconButton({super.key});

  @override
  State<CartIconButton> createState() => _CartIconButtonState();
}

class _CartIconButtonState extends State<CartIconButton> {
  CartController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final CartController controller = CartScope.of(context);
    if (_controller != controller) {
      _controller?.removeListener(_onCartChanged);
      _controller = controller..addListener(_onCartChanged);
      // No-op if already loaded or a fetch is in flight — this button is
      // rendered on Dashboard/Marketplace/Product Detail/Cart, so this
      // reliably fires the real cart fetch exactly once, whichever of
      // those screens the user reaches first.
      Future.microtask(controller.load);
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
    final ThemeData theme = Theme.of(context);
    final int count = _controller?.totalItemCount ?? 0;

    return IconButton(
      onPressed: () => context.push('/marketplace/cart'),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.shopping_cart_outlined),
          if (count > 0)
            Positioned(
              right: -6,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 1,
                ),
                constraints: const BoxConstraints(minWidth: 18),
                decoration: const BoxDecoration(
                  color: AppColors.alertRed,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
