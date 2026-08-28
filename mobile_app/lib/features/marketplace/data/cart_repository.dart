import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/cart_item.dart';

/// Calls the backend cart endpoints.
class CartRepository {
  CartRepository({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<List<CartItem>> getCart() async {
    final String? token = await _tokenStorage.readToken();
    final List<dynamic> json = await _apiClient.getList('/cart', token: token);
    return json
        .map((entry) => CartItem.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<CartItem> addItem({required int productId, required int quantity}) async {
    final String? token = await _tokenStorage.readToken();
    final Map<String, dynamic> json = await _apiClient.post(
      '/cart/add',
      token: token,
      body: {'product_id': productId, 'quantity': quantity},
    );
    return CartItem.fromJson(json);
  }

  Future<CartItem> updateQuantity({
    required int cartItemId,
    required int quantity,
  }) async {
    final String? token = await _tokenStorage.readToken();
    final Map<String, dynamic> json = await _apiClient.patch(
      '/cart/$cartItemId',
      token: token,
      body: {'quantity': quantity},
    );
    return CartItem.fromJson(json);
  }

  Future<void> removeItem(int cartItemId) async {
    final String? token = await _tokenStorage.readToken();
    await _apiClient.delete('/cart/$cartItemId', token: token);
  }
}
