import 'package:flutter/material.dart';

import '../../features/marketplace/domain/product.dart';

class CartItem {
  CartItem({required this.product, required this.quantity});

  final Product product;
  int quantity;

  double get lineTotal => product.price * quantity;
}

/// Lives above the whole app (see [CartScope], wrapped around
/// `MaterialApp.router` in app.dart) rather than in MainShell like
/// [AdvisoryChatController]. Unlike Advisory (only ever read from a shell
/// branch screen), Cart also needs to be reachable from the Product
/// Detail, Cart, Checkout, and Order Confirmation screens — all top-level
/// routes declared outside `StatefulShellRoute` (same pattern as
/// `/capture/result`) so they render full-screen without the bottom nav.
/// Those routes are pushed on the app's root Navigator, which sits above
/// MainShell, not inside it — so MainShell isn't a common ancestor of all
/// of them the way it is for AdvisoryChatScreen.
class CartController extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalItemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice =>
      _items.fold(0.0, (sum, item) => sum + item.lineTotal);

  void addItem(Product product, int quantity) {
    final int index = _items.indexWhere(
      (item) => item.product.id == product.id,
    );
    if (index >= 0) {
      _items[index].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
    notifyListeners();
  }

  void removeItem(int productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void updateQuantity(int productId, int quantity) {
    final int index = _items.indexWhere((item) => item.product.id == productId);
    if (index < 0) return;

    if (quantity <= 0) {
      _items.removeAt(index);
    } else {
      _items[index].quantity = quantity;
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}

class CartScope extends InheritedNotifier<CartController> {
  const CartScope({
    required CartController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static CartController of(BuildContext context) {
    final CartScope? scope = context
        .dependOnInheritedWidgetOfExactType<CartScope>();
    assert(scope != null, 'CartScope not found in context');
    return scope!.notifier!;
  }
}
