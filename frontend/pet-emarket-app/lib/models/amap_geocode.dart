class AmapGeocode {
  final double longitude, latitude;
  final String formattedAddress, province, city, district;
  const AmapGeocode({required this.longitude, required this.latitude,
    this.formattedAddress = '', this.province = '', this.city = '', this.district = ''});

  factory AmapGeocode.fromJson(Map<String, dynamic> json) => AmapGeocode(
    longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
    formattedAddress: json['formattedAddress'] as String? ?? '',
    province: json['province'] as String? ?? '',
    city: json['city'] as String? ?? '',
    district: json['district'] as String? ?? '',
  );
}
