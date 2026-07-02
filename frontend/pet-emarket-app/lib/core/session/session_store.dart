import 'package:flutter/foundation.dart';

import '../../models/app_user.dart';

class SessionStore extends ChangeNotifier {
  String? _token;
  AppUser? _user;

  String? get token => _token;
  AppUser? get user => _user;
  bool get isAuthenticated => _token != null && _user != null;
  bool get isAdmin => _user != null && _user!.role == 'ADMIN';
  bool get isMerchant => _user != null && _user!.role == 'MERCHANT';

  void setSession({required String token, required AppUser user}) {
    _token = token;
    _user = user;
    notifyListeners();
  }

  void updateUser(AppUser user) {
    _user = user;
    notifyListeners();
  }

  void clear() {
    _token = null;
    _user = null;
    notifyListeners();
  }

  /// Dev-only: skip login without backend.
  void devBypass({String role = 'CUSTOMER'}) {
    _token = 'dev-token-${DateTime.now().millisecondsSinceEpoch}';
    late final String id, username, displayName, memberLevel, email;
    switch (role) {
      case 'ADMIN':
        id = 'dev-admin-001';
        username = 'admin';
        displayName = 'Dev Admin';
        memberLevel = 'VIP';
        email = 'admin@petemarket.dev';
        break;
      case 'MERCHANT':
        id = 'dev-merchant-001';
        username = 'merchant';
        displayName = 'Dev Merchant';
        memberLevel = 'NORMAL';
        email = 'merchant@petemarket.dev';
        break;
      default: // CUSTOMER
        id = 'dev-user-001';
        username = 'customer';
        displayName = 'Dev Customer';
        memberLevel = 'NORMAL';
        email = 'user@petemarket.dev';
    }
    _user = AppUser(
      id: id,
      username: username,
      displayName: displayName,
      role: role,
      memberLevel: memberLevel,
      status: 'ACTIVE',
      phone: '18800000000',
      email: email,
    );
    notifyListeners();
  }
}
