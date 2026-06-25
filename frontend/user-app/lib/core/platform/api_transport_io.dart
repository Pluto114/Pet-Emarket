import 'dart:convert';
import 'dart:io';

import 'api_transport_types.dart';

Future<TransportResponse> sendHttpRequest({
  required String method,
  required Uri uri,
  required Map<String, String> headers,
  String? body,
}) async {
  final client = HttpClient();
  try {
    final request = await client.openUrl(method, uri);
    headers.forEach(request.headers.set);
    if (body != null) {
      request.add(utf8.encode(body));
    }
    final response = await request.close();
    final text = await utf8.decodeStream(response);
    return TransportResponse(statusCode: response.statusCode, body: text);
  } finally {
    client.close();
  }
}
