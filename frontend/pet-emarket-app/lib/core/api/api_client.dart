import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../models/app_user.dart';
import '../../models/admin_dashboard.dart';
import '../../models/ai_chat.dart';
import '../../models/cart_item.dart';
import '../../models/media_asset.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../models/recommendation.dart';
import '../../models/store.dart';
import 'api_transport.dart';
import '../session/session_store.dart';

class ApiClient {
  ApiClient({required this.sessionStore, String? baseUrl})
    : baseUrl = baseUrl ?? defaultApiBaseUrl();

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
    final user = AppUser.fromJson(
      Map<String, dynamic>.from(data['user'] as Map),
    );
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
    final user = AppUser.fromJson(
      Map<String, dynamic>.from(data['user'] as Map),
    );
    sessionStore.setSession(token: data['token'].toString(), user: user);
    return user;
  }

  Future<AppUser> me() async {
    final data = await _request('GET', '/api/v1/auth/me');
    final user = AppUser.fromJson(_object(data, 'user'));
    sessionStore.updateUser(user);
    return user;
  }

  Future<List<AppUser>> listUsers() async {
    final data = await _request('GET', '/api/v1/users');
    return (data['items'] as List)
        .map((item) => AppUser.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<AppUser> createUser(Map<String, dynamic> payload) async {
    final data = await _request('POST', '/api/v1/users', body: payload);
    return AppUser.fromJson(_object(data, 'user'));
  }

  Future<AppUser> updateUser(String id, Map<String, dynamic> payload) async {
    final data = await _request('PUT', '/api/v1/users/$id', body: payload);
    return AppUser.fromJson(_object(data, 'user'));
  }

  Future<void> deleteUser(String id) async {
    await _request('DELETE', '/api/v1/users/$id');
  }

  Future<List<Product>> listProducts({
    String keyword = '',
    String type = '',
  }) async {
    final query = <String, String>{};
    if (keyword.trim().isNotEmpty) query['keyword'] = keyword.trim();
    if (type.trim().isNotEmpty) query['type'] = type.trim();
    final data = await _request(
      'GET',
      '/api/v1/products',
      query: query,
      authenticated: false,
    );
    return (data['items'] as List)
        .map((item) => Product.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<Product> createProduct(Map<String, dynamic> payload) async {
    final data = await _request('POST', '/api/v1/products', body: payload);
    return Product.fromJson(_object(data, 'product'));
  }

  Future<Product> updateProduct(String id, Map<String, dynamic> payload) async {
    final data = await _request('PUT', '/api/v1/products/$id', body: payload);
    return Product.fromJson(_object(data, 'product'));
  }

  Future<void> deleteProduct(String id) async {
    await _request('DELETE', '/api/v1/products/$id');
  }

  Future<AdminDashboard> adminDashboard() async {
    final data = await _request('GET', '/api/v1/admin/dashboard');
    return AdminDashboard.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<Product>> listLivePetAudits({String auditStatus = ''}) async {
    final query = <String, String>{};
    if (auditStatus.trim().isNotEmpty) {
      query['auditStatus'] = auditStatus.trim();
    }
    final data = await _request(
      'GET',
      '/api/v1/products/live-pet-audits',
      query: query,
    );
    return (data['items'] as List)
        .map((item) => Product.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<Product> auditProduct(
    String id, {
    required bool approved,
    String remark = '',
  }) async {
    final data = await _request(
      'PUT',
      '/api/v1/products/$id/audit',
      body: {'approved': approved, 'remark': remark},
    );
    return Product.fromJson(_object(data, 'product'));
  }

  Future<List<PetStore>> listStores({bool authenticated = false}) async {
    final data = await _request(
      'GET',
      '/api/v1/stores',
      authenticated: authenticated,
    );
    return (data['items'] as List)
        .map(
          (item) => PetStore.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<List<PetStore>> nearbyStores({
    double longitude = 120.1551,
    double latitude = 30.2741,
    double radiusKm = 30,
    String keyword = '',
  }) async {
    final query = <String, String>{
      'longitude': longitude.toString(),
      'latitude': latitude.toString(),
      'radiusKm': radiusKm.toString(),
    };
    if (keyword.trim().isNotEmpty) query['keyword'] = keyword.trim();
    final data = await _request(
      'GET',
      '/api/v1/stores/nearby',
      query: query,
      authenticated: false,
    );
    return (data['items'] as List)
        .map(
          (item) => PetStore.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<PetStore> createStore(Map<String, dynamic> payload) async {
    final data = await _request('POST', '/api/v1/stores', body: payload);
    return PetStore.fromJson(_object(data, 'store'));
  }

  Future<PetStore> updateStore(String id, Map<String, dynamic> payload) async {
    final data = await _request('PUT', '/api/v1/stores/$id', body: payload);
    return PetStore.fromJson(_object(data, 'store'));
  }

  Future<void> deleteStore(String id) async {
    await _request('DELETE', '/api/v1/stores/$id');
  }

  Future<List<MediaAsset>> listMedia({
    bool authenticated = false,
    String status = '',
    String keyword = '',
  }) async {
    final query = <String, String>{};
    if (status.trim().isNotEmpty) query['status'] = status.trim();
    if (keyword.trim().isNotEmpty) query['keyword'] = keyword.trim();
    final data = await _request(
      'GET',
      '/api/v1/media',
      query: query,
      authenticated: authenticated,
    );
    return (data['items'] as List)
        .map(
          (item) => MediaAsset.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<MediaAsset> createMedia(Map<String, dynamic> payload) async {
    final data = await _request('POST', '/api/v1/media', body: payload);
    return MediaAsset.fromJson(_object(data, 'media'));
  }

  Future<MediaAsset> updateMedia(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final data = await _request('PUT', '/api/v1/media/$id', body: payload);
    return MediaAsset.fromJson(_object(data, 'media'));
  }

  Future<MediaAsset> auditMedia(
    String id, {
    required bool approved,
    String remark = '',
  }) async {
    final data = await _request(
      'PUT',
      '/api/v1/media/$id/audit',
      body: {'approved': approved, 'remark': remark},
    );
    return MediaAsset.fromJson(_object(data, 'media'));
  }

  Future<void> deleteMedia(String id) async {
    await _request('DELETE', '/api/v1/media/$id');
  }

  Future<List<RecommendationItem>> recommendations({
    String scene = 'HOME',
    String lastProductId = '',
    int limit = 8,
  }) async {
    final query = <String, String>{'scene': scene, 'limit': limit.toString()};
    if (lastProductId.trim().isNotEmpty) {
      query['lastProductId'] = lastProductId.trim();
    }
    final data = await _request(
      'GET',
      '/api/v1/recommend',
      query: query,
      authenticated: sessionStore.token != null,
    );
    return (data['items'] as List)
        .map(
          (item) => RecommendationItem.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<AiChatAnswer> chat(String question, {String scene = 'general'}) async {
    final data = await _request(
      'POST',
      '/api/v1/ai/chat',
      body: {'question': question, 'scene': scene},
      authenticated: false,
    );
    return AiChatAnswer.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> trackBehavior({
    required String productId,
    required String behaviorType,
    String scene = 'APP',
    int quantity = 1,
  }) async {
    if (sessionStore.token == null) return;
    await _request(
      'POST',
      '/api/v1/behaviors',
      body: {
        'productId': productId,
        'behaviorType': behaviorType,
        'scene': scene,
        'quantity': quantity,
      },
    );
  }

  Future<List<CartItem>> listCartItems() async {
    final data = await _request('GET', '/api/v1/cart/items');
    return (data['items'] as List)
        .map(
          (item) => CartItem.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<CartItem> addCartItem({
    required String productId,
    int quantity = 1,
  }) async {
    final data = await _request(
      'POST',
      '/api/v1/cart/items',
      body: {'productId': productId, 'quantity': quantity},
    );
    return CartItem.fromJson(_object(data, 'item'));
  }

  Future<CartItem> updateCartItem(String id, int quantity) async {
    final data = await _request(
      'PUT',
      '/api/v1/cart/items/$id',
      body: {'quantity': quantity},
    );
    return CartItem.fromJson(_object(data, 'item'));
  }

  Future<void> deleteCartItem(String id) async {
    await _request('DELETE', '/api/v1/cart/items/$id');
  }

  Future<PetOrder> createOrderFromCart() async {
    final data = await _request(
      'POST',
      '/api/v1/orders',
      body: {
        'addressSnapshot': {
          'receiver': sessionStore.user?.displayName ?? 'Demo User',
          'phone': sessionStore.user?.phone ?? '18800000000',
          'detail': 'Pet-Emarket demo address',
        },
      },
    );
    return PetOrder.fromJson(_object(data, 'order'));
  }

  Future<List<PetOrder>> listOrders() async {
    final data = await _request('GET', '/api/v1/orders');
    return (data['items'] as List)
        .map(
          (item) => PetOrder.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<PetOrder> operateOrder(
    String id,
    String action, {
    Map<String, dynamic> body = const {},
  }) async {
    final data = await _request(
      'PUT',
      '/api/v1/orders/$id/$action',
      body: body,
    );
    return PetOrder.fromJson(_object(data, 'order'));
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, String> query = const {},
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final uri = Uri.parse(
      '$baseUrl$path',
    ).replace(queryParameters: query.isEmpty ? null : query);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (authenticated && sessionStore.token != null)
        'Authorization': 'Bearer ${sessionStore.token}',
    };
    final response = await sendHttpRequest(
      method: method,
      uri: uri,
      headers: headers,
      body: body == null ? null : jsonEncode(body),
    );
    final decoded =
        response.body.isEmpty
            ? <String, dynamic>{}
            : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        decoded['success'] == false) {
      throw ApiException(
        statusCode: response.statusCode,
        code: decoded['code']?.toString() ?? 'UNKNOWN',
        message: decoded['message']?.toString() ?? 'Request failed',
      );
    }
    return decoded['data'];
  }

  Map<String, dynamic> _object(dynamic data, String legacyKey) {
    if (data is Map && data[legacyKey] is Map) {
      return Map<String, dynamic>.from(data[legacyKey] as Map);
    }
    return Map<String, dynamic>.from(data as Map);
  }
}

String defaultApiBaseUrl() {
  const configured = String.fromEnvironment('API_BASE_URL');
  if (configured.isNotEmpty) return configured;
  if (kIsWeb) return 'http://localhost:8080';
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8080';
  }
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
