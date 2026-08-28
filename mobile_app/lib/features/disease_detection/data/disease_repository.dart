import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/prediction_result.dart';

/// Calls the backend disease-detection endpoint.
class DiseaseRepository {
  DiseaseRepository({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<PredictionResult> predict({
    required String imagePath,
    required String crop,
  }) async {
    final String? token = await _tokenStorage.readToken();
    final Map<String, dynamic> json = await _apiClient.postMultipart(
      '/disease/predict',
      filePath: imagePath,
      fileField: 'image',
      fields: {'crop': crop},
      token: token,
    );
    return PredictionResult.fromJson(json);
  }
}
