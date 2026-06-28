class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.role,
    required this.memberLevel,
    required this.status,
    this.phone = '',
    this.email = '',
  });

  final String id;
  final String username;
  final String displayName;
  final String role;
  final String memberLevel;
  final String status;
  final String phone;
  final String email;

  bool get isAdmin => role == 'ADMIN';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      role: json['role']?.toString() ?? 'CUSTOMER',
      memberLevel: json['memberLevel']?.toString() ?? 'NORMAL',
      status: json['status']?.toString() ?? 'ACTIVE',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
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
      'phone': phone,
      'email': email,
    };
  }
}
