import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/session/session_store.dart';
import '../user/profile/profile_tab.dart';
import 'dashboard/merchant_dashboard_page.dart';
import 'order/merchant_order_page.dart';
import 'product/merchant_product_page.dart';
import 'video/merchant_video_page.dart';
import 'store/merchant_store_page.dart';

class MerchantShell extends StatefulWidget {
  const MerchantShell({
    required this.apiClient,
    required this.sessionStore,
    required this.onThemeToggle,
    required this.onLogout,
    this.onBackToUser,
    super.key,
  });

  final ApiClient apiClient;
  final SessionStore sessionStore;
  final VoidCallback onThemeToggle;
  final VoidCallback onLogout;
  final VoidCallback? onBackToUser;

  @override
  State<MerchantShell> createState() => _MerchantShellState();
}

class _MerchantShellState extends State<MerchantShell> {
  int selectedIndex = 0;

  static const menuItems = [
    _MenuItem(icon: Icons.space_dashboard_outlined, label: '商家概览'),
    _MenuItem(icon: Icons.inventory_2_outlined, label: '我的商品'),
    _MenuItem(icon: Icons.videocam_outlined, label: '视频管理'),
    _MenuItem(icon: Icons.receipt_long_outlined, label: '店铺订单'),
    _MenuItem(icon: Icons.storefront_outlined, label: '我的店铺'),
    _MenuItem(icon: Icons.person_outline, label: '账号'),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      MerchantDashboardPage(
        apiClient: widget.apiClient,
        sessionStore: widget.sessionStore,
      ),
      MerchantProductPage(
        apiClient: widget.apiClient,
        sessionStore: widget.sessionStore,
      ),
      MerchantVideoPage(apiClient: widget.apiClient),
      MerchantOrderPage(apiClient: widget.apiClient),
      MerchantStorePage(
        apiClient: widget.apiClient,
        sessionStore: widget.sessionStore,
      ),
      ProfileTab(
        apiClient: widget.apiClient,
        sessionStore: widget.sessionStore,
        onThemeToggle: widget.onThemeToggle,
        onLogout: widget.onLogout,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 800;
        final user = widget.sessionStore.user;
        return Scaffold(
          appBar: AppBar(
            title: Text(menuItems[selectedIndex].label),
            actions: [
              if (widget.onBackToUser != null)
                TextButton.icon(
                  onPressed: widget.onBackToUser,
                  icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                  label: const Text('用户首页'),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Center(
                  child: Chip(
                    avatar: const CircleAvatar(
                      child: Icon(Icons.storefront, size: 16),
                    ),
                    label: Text(user?.displayName ?? '商家'),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              IconButton(
                tooltip: '切换主题',
                icon: Icon(
                  Theme.of(context).brightness == Brightness.light
                      ? Icons.dark_mode
                      : Icons.light_mode,
                ),
                onPressed: widget.onThemeToggle,
              ),
              IconButton(
                tooltip: '退出登录',
                icon: const Icon(Icons.logout),
                onPressed: widget.onLogout,
              ),
            ],
          ),
          body: Row(
            children: [
              if (wide)
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected:
                      (i) => setState(() => selectedIndex = i),
                  labelType: NavigationRailLabelType.all,
                  destinations:
                      menuItems
                          .map(
                            (m) => NavigationRailDestination(
                              icon: Icon(m.icon),
                              label: Text(m.label),
                            ),
                          )
                          .toList(),
                ),
              Expanded(
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(widget.sessionStore.textScale.clamp(1.0, 1.5))),
                  child: IndexedStack(index: selectedIndex, children: pages),
                ),
              ),
            ],
          ),
          bottomNavigationBar:
              wide
                  ? null
                  : NavigationBar(
                    selectedIndex: selectedIndex,
                    onDestinationSelected:
                        (i) => setState(() => selectedIndex = i),
                    destinations:
                        menuItems
                            .map(
                              (m) => NavigationDestination(
                                icon: Icon(m.icon),
                                label: m.label,
                              ),
                            )
                            .toList(),
                  ),
        );
      },
    );
  }
}

class _MenuItem {
  const _MenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
