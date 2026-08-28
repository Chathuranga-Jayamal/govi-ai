import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';

/// Thin JSON HTTP client for calling the Govi-AI backend.
class ApiClient {
  ApiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final Uri uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final http.Response response;
    try {
      response = await _httpClient.post(
        uri,
        headers: _headers(token),
        body: jsonEncode(body ?? const {}),
      );
    } catch (_) {
      throw const ApiException(
        'Could not reach the server. Check your connection and try again.',
      );
    }
    return _decode(response);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final Uri uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final http.Response response;
    try {
      response = await _httpClient.patch(
        uri,
        headers: _headers(token),
        body: jsonEncode(body ?? const {}),
      );
    } catch (_) {
      throw const ApiException(
        'Could not reach the server. Check your connection and try again.',
      );
    }
    return _decode(response);
  }

  Future<Map<String, dynamic>> get(String path, {String? token}) async {
    final Uri uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final http.Response response;
    try {
      response = await _httpClient.get(uri, headers: _headers(token));
    } catch (_) {
      throw const ApiException(
        'Could not reach the server. Check your connection and try again.',
      );
    }
    return _decode(response);
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required String filePath,
    required String fileField,
    Map<String, String>? fields,
    String? token,
  }) async {
    final Uri uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final http.MultipartRequest request = http.MultipartRequest('POST', uri);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.fields.addAll(fields ?? const {});
    request.files.add(await http.MultipartFile.fromPath(fileField, filePath));

    final http.Response response;
    try {
      final http.StreamedResponse streamed = await _httpClient.send(request);
      response = await http.Response.fromStream(streamed);
    } catch (_) {
      throw const ApiException(
        'Could not reach the server. Check your connection and try again.',
      );
    }
    return _decode(response);
  }

  Map<String, String> _headers(String? token) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Map<String, dynamic> _decode(http.Response response) {
    final dynamic decoded = response.body.isEmpty
        ? {}
        : jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded as Map<String, dynamic>;
    }

    final String message =
        (decoded is Map<String, dynamic>
            ? decoded['detail']?.toString()
            : null) ??
        'Something went wrong. Please try again.';
    throw ApiException(message, statusCode: response.statusCode);
  }
}
