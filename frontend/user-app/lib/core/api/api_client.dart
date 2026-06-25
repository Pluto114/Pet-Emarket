import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../models/app_user.dart';
import '../../models/product.dart';
import '../platform/api_transport.dart';
import '../session/session_store.dart';

class ApiClient {
  ApiClient({
    required this.sessionStore,
    String? baseUrl,
  }) : baseUrl = baseUrl ?? defaultApiBaseUrl();

  final SessionStore sessionStore;
  final String baseUrl;

  Future<AppUser> login({
    required String username,
    required String password,
  }) async {
    final data = await _request(
      'POST',
      '/api/v1/auth/login',
      body: {'username': username, 'password': password},
      authenticated: false,
    );
    final user = AppUser.fromJson(Map<String, dynamic>.from(data['user'] as Map));
    sessionStore.setSession(token: data['token'].toString(), user: user);
    return user;
  }

  Future<AppUser> register({
    required String username,
    required String password,
    required String displayName,
    String phone = '',
    String email = '',
  }) async {
    final data = await _request(
      'POST',
      '/api/v1/auth/register',
      body: {
        'username': username,
        'password': password,
        'displayName': displayName,
        'phone': phone,
        'email': email,
      },
      authenticated: false,
    );
    final user = AppUser.fromJson(Map<String, dynamic>.from(data['user'] as Map));
    sessionStore.setSession(token: data['token'].toString(), user: user);
    return user;
  }

  Future<AppUser> me() async {
    final data = await _request('GET', '/api/v1/auth/me');
    final user = AppUser.fromJson(Map<String, dynamic>.from(data['user'] as Map));
    sessionStore.updateUser(user);
    return user;
  }

  Future<List<AppUser>> listUsers() async {
    final data = await _request('GET', '/api/v1/users');
    return (data['items'] as List).map((item) => AppUser.fromJson(Map<String, dynamic>.from(item as Map))).toList();
  }

  Future<AppUser> createUser(Map<String, dynamic> payload) async {
    final data = await _request('POST', '/api/v1/users', body: payload);
    return AppUser.fromJson(Map<String, dynamic>.from(data['user'] as Map));
  }

  Future<AppUser> updateUser(String id, Map<String, dynamic> payload) async {
    final data = await _request('PUT', '/api/v1/users/$id', body: payload);
    return AppUser.fromJson(Map<String, dynamic>.from(data['user'] as Map));
  }

  Future<void> deleteUser(String id) async {
    await _request('DELETE', '/api/v1/users/$id');
  }

  Future<List<Product>> listProducts({String keyword = '', String type = ''}) async {
    final query = <String, String>{};
    if (keyword.trim().isNotEmpty) query['keyword'] = keyword.trim();
    if (type.trim().isNotEmpty) query['type'] = type.trim();
    final data = await _request('GET', '/api/v1/products', query: query, authenticated: false);
    return (data['items'] as List).map((item) => Product.fromJson(Map<String, dynamic>.from(item as Map))).toList();
  }

  Future<Product> createProduct(Map<String, dynamic> payload) async {
    final data = await _request('POST', '/api/v1/products', body: payload);
    return Product.fromJson(Map<String, dynamic>.from(data['product'] as Map));
  }

  Future<Product> updateProduct(String id, Map<String, dynamic> payload) async {
    final data = await _request('PUT', '/api/v1/products/$id', body: payload);
    return Product.fromJson(Map<String, dynamic>.from(data['product'] as Map));
  }

  Future<void> deleteProduct(String id) async {
    await _request('DELETE', '/api/v1/products/$id');
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, String> query = const {},
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query.isEmpty ? null : query);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (authenticated && sessionStore.token != null) 'Authorization': 'Bearer ${sessionStore.token}',
    };
    final response = await sendHttpRequest(
      method: method,
      uri: uri,
      headers: headers,
      body: body == null ? null : jsonEncode(body),
    );
    final decoded = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300 || decoded['success'] == false) {
      throw ApiException(
        statusCode: response.statusCode,
        code: decoded['code']?.toString() ?? 'UNKNOWN',
        message: decoded['message']?.toString() ?? 'Request failed',
      );
    }
    return decoded['data'];
  }
}

String defaultApiBaseUrl() {
  const configured = String.fromEnvironment('API_BASE_URL');
  if (configured.isNotEmpty) return configured;
  if (kIsWeb) return 'http://localhost:8080';
  if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8080';
  return 'http://localhost:8080';
}

class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
  });

  final int statusCode;
  final String code;
  final String message;

  @override
  String toString() => message;
}
