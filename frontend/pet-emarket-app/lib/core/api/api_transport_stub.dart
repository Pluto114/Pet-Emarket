import 'api_transport_types.dart';

Future<TransportResponse> sendHttpRequest({
  required String method,
  required Uri uri,
  required Map<String, String> headers,
  String? body,
}) async {
  throw UnsupportedError('Unsupported platform');
}

Future<TransportResponse> sendMultipartRequest({
  required Uri uri,
  required Map<String, String> headers,
  required Map<String, String> fields,
  required List<TransportMultipartFile> files,
}) async {
  throw UnsupportedError('Unsupported platform');
}
