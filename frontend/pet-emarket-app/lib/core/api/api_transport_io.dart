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

Future<TransportResponse> sendMultipartRequest({
  required Uri uri,
  required Map<String, String> headers,
  required Map<String, String> fields,
  required List<TransportMultipartFile> files,
}) async {
  final client = HttpClient();
  final boundary = '----petemarket${DateTime.now().microsecondsSinceEpoch}';
  try {
    client.connectionTimeout = const Duration(seconds: 30);
    final request = await client
        .postUrl(uri)
        .timeout(const Duration(seconds: 30));
    headers.forEach(request.headers.set);
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'multipart/form-data; boundary=$boundary',
    );

    void write(String value) {
      request.add(utf8.encode(value));
    }

    for (final entry in fields.entries) {
      write('--$boundary\r\n');
      write(
        'Content-Disposition: form-data; name="${_escapeHeader(entry.key)}"\r\n\r\n',
      );
      write('${entry.value}\r\n');
    }
    for (final file in files) {
      write('--$boundary\r\n');
      write(
        'Content-Disposition: form-data; name="${_escapeHeader(file.fieldName)}"; filename="${_escapeHeader(file.filename)}"\r\n',
      );
      write('Content-Type: ${file.contentType}\r\n\r\n');
      request.add(file.bytes);
      write('\r\n');
    }
    write('--$boundary--\r\n');

    final response = await request.close().timeout(const Duration(seconds: 30));
    final text = await utf8
        .decodeStream(response)
        .timeout(const Duration(seconds: 30));
    return TransportResponse(statusCode: response.statusCode, body: text);
  } on TimeoutException {
    return const TransportResponse(
      statusCode: 504,
      body:
          '{"success":false,"code":"CLIENT_TIMEOUT","message":"上传超时，请检查文件大小或网络"}',
    );
  } finally {
    client.close();
  }
}

String _escapeHeader(String value) {
  return value.replaceAll('\\', '\\\\').replaceAll('"', r'\"');
}
