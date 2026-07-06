import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../models/app_user.dart';
import '../../models/admin_dashboard.dart';
import '../../models/amap_poi.dart';
import '../../models/amap_geocode.dart';
import '../../models/ai_chat.dart';
import '../../models/cart_item.dart';
import '../../models/media_asset.dart';
import '../../models/merchant_application.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../models/recommendation.dart';
import '../../models/shipping_address.dart';
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
    required String emailCode,
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
        'emailCode': emailCode,
      },
      authenticated: false,
    );
    final user = AppUser.fromJson(
      Map<String, dynamic>.from(data['user'] as Map),
    );
    sessionStore.setSession(token: data['token'].toString(), user: user);
    return user;
  }

  Future<String> sendRegisterEmailCode(String email) async {
    final data = await _request(
      'POST',
      '/api/v1/auth/email-code',
      body: {'email': email},
      authenticated: false,
    );
    return data['devCode']?.toString() ?? '';
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
    String status = '',
  }) async {
    final query = <String, String>{};
    if (keyword.trim().isNotEmpty) query['keyword'] = keyword.trim();
    if (type.trim().isNotEmpty) query['type'] = type.trim();
    if (status.trim().isNotEmpty) query['status'] = status.trim();
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

  Future<Product> getProduct(String id) async {
    final data = await _request(
      'GET',
      '/api/v1/products/$id',
      authenticated: false,
    );
    return Product.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<ProductReview>> listProductReviews(String id) async {
    final data = await _request(
      'GET',
      '/api/v1/products/$id/reviews',
      authenticated: false,
    );
    return (data['items'] as List)
        .map(
          (item) =>
              ProductReview.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<List<Product>> listManagedProducts({
    String keyword = '',
    String type = '',
    String status = '',
  }) async {
    final query = <String, String>{};
    if (keyword.trim().isNotEmpty) query['keyword'] = keyword.trim();
    if (type.trim().isNotEmpty) query['type'] = type.trim();
    if (status.trim().isNotEmpty) query['status'] = status.trim();
    final data = await _request(
      'GET',
      '/api/v1/products/managed',
      query: query,
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

  Future<List<Product>> listStoreProducts(String storeId) async {
    final data = await _request(
      'GET',
      '/api/v1/stores/$storeId/products',
    );
    return (data['items'] as List)
        .map((item) => Product.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
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

  Future<List<AmapPoi>> nearbyAmapPetStores({
    double longitude = 120.1551,
    double latitude = 30.2741,
    int radius = 5000,
    int limit = 20,
    String keywords = '',
  }) async {
    final query = <String, String>{
      'longitude': longitude.toString(),
      'latitude': latitude.toString(),
      'radius': radius.toString(),
      'limit': limit.toString(),
    };
    if (keywords.trim().isNotEmpty) query['keywords'] = keywords.trim();
    final data = await _request(
      'GET',
      '/api/v1/geo/amap/nearby-pet-stores',
      query: query,
      authenticated: false,
    );
    return (data['items'] as List)
        .map((item) => AmapPoi.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<AmapGeocode> reverseGeocode(double longitude, double latitude) async {
    final data = await _request('GET', '/api/v1/geo/amap/regeo', query: {
      'longitude': longitude.toString(),
      'latitude': latitude.toString(),
    }, authenticated: false);
    return AmapGeocode.fromJson(Map<String, dynamic>.from(data));
  }

  /// 正地理编码：地址 -> 经纬度，统一走后端，避免前端暴露或缺失高德 key。
  Future<AmapGeocode> geocode(String address, {String city = ''}) async {
    final query = <String, String>{'address': address.trim()};
    if (city.trim().isNotEmpty) query['city'] = city.trim();
    final data = await _request(
      'GET',
      '/api/v1/geo/amap/geocode',
      query: query,
      authenticated: false,
    );
    return AmapGeocode.fromJson(Map<String, dynamic>.from(data as Map));
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

  Future<List<MerchantApplication>> myMerchantApplications() async {
    final data = await _request('GET', '/api/v1/merchant/applications/me');
    return (data['items'] as List)
        .map(
          (item) => MerchantApplication.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<List<MerchantApplication>> listMerchantApplications({
    String status = '',
  }) async {
    final query = <String, String>{};
    if (status.trim().isNotEmpty) query['status'] = status.trim();
    final data = await _request(
      'GET',
      '/api/v1/merchant/applications',
      query: query,
    );
    return (data['items'] as List)
        .map(
          (item) => MerchantApplication.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<MerchantApplication> submitMerchantApplication(
    Map<String, dynamic> payload,
  ) async {
    final data = await _request(
      'POST',
      '/api/v1/merchant/applications',
      body: payload,
    );
    return MerchantApplication.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<MerchantApplication> auditMerchantApplication(
    String id, {
    required bool approved,
    String remark = '',
  }) async {
    final data = await _request(
      'PUT',
      '/api/v1/merchant/applications/$id/audit',
      body: {'approved': approved, 'remark': remark},
    );
    return MerchantApplication.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<ShippingAddress>> listAddresses() async {
    final data = await _request('GET', '/api/v1/addresses');
    return (data['items'] as List)
        .map(
          (item) =>
              ShippingAddress.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<ShippingAddress> createAddress(Map<String, dynamic> payload) async {
    final data = await _request('POST', '/api/v1/addresses', body: payload);
    return ShippingAddress.fromJson(_object(data, 'address'));
  }

  Future<ShippingAddress> updateAddress(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final data = await _request('PUT', '/api/v1/addresses/$id', body: payload);
    return ShippingAddress.fromJson(_object(data, 'address'));
  }

  Future<ShippingAddress> setDefaultAddress(String id) async {
    final data = await _request('PUT', '/api/v1/addresses/$id/default');
    return ShippingAddress.fromJson(_object(data, 'address'));
  }

  Future<void> deleteAddress(String id) async {
    await _request('DELETE', '/api/v1/addresses/$id');
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

  Future<MediaAsset> uploadMedia({
    required String title,
    required String mediaType,
    required String fileName,
    required List<int> fileBytes,
    String productId = '',
    String description = '',
    String fileContentType = '',
    String coverFileName = '',
    List<int>? coverFileBytes,
    String coverContentType = '',
  }) async {
    final fields = <String, String>{
      'title': title,
      'mediaType': mediaType,
      if (productId.trim().isNotEmpty) 'productId': productId.trim(),
      if (description.trim().isNotEmpty) 'description': description.trim(),
    };
    final files = <TransportMultipartFile>[
      TransportMultipartFile(
        fieldName: 'file',
        filename: fileName,
        bytes: fileBytes,
        contentType:
            fileContentType.isNotEmpty
                ? fileContentType
                : _contentTypeFor(fileName),
      ),
    ];
    if (coverFileBytes != null && coverFileName.trim().isNotEmpty) {
      files.add(
        TransportMultipartFile(
          fieldName: 'coverFile',
          filename: coverFileName,
          bytes: coverFileBytes,
          contentType:
              coverContentType.isNotEmpty
                  ? coverContentType
                  : _contentTypeFor(coverFileName),
        ),
      );
    }
    final data = await _multipartRequest(
      '/api/v1/media/upload',
      fields: fields,
      files: files,
    );
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

  /// Get approved media assets (images/videos) for a product
  Future<List<MediaAsset>> listProductMedia(String productId) async {
    final data = await _request('GET', '/api/v1/media/product/$productId');
    if (data is List) {
      return (data as List)
          .map((item) => MediaAsset.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    return [];
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

  Future<PetOrder> createOrderFromCart({String addressId = '', List<String>? cartItemIds}) async {
    final body = <String, dynamic>{};
    if (addressId.trim().isNotEmpty) {
      body['addressId'] = int.tryParse(addressId.trim()) ?? addressId.trim();
    }
    if (cartItemIds != null && cartItemIds.isNotEmpty) {
      body['cartItemIds'] = cartItemIds.map((id) => int.tryParse(id) ?? id).toList();
    }
    final data = await _request('POST', '/api/v1/orders', body: body);
    return PetOrder.fromJson(_object(data, 'order'));
  }

  Future<PetOrder> createOrderFromCartAndPay({
    required String addressId,
  }) async {
    final created = await createOrderFromCart(addressId: addressId);
    return operateOrder(created.id, 'pay');
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

  Future<dynamic> _multipartRequest(
    String path, {
    required Map<String, String> fields,
    required List<TransportMultipartFile> files,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{
      if (sessionStore.token != null)
        'Authorization': 'Bearer ${sessionStore.token}',
    };
    final response = await sendMultipartRequest(
      uri: uri,
      headers: headers,
      fields: fields,
      files: files,
    );
    return _parseResponse(response);
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
    return _parseResponse(response);
  }

  dynamic _parseResponse(TransportResponse response) {
    final responseBody = response.body.trim();
    Map<String, dynamic> decoded = <String, dynamic>{};
    if (responseBody.isNotEmpty) {
      try {
        decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      } catch (_) {
        decoded = {
          'success': false,
          'code': 'INVALID_RESPONSE',
          'message': '后端返回了无法解析的响应',
        };
      }
    }
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

  String _contentTypeFor(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'mp4' || 'm4v' => 'video/mp4',
      'mov' => 'video/quicktime',
      'avi' => 'video/x-msvideo',
      'webm' => 'video/webm',
      _ => 'application/octet-stream',
    };
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
