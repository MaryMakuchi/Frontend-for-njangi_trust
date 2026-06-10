import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import 'secure_storage_service.dart';

class ApiService {
  ApiService({
    http.Client? client,
    SecureStorageService? storage,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? SecureStorageService(),
        _baseUrl = baseUrl ?? AppConstants.apiBaseUrl;

  final http.Client _client;
  final SecureStorageService _storage;
  final String _baseUrl;

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await _storage.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<http.Response> get(String path, {bool auth = true}) async {
    final uri = Uri.parse('$_baseUrl$path');
    return _client
        .get(uri, headers: await _headers(auth: auth))
        .timeout(AppConstants.apiTimeout);
  }

  Future<http.Response> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    return _client
        .post(
          uri,
          headers: await _headers(auth: auth),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(AppConstants.apiTimeout);
  }

  Future<http.Response> put(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    return _client
        .put(
          uri,
          headers: await _headers(auth: auth),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(AppConstants.apiTimeout);
  }

  Future<http.Response> delete(String path, {bool auth = true}) async {
    final uri = Uri.parse('$_baseUrl$path');
    return _client
        .delete(uri, headers: await _headers(auth: auth))
        .timeout(AppConstants.apiTimeout);
  }

  Future<http.Response> patch(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    return _client
        .patch(
          uri,
          headers: await _headers(auth: auth),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(AppConstants.apiTimeout);
  }
}
