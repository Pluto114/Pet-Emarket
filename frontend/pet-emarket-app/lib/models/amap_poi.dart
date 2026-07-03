import 'product.dart';

class AmapPoi {
  const AmapPoi({
    required this.poiId,
    required this.name,
    required this.type,
    required this.address,
    required this.city,
    required this.district,
    required this.longitude,
    required this.latitude,
    this.phone = '',
    this.distanceMeters,
  });

  final String poiId;
  final String name;
  final String type;
  final String address;
  final String city;
  final String district;
  final double longitude;
  final double latitude;
  final String phone;
  final double? distanceMeters;

  factory AmapPoi.fromJson(Map<String, dynamic> json) {
    return AmapPoi(
      poiId: json['poiId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      longitude: NumberParser.toDouble(json['longitude']),
      latitude: NumberParser.toDouble(json['latitude']),
      phone: json['phone']?.toString() ?? '',
      distanceMeters:
          json['distanceMeters'] == null
              ? null
              : NumberParser.toDouble(json['distanceMeters']),
    );
  }
}
