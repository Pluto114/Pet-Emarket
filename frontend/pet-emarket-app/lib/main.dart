import 'package:flutter/material.dart';
// Using system fonts
import 'core/api/api_client.dart';
import 'core/session/session_store.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_page.dart';
import 'features/admin/admin_shell.dart';
import 'features/merchant/merchant_shell.dart';
import 'features/user/user_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Preload Google Fonts to prevent runtime errors
  // Using system fonts, no preloading needed
  runApp(const PetEmarketApp());
}

class PetEmarketApp extends StatefulWidget {
  const PetEmarketApp({super.key});

  @override
  State<PetEmarketApp> createState() => _PetEmarketAppState();
}

class _PetEmarketAppState extends State<PetEmarketApp> {
  late final SessionStore sessionStore;
  late final ApiClient apiClient;
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    sessionStore = SessionStore();
    apiClient = ApiClient(sessionStore: sessionStore);
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _logout() {
    sessionStore.clear();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: sessionStore,
      builder: (context, _) {
        return MaterialApp(
          title: 'Pet-Emarket',
          debugShowCheckedModeBanner: false,
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: _themeMode,
          home: _buildHome(),
        );
      },
    );
  }

  Widget _buildHome() {
    if (!sessionStore.isAuthenticated) {
      return AuthPage(apiClient: apiClient, sessionStore: sessionStore);
    }
    if (sessionStore.isAdmin) {
      return AdminShell(
        apiClient: apiClient,
        sessionStore: sessionStore,
        onThemeToggle: _toggleTheme,
        onLogout: _logout,
      );
    }
    if (sessionStore.isMerchant) {
      return MerchantShell(
        apiClient: apiClient,
        sessionStore: sessionStore,
        onThemeToggle: _toggleTheme,
        onLogout: _logout,
      );
    }
    return UserShell(
      apiClient: apiClient,
      sessionStore: sessionStore,
      onThemeToggle: _toggleTheme,
      onLogout: _logout,
    );
  }
}