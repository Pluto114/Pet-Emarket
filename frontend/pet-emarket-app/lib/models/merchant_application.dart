import 'product.dart';

class MerchantApplication {
  const MerchantApplication({
    required this.id,
    required this.userId,
    required this.storeName,
    required this.city,
    required this.district,
    required this.address,
    required this.longitude,
    required this.latitude,
    required this.status,
    this.contactName = '',
    this.contactPhone = '',
    this.businessLicenseNo = '',
    this.reason = '',
    this.auditRemark = '',
    this.storeId = '',
    this.createdAt = '',
  });

  final String id;
  final String userId;
  final String storeName;
  final String city;
  final String district;
  final String address;
  final double longitude;
  final double latitude;
  final String status;
  final String contactName;
  final String contactPhone;
  final String businessLicenseNo;
  final String reason;
  final String auditRemark;
  final String storeId;
  final String createdAt;

  factory MerchantApplication.fromJson(Map<String, dynamic> json) {
    return MerchantApplication(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      storeName: json['storeName']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      longitude: NumberParser.toDouble(json['longitude']),
      latitude: NumberParser.toDouble(json['latitude']),
      status: json['status']?.toString() ?? 'PENDING',
      contactName: json['contactName']?.toString() ?? '',
      contactPhone: json['contactPhone']?.toString() ?? '',
      businessLicenseNo: json['businessLicenseNo']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      auditRemark: json['auditRemark']?.toString() ?? '',
      storeId: json['storeId']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}
