import 'package:flutter/material.dart';

import 'core/api/api_client.dart';
import 'core/session/session_store.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_page.dart';
import 'features/home/home_page.dart';

void main() {
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
          title: 'Pet-Emarket',
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
