/// 用户端首页
/// 展示欢迎卡片、快捷入口、热门商品、活体推荐
library;

import 'package:flutter/material.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/session/session_store.dart';
import '../../../../models/product.dart';
import '../ai_assistant/ai_assistant_page.dart';
import '../product/product_detail_page.dart';
import '../recommendation/recommendation_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    required this.apiClient,
    required this.sessionStore,
    required this.onNavigate,
    super.key,
  });

  final ApiClient apiClient;
  final SessionStore sessionStore;
  final ValueChanged<int> onNavigate;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
    setState(() {
      loading = true;
      errorText = null;
    });
    try {
      final products = await widget.apiClient.listProducts(keyword: '');
      hotProducts =
          products.where((p) => p.status == 'ON_SALE').take(6).toList();
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
          _WelcomeCard(theme: theme, user: user),
          const SizedBox(height: 16),
          _QuickActions(apiClient: widget.apiClient, onNavigate: widget.onNavigate),
          const SizedBox(height: 20),
          if (loading)
            const Center(child: Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator()))
          else if (errorText != null)
            _ErrorBanner(message: errorText!, onRetry: loadData)
          else ...[
            _ProductSection(
              title: 'Hot Products',
              products: hotProducts,
              apiClient: widget.apiClient,
              onViewAll: () => _push(context, ProductsPage(apiClient: widget.apiClient, sessionStore: widget.sessionStore)),
            ),
            const SizedBox(height: 20),
            _ProductSection(
              title: 'Featured Pets',
              products: livePets,
              apiClient: widget.apiClient,
              onViewAll: () => _push(context, ProductsPage(apiClient: widget.apiClient, sessionStore: widget.sessionStore, filterType: 'PET_LIVE')),
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

// ── 欢迎卡片 ──
class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.theme, required this.user});
  final ThemeData theme;
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              child: Text(user != null && user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user != null ? 'Hello, ${user.displayName}' : 'Welcome to Pet-Emarket',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user != null ? '${user.memberLevel} Member' : 'Sign in for more benefits',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 快捷入口行 ──
class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.apiClient, required this.onNavigate});
  final ApiClient apiClient;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QuickAction(icon: Icons.store, label: 'Nearby Stores', onTap: () => onNavigate(1)),
        _QuickAction(icon: Icons.smart_toy_outlined, label: 'AI Asst',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AiAssistantPage(apiClient: apiClient)))),
        _QuickAction(icon: Icons.recommend_outlined, label: 'Recommend',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RecommendationPage(apiClient: apiClient)))),
        _QuickAction(icon: Icons.pets, label: 'Live Pets',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ProductsPage(apiClient: apiClient, sessionStore: SessionStore(), filterType: 'PET_LIVE')))),
      ],
    );
  }
}

// ── 错误横幅 ──
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Text(message, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh, size: 18), label: const Text('Retry')),
        ]),
      ),
    );
  }
}

// ── 商品区块（横向滚动） ──
class _ProductSection extends StatelessWidget {
  const _ProductSection({required this.title, required this.products, required this.apiClient, required this.onViewAll});
  final String title;
  final List<Product> products;
  final ApiClient apiClient;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
        TextButton(onPressed: onViewAll, child: const Text('More >')),
      ]),
      const SizedBox(height: 8),
      if (products.isEmpty)
        const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No products yet')))
      else
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (ctx, i) => _ProductCard(product: products[i], apiClient: apiClient),
          ),
        ),
    ]);
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
          child: Column(children: [
            Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 6),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ]),
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
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ProductDetailPage(product: product, apiClient: apiClient))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              height: 100,
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              child: Center(
                  child: Icon(product.isLivePet ? Icons.pets : Icons.shopping_bag_outlined,
                      size: 40, color: theme.colorScheme.primary)),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 4),
                Text('¥${product.price.toStringAsFixed(2)}',
                    style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
