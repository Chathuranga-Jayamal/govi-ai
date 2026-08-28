import 'package:flutter/material.dart';

import '../../features/marketplace/data/cart_repository.dart';
import '../../features/marketplace/domain/cart_item.dart';
import '../../features/marketplace/domain/product.dart';
import '../network/api_exception.dart';

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
///
/// Backed by the real /cart endpoints (see [CartRepository]) — every
/// mutating method calls the server and replaces local state with its
/// response, the same "reflect the real response" principle
/// [CurrentUserController.updateProfile] already uses, rather than
/// optimistically assuming success.
class CartController extends ChangeNotifier {
  CartController({CartRepository? cartRepository})
    : _cartRepository = cartRepository ?? CartRepository();

  final CartRepository _cartRepository;

  List<CartItem> _items = [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _errorMessage;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalItemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice =>
      _items.fold(0.0, (sum, item) => sum + item.lineTotal);

  /// Fetches the real cart from the server. A no-op if already loaded
  /// (unless [force]) or a fetch is already in flight — safe to call
  /// from multiple widgets (e.g. every screen showing [CartIconButton])
  /// without triggering duplicate requests.
  Future<void> load({bool force = false}) async {
    if (_isLoading || (_hasLoaded && !force)) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await _cartRepository.getCart();
      _hasLoaded = true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds [product] to the cart (or increments it server-side if already
  /// present). Rethrows on failure so the calling screen can show its own
  /// error feedback; local state is left untouched until the server
  /// confirms.
  Future<void> addItem(Product product, int quantity) async {
    final CartItem updated = await _cartRepository.addItem(
      productId: product.id,
      quantity: quantity,
    );
    final int index = _items.indexWhere((item) => item.id == updated.id);
    _items = index >= 0
        ? (List<CartItem>.of(_items)..[index] = updated)
        : [..._items, updated];
    notifyListeners();
  }

  /// Updates a cart row by its own id (not the product id — a cart item
  /// is addressed by `cart_item_id` server-side). A quantity of 0 or
  /// below removes the row, matching the old local-only behavior.
  Future<void> updateQuantity(int cartItemId, int quantity) async {
    if (quantity <= 0) {
      await removeItem(cartItemId);
      return;
    }

    final CartItem updated = await _cartRepository.updateQuantity(
      cartItemId: cartItemId,
      quantity: quantity,
    );
    final int index = _items.indexWhere((item) => item.id == cartItemId);
    if (index < 0) return;
    _items = List<CartItem>.of(_items)..[index] = updated;
    notifyListeners();
  }

  Future<void> removeItem(int cartItemId) async {
    await _cartRepository.removeItem(cartItemId);
    _items = _items.where((item) => item.id != cartItemId).toList();
    notifyListeners();
  }

  /// Resets local state after a successful order placement — the server
  /// already cleared `cart_items` as part of placing the order, so this
  /// is a local-only reset, not a separate API call.
  void clear() {
    _items = [];
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
