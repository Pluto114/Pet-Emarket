import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'api_transport_types.dart';

Future<TransportResponse> sendHttpRequest({
  required String method,
  required Uri uri,
  required Map<String, String> headers,
  String? body,
}) async {
  final client = HttpClient();
  try {
    client.connectionTimeout = const Duration(seconds: 15);
    final request = await client
        .openUrl(method, uri)
        .timeout(const Duration(seconds: 15));
    headers.forEach(request.headers.set);
    if (body != null) {
      request.add(utf8.encode(body));
    }
    final response = await request.close().timeout(const Duration(seconds: 15));
    final text = await utf8
        .decodeStream(response)
        .timeout(const Duration(seconds: 15));
    return TransportResponse(statusCode: response.statusCode, body: text);
  } on TimeoutException {
    return const TransportResponse(
      statusCode: 504,
      body:
          '{"success":false,"code":"CLIENT_TIMEOUT","message":"请求超时，请检查后端服务或网络"}',
    );
  } finally {
    client.close();
  }
}
