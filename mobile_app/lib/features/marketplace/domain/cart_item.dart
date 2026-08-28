import 'product.dart';

/// Result of a cart-endpoint call. Immutable — the cart's source of truth
/// is always the server's response, never a local mutation.
class CartItem {
  const CartItem({required this.id, required this.product, required this.quantity});

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: json['id'] as int,
    product: Product.fromJson(json['product'] as Map<String, dynamic>),
    quantity: json['quantity'] as int,
  );

  final int id;
  final Product product;
  final int quantity;

  double get lineTotal => product.price * quantity;
}
