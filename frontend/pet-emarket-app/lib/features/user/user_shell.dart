import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/session/session_store.dart';
import 'cart/cart_page.dart';
import 'home/home_page.dart';
import 'order/order_page.dart';
import 'profile/profile_tab.dart';
import 'store/nearby_store_page.dart';

/// 用户端底部导航壳 — 纯粹的路由容器，不包含任何业务 UI。
class UserShell extends StatefulWidget {
  const UserShell({
    required this.apiClient,
    required this.sessionStore,
    required this.onThemeToggle,
    required this.onLogout,
    super.key,
  });

  final ApiClient apiClient;
  final SessionStore sessionStore;
  final VoidCallback onThemeToggle;
  final VoidCallback onLogout;

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  int selectedIndex = 0;

  static const _tabs = [
    NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.store_outlined), selectedIcon: Icon(Icons.store), label: 'Nearby'),
    NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), selectedIcon: Icon(Icons.shopping_cart), label: 'Cart'),
    NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
    NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(
        apiClient: widget.apiClient,
        sessionStore: widget.sessionStore,
        onNavigate: (i) => setState(() => selectedIndex = i),
      ),
      NearbyStorePage(apiClient: widget.apiClient),
      CartPage(apiClient: widget.apiClient),
      OrderPage(apiClient: widget.apiClient, sessionStore: widget.sessionStore),
      ProfileTab(
        apiClient: widget.apiClient,
        sessionStore: widget.sessionStore,
        onThemeToggle: widget.onThemeToggle,
        onLogout: widget.onLogout,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet-Emarket'),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            icon: Icon(Theme.of(context).brightness == Brightness.light ? Icons.dark_mode : Icons.light_mode),
            onPressed: widget.onThemeToggle,
          ),
        ],
      ),
      body: IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        destinations: _tabs,
        onDestinationSelected: (i) => setState(() => selectedIndex = i),
      ),
    );
  }
}
