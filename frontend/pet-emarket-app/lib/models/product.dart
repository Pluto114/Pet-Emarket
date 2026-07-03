class Product {
  const Product({
    required this.id,
    required this.name,
    required this.type,
    required this.category,
    required this.price,
    required this.stock,
    required this.status,
    this.storeId = '',
    this.description = '',
    this.coverUrl = '',
    this.tags = const [],
    this.auditStatus = '',
    this.auditRemark = '',
    this.livePet,
  });

  final String id;
  final String name;
  final String type;
  final String category;
  final double price;
  final int stock;
  final String status;
  final String storeId;
  final String description;
  final String coverUrl;
  final List<String> tags;
  final String auditStatus;
  final String auditRemark;
  final Map<String, dynamic>? livePet;

  bool get isLivePet => type == 'PET_LIVE';

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'GOODS',
      category: json['category']?.toString() ?? 'General',
      price: NumberParser.toDouble(json['price']),
      stock: NumberParser.toInt(json['stock']),
      status: json['status']?.toString() ?? 'DRAFT',
      storeId: json['storeId']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      coverUrl: json['coverUrl']?.toString() ?? '',
      tags:
          (json['tags'] is List)
              ? (json['tags'] as List).map((item) => item.toString()).toList()
              : const [],
      auditStatus:
          json['auditStatus']?.toString() ??
          json['livePet']?['auditStatus']?.toString() ??
          '',
      auditRemark: json['auditRemark']?.toString() ?? '',
      livePet:
          json['livePet'] is Map
              ? Map<String, dynamic>.from(json['livePet'] as Map)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'category': category,
      'price': price,
      'stock': stock,
      'status': status,
      'storeId': storeId,
      'description': description,
      'coverUrl': coverUrl,
      'tags': tags,
      'auditStatus': auditStatus,
      'auditRemark': auditRemark,
      'livePet': livePet,
    };
  }
}

class ProductReview {
  const ProductReview({
    required this.orderId,
    required this.orderNo,
    required this.userId,
    required this.rating,
    required this.content,
    required this.reviewedAt,
  });

  final String orderId;
  final String orderNo;
  final String userId;
  final int rating;
  final String content;
  final String reviewedAt;

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    return ProductReview(
      orderId: json['orderId']?.toString() ?? '',
      orderNo: json['orderNo']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      rating: NumberParser.toInt(json['rating']),
      content: json['content']?.toString() ?? '',
      reviewedAt: json['reviewedAt']?.toString() ?? '',
    );
  }
}

class NumberParser {
  static double toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int toInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
