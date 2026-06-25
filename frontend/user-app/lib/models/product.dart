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
      tags: (json['tags'] is List) ? (json['tags'] as List).map((item) => item.toString()).toList() : const [],
      livePet: _livePetFromJson(json),
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
      'livePet': livePet,
    };
  }
}

Map<String, dynamic>? _livePetFromJson(Map<String, dynamic> json) {
  if (json['livePet'] is Map) {
    return Map<String, dynamic>.from(json['livePet'] as Map);
  }
  if (json['type']?.toString() != 'PET_LIVE') {
    return null;
  }
  return {
    'petCode': json['petCode']?.toString() ?? '',
    'breed': json['breed']?.toString() ?? '',
    'healthStatus': json['healthStatus']?.toString() ?? '',
    'vaccineCertNo': json['vaccineCertNo']?.toString() ?? '',
    'quarantineCertNo': json['quarantineCertNo']?.toString() ?? '',
    'traceSource': json['traceSource']?.toString() ?? '',
  };
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
