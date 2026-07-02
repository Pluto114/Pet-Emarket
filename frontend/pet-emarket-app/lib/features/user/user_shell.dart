import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/session/session_store.dart';
import '../../core/theme/app_theme.dart';
import 'cart/cart_page.dart';
import 'home/home_page.dart';
import 'order/order_page.dart';
import 'profile/profile_tab.dart';
import 'store/nearby_store_page.dart';

const _navItems = [
  {'l': 'Home', 'i': Icons.home},
  {'l': 'Nearby', 'i': Icons.store},
  {'l': 'Cart', 'i': Icons.shopping_cart},
  {'l': 'Orders', 'i': Icons.receipt_long},
  {'l': 'Me', 'i': Icons.person},
];

class UserShell extends StatefulWidget {
  const UserShell({
    required this.apiClient,
    required this.sessionStore,
    required this.onThemeToggle,
    required this.onLogout,
    this.onGoToMerchant,
    super.key,
  });
  final ApiClient apiClient;
  final SessionStore sessionStore;
  final VoidCallback onThemeToggle;
  final VoidCallback onLogout;
  final VoidCallback? onGoToMerchant;

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  int _idx = 0;
  final _searchCtrl = TextEditingController();

  static const _tabs = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: '首页',
    ),
    NavigationDestination(
      icon: Icon(Icons.store_outlined),
      selectedIcon: Icon(Icons.store),
      label: '附近',
    ),
    NavigationDestination(
      icon: Icon(Icons.shopping_cart_outlined),
      selectedIcon: Icon(Icons.shopping_cart),
      label: '购物车',
    ),
    NavigationDestination(
      icon: Icon(Icons.receipt_long_outlined),
      selectedIcon: Icon(Icons.receipt_long),
      label: '订单',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: '我的',
    ),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  PreferredSizeWidget _buildAppBar(ThemeData t, ColorScheme s, bool wide, double screenW) {
    final isLight = t.brightness == Brightness.light;
    final xWide = screenW > 1100;
    final navGap = xWide ? 24.0 : 12.0;
    final searchMaxW = xWide ? 400.0 : (wide ? 220.0 : screenW * 0.4);
    return PreferredSize(
      preferredSize: Size.fromHeight(wide ? 64 : 56),
      child: Container(
        color: PawmartColors.surfaceCard,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: wide && xWide ? 40 : 12, vertical: 4),
            child: Row(
              children: [
                // Logo
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: PawmartColors.primary500,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Icon(Icons.pets, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'PawMart',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: PawmartColors.primary500,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Search bar
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: searchMaxW),
                    child: SizedBox(
                      height: 38,
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: PawmartColors.neutral50,
                          hintText: wide ? '搜索宠物、口粮…' : '搜索…',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: PawmartColors.textSecondary.withAlpha(150),
                          ),
                          prefixIcon: Icon(Icons.search_rounded, size: 20, color: PawmartColors.neutral400),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(pawmartRadiusFull),
                            borderSide: BorderSide(color: PawmartColors.neutral200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(pawmartRadiusFull),
                            borderSide: BorderSide(color: PawmartColors.primary500, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 9),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Wide nav items
                if (wide) ...[
                  ...List.generate(_navItems.length, (i) {
                    final item = _navItems[i];
                    final active = i == _idx;
                    return Padding(
                      padding: EdgeInsets.only(left: i == 0 ? 0 : navGap),
                      child: InkWell(
                        onTap: () => setState(() => _idx = i),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item['i'] as IconData,
                                size: 18,
                                color: active ? PawmartColors.primary500 : PawmartColors.textSecondary,
                              ),
                              Text(
                                item['l'] as String,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                                  color: active ? PawmartColors.primary500 : PawmartColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 8),
                ],
                // Theme toggle
                IconButton(
                  tooltip: '切换主题',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    isLight ? Icons.dark_mode : Icons.light_mode,
                    color: PawmartColors.textSecondary,
                  ),
                  onPressed: widget.onThemeToggle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    final t = Theme.of(ctx);
    final s = t.colorScheme;
    final w = MediaQuery.of(ctx).size.width;
    final wide = w > 800;

    final pages = <Widget>[
      HomePage(
        apiClient: widget.apiClient,
        sessionStore: widget.sessionStore,
        onGoToMerchant: widget.onGoToMerchant,
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

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 2000),
        child: Scaffold(
          backgroundColor: PawmartColors.surfaceBg,
          appBar: _buildAppBar(t, s, wide, w),
          body: IndexedStack(index: _idx, children: pages),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _idx,
                  destinations: _tabs,
                  onDestinationSelected: (i) => setState(() => _idx = i),
                ),
        ),
      ),
    );
  }
}
