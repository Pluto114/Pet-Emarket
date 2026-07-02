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
  void devBypass({required bool asAdmin}) {
    _token = 'dev-token-${DateTime.now().millisecondsSinceEpoch}';
    _user = AppUser(
      id: asAdmin ? 'dev-admin-001' : 'dev-user-001',
      username: asAdmin ? 'admin' : 'customer',
      displayName: asAdmin ? 'Dev Admin' : 'Dev Customer',
      role: asAdmin ? 'ADMIN' : 'CUSTOMER',
      memberLevel: asAdmin ? 'VIP' : 'NORMAL',
      status: 'ACTIVE',
      phone: '18800000000',
      email: asAdmin ? 'admin@petemarket.dev' : 'user@petemarket.dev',
    );
    notifyListeners();
  }
}
