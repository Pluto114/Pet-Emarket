import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/session/session_store.dart';
import '../product/product_manage_page.dart';
import '../pet_audit/pet_audit_page.dart';
import '../order/order_manage_page.dart';
import '../refund/refund_audit_page.dart';
import '../member/member_manage_page.dart';
import '../store/store_manage_page.dart';
import '../media/media_manage_page.dart';
import 'dashboard_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({required this.apiClient, required this.sessionStore, super.key});
  final ApiClient apiClient;
  final SessionStore sessionStore;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  static const menuItems = [
    _MenuItem(icon: Icons.dashboard, label: '数据看板'),
    _MenuItem(icon: Icons.inventory_2, label: '商品管理'),
    _MenuItem(icon: Icons.pets, label: '宠物审核'),
    _MenuItem(icon: Icons.receipt_long, label: '订单管理'),
    _MenuItem(icon: Icons.money_off, label: '退单审核'),
    _MenuItem(icon: Icons.group, label: '会员管理'),
    _MenuItem(icon: Icons.store, label: '商店管理'),
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
            title: const Text('Pet-Emarket 管理后台'),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(child: Text(widget.sessionStore.user?.displayName ?? '')),
              ),
              IconButton(
                tooltip: '退出登录',
                icon: const Icon(Icons.logout),
                onPressed: () => widget.sessionStore.clear(),
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
          bottomNavigationBar: wide ? null : NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (i) => setState(() => selectedIndex = i),
            destinations: menuItems.take(4).map((m) => NavigationDestination(
              icon: Icon(m.icon),
              label: m.label,
            )).toList(),
          ),
          drawer: wide ? null : Drawer(
            child: ListView(
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(Icons.admin_panel_settings, size: 40, color: Colors.white),
                      const SizedBox(height: 8),
                      Text(widget.sessionStore.user?.displayName ?? '管理员', style: const TextStyle(color: Colors.white, fontSize: 18)),
                      Text(widget.sessionStore.user?.role ?? '', style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                for (var i = 0; i < menuItems.length; i++)
                  ListTile(
                    selected: selectedIndex == i,
                    leading: Icon(menuItems[i].icon),
                    title: Text(menuItems[i].label),
                    onTap: () {
                      setState(() => selectedIndex = i);
                      Navigator.pop(context);
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

