import 'package:flutter/material.dart';

import 'core/api/api_client.dart';
import 'core/session/session_store.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_page.dart';
import 'features/home/home_page.dart';

void main() {
  runApp(const AdminApp());
}

class AdminApp extends StatefulWidget {
  const AdminApp({super.key});

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  late final SessionStore sessionStore;
  late final ApiClient apiClient;

  @override
  void initState() {
    super.initState();
    sessionStore = SessionStore();
    apiClient = ApiClient(sessionStore: sessionStore);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: sessionStore,
      builder: (context, _) {
        return MaterialApp(
          title: 'Pet-Emarket 管理后台',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          home: sessionStore.isAuthenticated
              ? HomePage(apiClient: apiClient, sessionStore: sessionStore)
              : AuthPage(apiClient: apiClient, sessionStore: sessionStore),
        );
      },
    );
  }
}

