import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/auth_user.dart';

/// Calls the backend auth endpoints and persists the resulting JWT.
class AuthRepository {
  AuthRepository({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<AuthUser> register({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    String? preferredLanguage,
  }) async {
    final Map<String, dynamic> json = await _apiClient.post(
      '/auth/register',
      body: {
        'full_name': fullName,
        'email': email,
        'password': password,
        'phone_number': ?phoneNumber,
        'preferred_language': ?preferredLanguage,
      },
    );
    return AuthUser.fromJson(json);
  }

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final Map<String, dynamic> json = await _apiClient.post(
      '/auth/login',
      body: {'email': email, 'password': password},
    );
    await _tokenStorage.saveToken(json['access_token'] as String);
    return AuthUser.fromJson(json['user'] as Map<String, dynamic>);
  }

  Future<void> logout() => _tokenStorage.clearToken();

  Future<AuthUser> getCurrentUser() async {
    final String? token = await _tokenStorage.readToken();
    final Map<String, dynamic> json = await _apiClient.get(
      '/auth/me',
      token: token,
    );
    return AuthUser.fromJson(json);
  }

  Future<AuthUser> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? preferredLanguage,
  }) async {
    final String? token = await _tokenStorage.readToken();
    final Map<String, dynamic> json = await _apiClient.patch(
      '/auth/me',
      token: token,
      body: {
        'full_name': ?fullName,
        'phone_number': ?phoneNumber,
        'preferred_language': ?preferredLanguage,
      },
    );
    return AuthUser.fromJson(json);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final String? token = await _tokenStorage.readToken();
    await _apiClient.post(
      '/auth/change-password',
      token: token,
      body: {'current_password': currentPassword, 'new_password': newPassword},
    );
  }
}
