import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/advisory_result.dart';

/// Calls the backend RAG advisory endpoint.
class AdvisoryRepository {
  AdvisoryRepository({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  // The LLM call behind this endpoint can currently take 60-100+ seconds
  // (known free-tier latency, tracked separately) — the default has no
  // timeout at all, so this needs a generous one rather than hanging
  // forever on a stalled connection.
  static const Duration _timeout = Duration(minutes: 3);

  Future<AdvisoryResult> postAdvisory({
    required String message,
    String? crop,
    String? disease,
    required String language,
    required List<Map<String, String>> conversationHistory,
  }) async {
    final String? token = await _tokenStorage.readToken();
    final Map<String, dynamic> json = await _apiClient.post(
      '/advisory',
      token: token,
      timeout: _timeout,
      body: {
        'message': message,
        'crop': ?crop,
        'disease': ?disease,
        'language': language,
        'conversation_history': conversationHistory,
      },
    );
    return AdvisoryResult.fromJson(json);
  }
}
