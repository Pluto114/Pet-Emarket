import 'product.dart';

class PetStore {
  const PetStore({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.district,
    required this.longitude,
    required this.latitude,
    required this.rating,
    required this.status,
    this.phone = '',
    this.businessHours = '',
    this.featureTags = '',
    this.distanceKm,
  });

  final String id;
  final String name;
  final String address;
  final String city;
  final String district;
  final double longitude;
  final double latitude;
  final double rating;
  final String status;
  final String phone;
  final String businessHours;
  final String featureTags;
  final double? distanceKm;

  factory PetStore.fromJson(Map<String, dynamic> json) {
    return PetStore(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      longitude: NumberParser.toDouble(json['longitude']),
      latitude: NumberParser.toDouble(json['latitude']),
      rating: NumberParser.toDouble(json['rating']),
      status: json['status']?.toString() ?? 'OPEN',
      phone: json['phone']?.toString() ?? '',
      businessHours: json['businessHours']?.toString() ?? '',
      featureTags: json['featureTags']?.toString() ?? '',
      distanceKm: json['distanceKm'] == null ? null : NumberParser.toDouble(json['distanceKm']),
    );
  }
}
