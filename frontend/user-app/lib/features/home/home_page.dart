import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/session/session_store.dart';
import '../../models/product.dart';
import '../cart/cart_page.dart';
import '../order/order_page.dart';
import '../product/product_detail_page.dart';
import '../store/nearby_store_page.dart';
import '../ai_assistant/ai_assistant_page.dart';
import '../recommendation/recommendation_page.dart';

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
      HomeTab(apiClient: widget.apiClient, sessionStore: widget.sessionStore, onNavigate: (i) => setState(() => selectedIndex = i)),
      NearbyStorePage(apiClient: widget.apiClient),
      CartPage(apiClient: widget.apiClient),
      OrderPage(apiClient: widget.apiClient, sessionStore: widget.sessionStore),
      ProfileTab(apiClient: widget.apiClient, sessionStore: widget.sessionStore),
    ];

    final destinations = const [
      NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '首页'),
      NavigationDestination(icon: Icon(Icons.store_outlined), selectedIcon: Icon(Icons.store), label: '附近'),
      NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), selectedIcon: Icon(Icons.shopping_cart), label: '购物车'),
      NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: '订单'),
      NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: '我的'),
    ];

    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        destinations: destinations,
        onDestinationSelected: (i) => setState(() => selectedIndex = i),
      ),
    );
  }
}

// ==================== Consumer Home Tab ====================
class HomeTab extends StatefulWidget {
  const HomeTab({required this.apiClient, required this.sessionStore, required this.onNavigate, super.key});
  final ApiClient apiClient;
  final SessionStore sessionStore;
  final ValueChanged<int> onNavigate;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool loading = true;
  String? errorText;
  List<Product> hotProducts = [];
  List<Product> livePets = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() { loading = true; errorText = null; });
    try {
      final products = await widget.apiClient.listProducts(keyword: '');
      hotProducts = products.where((p) => p.status == 'ON_SALE').take(6).toList();
      livePets = products.where((p) => p.type == 'PET_LIVE').take(4).toList();
    } catch (e) {
      errorText = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = widget.sessionStore.user;

    return RefreshIndicator(
      onRefresh: loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Welcome card
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(child: Text(user != null && user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?')),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user != null ? '你好, ' + user.displayName : '欢迎来到 Pet-Emarket', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(user != null ? user.memberLevel + ' 会员' : '登录后享受更多权益', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quick actions
          Row(
            children: [
              _QuickAction(icon: Icons.store, label: '附近商店', onTap: () => widget.onNavigate(1)),
              _QuickAction(icon: Icons.smart_toy_outlined, label: 'AI 问答', onTap: () => _push(context, AiAssistantPage(apiClient: widget.apiClient))),
              _QuickAction(icon: Icons.recommend_outlined, label: '商品推荐', onTap: () => _push(context, RecommendationPage(apiClient: widget.apiClient))),
              _QuickAction(icon: Icons.pets, label: '活体宠物', onTap: () => _push(context, ProductsPage(apiClient: widget.apiClient, sessionStore: widget.sessionStore, filterType: 'PET_LIVE'))),
            ],
          ),
          const SizedBox(height: 20),

          if (loading)
            const Center(child: Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator()))
          else ...[
            // Hot products
            _SectionHeader(title: '热门商品', onTap: () => _push(context, ProductsPage(apiClient: widget.apiClient, sessionStore: widget.sessionStore))),
            const SizedBox(height: 8),
            if (hotProducts.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('暂无商品，请先添加商品')))
            else
              SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: hotProducts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (ctx, i) => _ProductCard(product: hotProducts[i], apiClient: widget.apiClient),
                ),
              ),
            const SizedBox(height: 20),

            // Live pets
            _SectionHeader(title: '精选活体宠物', onTap: () => _push(context, ProductsPage(apiClient: widget.apiClient, sessionStore: widget.sessionStore, filterType: 'PET_LIVE'))),
            const SizedBox(height: 8),
            if (livePets.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('暂无活体宠物')))
            else
              SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: livePets.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (ctx, i) => _ProductCard(product: livePets[i], apiClient: widget.apiClient),
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onTap});
  final String title;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
        TextButton(onPressed: onTap, child: const Text('更多 >')),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 6),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.apiClient});
  final Product product;
  final ApiClient apiClient;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 160,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailPage(product: product, apiClient: apiClient))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 100,
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                child: Center(child: Icon(product.isLivePet ? Icons.pets : Icons.shopping_bag_outlined, size: 40, color: theme.colorScheme.primary)),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('¥' + product.price.toStringAsFixed(2), style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
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

// ==================== Profile Tab ====================
class ProfileTab extends StatelessWidget {
  const ProfileTab({required this.apiClient, required this.sessionStore, super.key});
  final ApiClient apiClient;
  final SessionStore sessionStore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = sessionStore.user;
    if (user == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline, size: 64, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('请先登录', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => sessionStore.clear(), child: const Text('去登录')),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(radius: 30, child: Text(user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?', style: const TextStyle(fontSize: 24))),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.displayName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('@' + user.username + '  |  ' + user.role + '  |  ' + user.memberLevel, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _InfoTile(icon: Icons.phone, title: '手机号', value: user.phone.isNotEmpty ? user.phone : '未设置'),
        _InfoTile(icon: Icons.email, title: '邮箱', value: user.email.isNotEmpty ? user.email : '未设置'),
        _InfoTile(icon: Icons.verified_user, title: '角色', value: user.role),
        _InfoTile(icon: Icons.workspace_premium, title: '会员等级', value: user.memberLevel),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => sessionStore.clear(),
          icon: const Icon(Icons.logout),
          label: const Text('退出登录'),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.title, required this.value});
  final IconData icon;
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: Text(value),
      ),
    );
  }
}
