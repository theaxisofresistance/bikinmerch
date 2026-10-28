import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'http_client.dart' if (dart.library.js_interop) 'http_client_web.dart';
import 'models.dart';

class ApiException implements Exception {
  const ApiException(this.message, [this.status = 0]);
  final String message;
  final int status;
  @override
  String toString() => message;
}

class Api {
  Api({String? baseUrl, http.Client? client, FlutterSecureStorage? storage})
    : baseUrl = (baseUrl ?? defaultBaseUrl).replaceAll(RegExp(r'/$'), ''),
      _client = client ?? createClient(),
      _storage = storage ?? const FlutterSecureStorage();
  static String get defaultBaseUrl {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) return configured;
    if (kIsWeb) {
      return Uri.base.port == 5000 ? 'http://localhost:3000' : Uri.base.origin;
    }
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:3000'
        : 'http://localhost:3000';
  }

  final String baseUrl;
  final http.Client _client;
  final FlutterSecureStorage _storage;
  String? _token;

  Future<void> restoreSession() async {
    if (!kIsWeb) _token = await _storage.read(key: 'bm_session');
  }

  Future<void> rememberSession(Json response) async {
    if (kIsWeb) return;
    final token = response['token'];
    if (token is! String || token.isEmpty) {
      throw const ApiException(
        'Backend belum mendukung sesi Flutter. Perbarui server BikinMerch.',
      );
    }
    await _storage.write(key: 'bm_session', value: token);
    _token = token;
  }

  Future<void> clearSession() async {
    _token = null;
    if (!kIsWeb) await _storage.delete(key: 'bm_session');
  }

  String imageUrl(String path) => path.startsWith('/') ? '$baseUrl$path' : path;
  Future<dynamic> get(String path) => request('GET', path);
  Future<dynamic> post(String path, Json body) => request('POST', path, body);
  Future<dynamic> patch(String path, Json body) => request('PATCH', path, body);
  Future<dynamic> delete(String path) => request('DELETE', path);

  Future<dynamic> request(String method, String path, [Json? body]) async {
    try {
      final request = http.Request(method, Uri.parse('$baseUrl$path'));
      request.headers['Accept'] = 'application/json';
      if (!kIsWeb) request.headers['X-Bikinmerch-Client'] = 'flutter-native';
      if (_token != null) request.headers['Authorization'] = 'Bearer $_token';
      if (body != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode(body);
      }
      final response = await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 40)),
      ).timeout(const Duration(seconds: 40));
      dynamic decoded;
      try {
        decoded = jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        throw ApiException(
          'Server mengembalikan respons yang tidak valid.',
          response.statusCode,
        );
      }
      if (response.statusCode >= 400) {
        if (response.statusCode == 401) await clearSession();
        throw ApiException(
          textOf(
            object(decoded)['error'],
            'Permintaan gagal. Silakan coba lagi.',
          ),
          response.statusCode,
        );
      }
      return decoded;
    } on TimeoutException {
      throw const ApiException('Server belum merespons. Silakan coba lagi.');
    } on http.ClientException {
      throw const ApiException(
        'Tidak dapat terhubung ke server BikinMerch. Periksa koneksi dan alamat API.',
      );
    }
  }

  void dispose() => _client.close();
}
