import 'api_transport_types.dart';

Future<TransportResponse> sendHttpRequest({
  required String method,
  required Uri uri,
  required Map<String, String> headers,
  String? body,
}) {
  throw UnsupportedError('No HTTP transport is available on this platform.');
}
