import 'product.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.role,
    required this.memberLevel,
    required this.status,
    this.pointsBalance = 0,
    this.totalSpent = 0,
    this.phone = '',
    this.email = '',
  });

  final String id;
  final String username;
  final String displayName;
  final String role;
  final String memberLevel;
  final String status;
  final int pointsBalance;
  final double totalSpent;
  final String phone;
  final String email;

  bool get isAdmin => role == 'ADMIN';

  /// 下一级所需总消费金额，已满级返回 0
  double get nextLevelThreshold {
    return switch (memberLevel) {
      'SVIP' => 0,
      'VIP' => 2000,
      _ => 500,
    };
  }

  /// 距下一级还需消费金额
  double get amountToNextLevel {
    final threshold = nextLevelThreshold;
    if (threshold <= 0) return 0;
    return (threshold - totalSpent).clamp(0, threshold);
  }

  /// 升级进度 0.0 ~ 1.0
  double get levelProgress {
    final threshold = nextLevelThreshold;
    if (threshold <= 0) return 1.0;
    return (totalSpent / threshold).clamp(0.0, 1.0);
  }

  String get memberLevelLabel {
    return switch (memberLevel) {
      'SVIP' => '至尊会员',
      'VIP' => '银卡会员',
      _ => '普通会员',
    };
  }

  String get nextLevelLabel {
    return switch (memberLevel) {
      'NORMAL' => '银卡会员',
      'VIP' => '至尊会员',
      _ => '已满级',
    };
  }

  double get discountRate {
    return switch (memberLevel) {
      'SVIP' => 0.10,
      'VIP' => 0.05,
      _ => 0.0,
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      role: json['role']?.toString() ?? 'CUSTOMER',
      memberLevel: json['memberLevel']?.toString() ?? 'NORMAL',
      status: json['status']?.toString() ?? 'ACTIVE',
      pointsBalance: NumberParser.toInt(json['pointsBalance']),
      totalSpent: NumberParser.toDouble(json['totalSpent']),
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }

  AppUser copyWithRole(String newRole) {
    return AppUser(
      id: id,
      username: username,
      displayName: displayName,
      role: newRole,
      memberLevel: memberLevel,
      status: status,
      pointsBalance: pointsBalance,
      totalSpent: totalSpent,
      phone: phone,
      email: email,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'displayName': displayName,
      'role': role,
      'memberLevel': memberLevel,
      'status': status,
      'pointsBalance': pointsBalance,
      'totalSpent': totalSpent,
      'phone': phone,
      'email': email,
    };
  }
}
