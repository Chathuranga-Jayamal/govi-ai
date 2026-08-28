import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/order.dart';

/// Calls the backend orders endpoints.
class OrderRepository {
  OrderRepository({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<List<Order>> getOrders() async {
    final String? token = await _tokenStorage.readToken();
    final List<dynamic> json = await _apiClient.getList('/orders', token: token);
    return json
        .map((entry) => Order.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<Order> placeOrder({
    required String deliveryAddress,
    required String paymentMethod,
  }) async {
    final String? token = await _tokenStorage.readToken();
    final Map<String, dynamic> json = await _apiClient.post(
      '/orders',
      token: token,
      body: {
        'delivery_address': deliveryAddress,
        'payment_method': paymentMethod,
      },
    );
    return Order.fromJson(json);
  }
}
