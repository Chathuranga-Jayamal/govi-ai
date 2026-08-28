import '../../../core/network/api_client.dart';
import '../domain/product.dart';

/// Calls the backend product-catalog endpoints. Public endpoints — no
/// token needed.
class ProductRepository {
  ProductRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Product>> getProducts({
    ProductCategory? category,
    bool? bestSeller,
  }) async {
    final List<dynamic> json = await _apiClient.getList(
      '/products',
      queryParameters: {
        if (category != null) 'category': category.name,
        if (bestSeller != null) 'best_seller': bestSeller.toString(),
      },
    );
    return json
        .map((entry) => Product.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<Product> getProduct(int id) async {
    final Map<String, dynamic> json = await _apiClient.get('/products/$id');
    return Product.fromJson(json);
  }
}
