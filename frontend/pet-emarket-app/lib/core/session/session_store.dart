import 'package:flutter/foundation.dart';

import '../../models/app_user.dart';

class SessionStore extends ChangeNotifier {
  String? _token;
  AppUser? _user;

  String? get token => _token;
  AppUser? get user => _user;
  bool get isAuthenticated => _token != null && _user != null;
  bool get isAdmin => _user?.role == 'ADMIN';
  bool get isMerchant => _user?.role == 'MERCHANT';
  double _textScale = 1.0;
  double get textScale => _textScale;
  bool get isManager => isAdmin || isMerchant;

  void setTextScale(double s) { _textScale = s; notifyListeners(); }

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
}
