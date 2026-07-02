import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/session/session_store.dart';
import 'dashboard/merchant_dashboard_page.dart';
import 'product/merchant_product_page.dart';
import 'order/merchant_order_page.dart';
import 'store/merchant_store_page.dart';

class MerchantShell extends StatefulWidget {
  const MerchantShell({
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
  State<MerchantShell> createState() => _MerchantShellState();
}

class _MerchantShellState extends State<MerchantShell> {
  int selectedIndex = 0;

  static const menuItems = [
    _MenuItem(icon: Icons.dashboard, label: '仪表盘'),
    _MenuItem(icon: Icons.inventory_2, label: '商品管理'),
    _MenuItem(icon: Icons.receipt_long, label: '订单管理'),
    _MenuItem(icon: Icons.store, label: '店铺设置'),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      MerchantDashboardPage(apiClient: widget.apiClient, sessionStore: widget.sessionStore),
      MerchantProductPage(apiClient: widget.apiClient, sessionStore: widget.sessionStore),
      MerchantOrderPage(apiClient: widget.apiClient),
      MerchantStorePage(apiClient: widget.apiClient, sessionStore: widget.sessionStore),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 800;
        return Scaffold(
          appBar: AppBar(
            title: Text(menuItems[selectedIndex].label),
            actions: [
              IconButton(
                tooltip: '切换主题',
                icon: Icon(Theme.of(context).brightness == Brightness.light
                    ? Icons.dark_mode
                    : Icons.light_mode),
                onPressed: widget.onThemeToggle,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Center(
                  child: Chip(
                    avatar: CircleAvatar(
                      radius: 12,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        (widget.sessionStore.user?.displayName ?? 'M').isNotEmpty
                            ? widget.sessionStore.user!.displayName[0].toUpperCase()
                            : 'M',
                        style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onPrimary),
                      ),
                    ),
                    label: Text(widget.sessionStore.user?.displayName ?? '商家',
                        style: const TextStyle(fontSize: 13)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
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
                  onDestinationSelected: (i) => setState(() => selectedIndex = i),
                  labelType: NavigationRailLabelType.all,
                  destinations: menuItems.map((m) => NavigationRailDestination(
                    icon: Icon(m.icon),
                    label: Text(m.label),
                  )).toList(),
                ),
              Expanded(child: pages[selectedIndex]),
            ],
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (i) => setState(() => selectedIndex = i),
                  animationDuration: const Duration(milliseconds: 300),
                  destinations: menuItems
                      .map((m) => NavigationDestination(
                          icon: Icon(m.icon), label: m.label))
                      .toList(),
                ),
          drawer: wide
              ? null
              : Drawer(
                  child: Column(
                    children: [
                      DrawerHeader(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: Text(
                                (widget.sessionStore.user?.displayName ?? 'M').isNotEmpty
                                    ? widget.sessionStore.user!.displayName[0].toUpperCase()
                                    : 'M',
                                style: TextStyle(
                                    fontSize: 20,
                                    color: Theme.of(context).colorScheme.onPrimary),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(widget.sessionStore.user?.displayName ?? '商家',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700)),
                            const Text('MERCHANT',
                                style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          children: [
                            for (var i = 0; i < menuItems.length; i++)
                              ListTile(
                                selected: selectedIndex == i,
                                selectedTileColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withAlpha(80),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                leading: Icon(menuItems[i].icon,
                                    color: selectedIndex == i
                                        ? Theme.of(context).colorScheme.primary
                                        : null),
                                title: Text(menuItems[i].label),
                                onTap: () {
                                  setState(() => selectedIndex = i);
                                  Navigator.pop(context);
                                },
                              ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.brightness_6),
                        title: const Text('切换主题'),
                        onTap: () {
                          Navigator.pop(context);
                          widget.onThemeToggle();
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('退出登录'),
                        onTap: () {
                          Navigator.pop(context);
                          widget.onLogout();
                        },
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  const _MenuItem({required this.icon, required this.label});
}
