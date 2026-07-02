// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'api_transport_types.dart';

Future<TransportResponse> sendHttpRequest({
  required String method,
  required Uri uri,
  required Map<String, String> headers,
  String? body,
}) async {
  final completer = Completer<TransportResponse>();
  final request = html.HttpRequest();
  request.open(method, uri.toString());
  request.timeout = 15000;
  headers.forEach(request.setRequestHeader);
  request.onLoad.listen((_) {
    if (completer.isCompleted) return;
    completer.complete(
      TransportResponse(
        statusCode: request.status ?? 500,
        body: request.responseText ?? '',
      ),
    );
  });
  request.onError.listen((_) {
    if (completer.isCompleted) return;
    completer.complete(TransportResponse(statusCode: 500, body: ''));
  });
  request.onTimeout.listen((_) {
    if (completer.isCompleted) return;
    completer.complete(
      TransportResponse(
        statusCode: 504,
        body:
            '{"success":false,"code":"CLIENT_TIMEOUT","message":"请求超时，请检查后端服务或网络"}',
      ),
    );
  });
  if (body != null) {
    request.send(body);
  } else {
    request.send();
  }
  return completer.future;
}
