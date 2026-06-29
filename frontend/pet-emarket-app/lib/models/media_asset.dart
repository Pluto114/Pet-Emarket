class MediaAsset {
  const MediaAsset({
    required this.id,
    required this.title,
    required this.mediaType,
    required this.url,
    required this.status,
    this.coverUrl = '',
    this.productId = '',
    this.description = '',
    this.auditRemark = '',
  });

  final String id;
  final String title;
  final String mediaType;
  final String url;
  final String status;
  final String coverUrl;
  final String productId;
  final String description;
  final String auditRemark;

  factory MediaAsset.fromJson(Map<String, dynamic> json) {
    return MediaAsset(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      mediaType: json['mediaType']?.toString() ?? 'IMAGE',
      url: json['url']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      coverUrl: json['coverUrl']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      auditRemark: json['auditRemark']?.toString() ?? '',
    );
  }
}
