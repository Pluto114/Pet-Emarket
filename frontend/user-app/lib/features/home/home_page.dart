import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/session/session_store.dart';
import '../product/product_detail_page.dart';
import '../users/users_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    required this.apiClient,
    required this.sessionStore,
    super.key,
  });

  final ApiClient apiClient;
  final SessionStore sessionStore;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(apiClient: widget.apiClient, sessionStore: widget.sessionStore),
      ProductsPage(apiClient: widget.apiClient, sessionStore: widget.sessionStore),
      UsersPage(apiClient: widget.apiClient, sessionStore: widget.sessionStore),
    ];
    final destinations = const [
      NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: '总览'),
      NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: '商品'),
      NavigationDestination(icon: Icon(Icons.group_outlined), selectedIcon: Icon(Icons.group), label: '用户'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 860;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Pet-Emarket 控制台'),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(child: Text(widget.sessionStore.user?.displayName ?? '')),
              ),
              IconButton(
                tooltip: '退出登录',
                onPressed: widget.sessionStore.clear,
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: Row(
            children: [
              if (wide)
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) => setState(() => selectedIndex = index),
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('总览')),
                    NavigationRailDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: Text('商品')),
                    NavigationRailDestination(icon: Icon(Icons.group_outlined), selectedIcon: Icon(Icons.group), label: Text('用户')),
                  ],
                ),
              Expanded(child: pages[selectedIndex]),
            ],
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: selectedIndex,
                  destinations: destinations,
                  onDestinationSelected: (index) => setState(() => selectedIndex = index),
                ),
        );
      },
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    required this.apiClient,
    required this.sessionStore,
    super.key,
  });

  final ApiClient apiClient;
  final SessionStore sessionStore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = sessionStore.user;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('基础骨架已连接', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('当前阶段先跑通登录、鉴权、用户 CRUD 和商品 CRUD，订单与推荐后续接入。', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _InfoCard(
              icon: Icons.verified_user,
              title: '登录账号',
              value: '${user?.username ?? '-'} / ${user?.role ?? '-'}',
            ),
            _InfoCard(
              icon: Icons.workspace_premium,
              title: '会员等级',
              value: user?.memberLevel ?? '-',
            ),
            _InfoCard(
              icon: Icons.api,
              title: 'API 地址',
              value: apiClient.baseUrl,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('当前可演示链路', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                SizedBox(height: 10),
                _CheckLine(text: '管理员登录获取 Token'),
                _CheckLine(text: 'Token 鉴权访问用户列表'),
                _CheckLine(text: '创建、修改、删除用户'),
                _CheckLine(text: '游客浏览商品列表'),
                _CheckLine(text: '管理员创建、修改、删除商品'),
                _CheckLine(text: '活体宠物商品保留检疫、疫苗、健康状态字段'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 260,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.labelMedium),
                    const SizedBox(height: 4),
                    Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckLine extends StatelessWidget {
  const _CheckLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
