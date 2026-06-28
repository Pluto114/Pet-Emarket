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
  headers.forEach(request.setRequestHeader);
  request.onLoad.listen((_) {
    completer.complete(TransportResponse(
      statusCode: request.status ?? 500,
      body: request.responseText ?? '',
    ));
  });
  request.onError.listen((_) {
    completer.complete(TransportResponse(
      statusCode: 500,
      body: '',
    ));
  });
  if (body != null) {
    request.setRequestHeader('Content-Type', 'application/json');
    request.send(body);
  } else {
    request.send();
  }
  return completer.future;
}
