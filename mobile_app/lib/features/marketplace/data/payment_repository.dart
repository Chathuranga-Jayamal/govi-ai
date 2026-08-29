import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/payhere_checkout.dart';

/// Calls the backend payments endpoints.
class PaymentRepository {
  PaymentRepository({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<PayHereCheckoutData> initiate({required int orderId}) async {
    final String? token = await _tokenStorage.readToken();
    final Map<String, dynamic> json = await _apiClient.post(
      '/payments/initiate',
      token: token,
      body: {'order_id': orderId},
    );
    return PayHereCheckoutData.fromJson(json);
  }
}
