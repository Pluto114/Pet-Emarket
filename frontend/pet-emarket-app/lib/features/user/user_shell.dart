import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/session/session_store.dart';
import '../../core/theme/app_theme.dart';
import 'cart/cart_page.dart' show CartPage, CartPageState;
import 'home/home_page.dart';
import 'order/order_page.dart' show OrderPage, OrderPageState;
import 'product/product_list_page.dart';
import 'profile/profile_tab.dart';
import 'store/nearby_store_page.dart';
import 'announcement/announcement_page.dart';
import 'video/video_page.dart';

const _navItems = [
  {'l': '首页', 'i': Icons.home},
  {'l': '商品', 'i': Icons.shopping_bag},
  {'l': '附近', 'i': Icons.store},
  {'l': '购物车', 'i': Icons.shopping_cart},
  {'l': '订单', 'i': Icons.receipt_long},
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
  final _cartKey = GlobalKey<CartPageState>();
  final _orderKey = GlobalKey<OrderPageState>();

  void _onTabChanged(int i) {
    setState(() => _idx = i);
    if (i == 3) _cartKey.currentState?.load();
    if (i == 4) _orderKey.currentState?.load();
  }

  static const _tabs = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: '首页',
    ),
    NavigationDestination(
      icon: Icon(Icons.shopping_bag_outlined),
      selectedIcon: Icon(Icons.shopping_bag),
      label: '商品',
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

  PreferredSizeWidget _buildAppBar(
    ThemeData t,
    ColorScheme s,
    bool wide,
    double screenW,
  ) {
    final isLight = t.brightness == Brightness.light;
    final xWide = screenW > 1100;
    final navGap = xWide ? 24.0 : 12.0;
    final searchMaxW = xWide ? 400.0 : (wide ? 220.0 : screenW * 0.35);
    return PreferredSize(
      preferredSize: Size.fromHeight(wide ? 64 : 56),
      child: Container(
        color: PawmartColors.surfaceCard,
        child: SafeArea(
          bottom: false,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: PawmartColors.neutral200),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: wide && xWide ? 40 : 12,
                vertical: 4,
              ),
              child: Row(
                children: [
                  // Logo
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: PawmartColors.primary500,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.pets,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'PawMart',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: PawmartColors.primary500,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Wide nav items
                  if (wide) ...[
                    ...List.generate(_navItems.length, (i) {
                      final item = _navItems[i];
                      final active = i == _idx;
                      return Padding(
                        padding: EdgeInsets.only(left: i == 0 ? 0 : navGap),
                        child: InkWell(
                          onTap: () => _onTabChanged(i),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item['i'] as IconData,
                                  size: 20,
                                  color: active
                                      ? PawmartColors.primary500
                                      : PawmartColors.textSecondary,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item['l'] as String,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: active
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: active
                                        ? PawmartColors.primary500
                                        : PawmartColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(width: 12),
                  ],
                  const Spacer(),
                  // Search bar
                  Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: searchMaxW),
                      child: SizedBox(
                        height: 38,
                        child: TextField(
                          controller: _searchCtrl,
                          onSubmitted: (_) => _onTabChanged(1),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: PawmartColors.neutral50,
                            hintText: wide ? '搜索宠物、口粮…' : '搜索…',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: PawmartColors.textSecondary.withAlpha(150),
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: PawmartColors.neutral400,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(pawmartRadiusFull),
                              borderSide: BorderSide(color: PawmartColors.neutral200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(pawmartRadiusFull),
                              borderSide: BorderSide(
                                color: PawmartColors.primary500,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 9),
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Announcements
                  IconButton(
                    tooltip: '公告',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.campaign_outlined, size: 20, color: PawmartColors.textSecondary),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnnouncementPage(apiClient: widget.apiClient))),
                  ),
                  // Video page
                  IconButton(
                    tooltip: '宠物视频',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.videocam_outlined,
                      size: 20,
                      color: PawmartColors.textSecondary,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VideoPage(apiClient: widget.apiClient),
                      ),
                    ),
                  ),
                  // Theme toggle
                  IconButton(
                    tooltip: '切换主题',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      isLight ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                      size: 20,
                      color: PawmartColors.textSecondary,
                    ),
                    onPressed: widget.onThemeToggle,
                  ),
                  // User profile
                  IconButton(
                    tooltip: '个人中心',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.person_outline,
                      size: 20,
                      color: _idx == 5 ? PawmartColors.primary500 : PawmartColors.textSecondary,
                    ),
                    onPressed: () => _onTabChanged(5),
                  ),
                  // Quick logout
                  IconButton(
                    tooltip: '退出登录',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.logout,
                      size: 20,
                      color: PawmartColors.textSecondary,
                    ),
                    onPressed: widget.onLogout,
                  ),
                ],
              ),
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
        onNavigateToProducts: () => _onTabChanged(1),
      ),
      ProductListPage(apiClient: widget.apiClient),
      NearbyStorePage(apiClient: widget.apiClient),
      CartPage(key: _cartKey, apiClient: widget.apiClient, sessionStore: widget.sessionStore),
      OrderPage(key: _orderKey, apiClient: widget.apiClient, sessionStore: widget.sessionStore),
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
          body: MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(widget.sessionStore.textScale.clamp(1.0, 1.5))),
            child: IndexedStack(index: _idx, children: pages),
          ),
          bottomNavigationBar:
              wide
                  ? null
                  : NavigationBar(
                    selectedIndex: _idx,
                    destinations: _tabs,
                    onDestinationSelected: (i) => _onTabChanged(i),
                  ),
        ),
      ),
    );
  }
}
