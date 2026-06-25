// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

import 'api_transport_types.dart';

Future<TransportResponse> sendHttpRequest({
  required String method,
  required Uri uri,
  required Map<String, String> headers,
  String? body,
}) async {
  final response = await html.HttpRequest.request(
    uri.toString(),
    method: method,
    requestHeaders: headers,
    sendData: body,
  );
  return TransportResponse(
    statusCode: response.status ?? 0,
    body: response.responseText ?? '',
  );
}
