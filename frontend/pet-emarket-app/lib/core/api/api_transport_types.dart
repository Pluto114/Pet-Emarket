class TransportResponse {
  const TransportResponse({required this.statusCode, required this.body});
  final int statusCode;
  final String body;
}

class TransportMultipartFile {
  const TransportMultipartFile({
    required this.fieldName,
    required this.filename,
    required this.bytes,
    required this.contentType,
  });

  final String fieldName;
  final String filename;
  final List<int> bytes;
  final String contentType;
}
