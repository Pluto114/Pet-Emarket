class ShippingAddress {
  const ShippingAddress({
    required this.id,
    required this.receiver,
    required this.phone,
    required this.province,
    required this.city,
    required this.district,
    required this.detail,
    required this.defaultAddress,
  });

  final String id;
  final String receiver;
  final String phone;
  final String province;
  final String city;
  final String district;
  final String detail;
  final bool defaultAddress;

  String get fullAddress {
    return [
      province,
      city,
      district,
      detail,
    ].where((part) => part.trim().isNotEmpty).join(' ');
  }

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      id: json['id']?.toString() ?? '',
      receiver: json['receiver']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      province: json['province']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      detail: json['detail']?.toString() ?? '',
      defaultAddress: json['defaultAddress'] == true,
    );
  }
}
