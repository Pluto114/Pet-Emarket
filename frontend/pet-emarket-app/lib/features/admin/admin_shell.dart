import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/session/session_store.dart';
import 'product/product_manage_page.dart';
import 'pet_audit/pet_audit_page.dart';
import 'order/order_manage_page.dart';
import 'refund/refund_audit_page.dart';
import 'member/member_manage_page.dart';
import 'store/store_manage_page.dart';
import 'media/media_manage_page.dart';
import 'dashboard/dashboard_page.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({
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
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int selectedIndex = 0;

  static const menuItems = [
    _MenuItem(icon: Icons.dashboard, label: '仪表盘'),
    _MenuItem(icon: Icons.inventory_2, label: '商品管理'),
    _MenuItem(icon: Icons.pets, label: '宠物审核'),
    _MenuItem(icon: Icons.receipt_long, label: '订单管理'),
    _MenuItem(icon: Icons.money_off, label: '退款审核'),
    _MenuItem(icon: Icons.group, label: '会员管理'),
    _MenuItem(icon: Icons.store, label: '店铺管理'),
    _MenuItem(icon: Icons.videocam, label: '媒体管理'),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(apiClient: widget.apiClient, sessionStore: widget.sessionStore),
      ProductManagePage(apiClient: widget.apiClient, sessionStore: widget.sessionStore),
      PetAuditPage(apiClient: widget.apiClient),
      OrderManagePage(apiClient: widget.apiClient),
      RefundAuditPage(apiClient: widget.apiClient),
      MemberManagePage(apiClient: widget.apiClient),
      StoreManagePage(apiClient: widget.apiClient),
      MediaManagePage(apiClient: widget.apiClient),
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
                        (widget.sessionStore.user?.displayName ?? 'A').isNotEmpty
                            ? widget.sessionStore.user!.displayName[0].toUpperCase()
                            : 'A',
                        style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onPrimary),
                      ),
                    ),
                    label: Text(widget.sessionStore.user?.displayName ?? 'Admin',
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
                                (widget.sessionStore.user?.displayName ?? 'A').isNotEmpty
                                    ? widget.sessionStore.user!.displayName[0].toUpperCase()
                                    : 'A',
                                style: TextStyle(
                                    fontSize: 20,
                                    color: Theme.of(context).colorScheme.onPrimary),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(widget.sessionStore.user?.displayName ?? 'Admin',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700)),
                            Text(widget.sessionStore.user?.role ?? '',
                                style: const TextStyle(fontSize: 13)),
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

