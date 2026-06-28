import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/session/session_store.dart';
import '../../../models/product.dart';
import 'cart/cart_page.dart';
import 'order/order_page.dart';
import 'product/product_detail_page.dart';
import 'store/nearby_store_page.dart';
import 'ai_assistant/ai_assistant_page.dart';
import 'recommendation/recommendation_page.dart';

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

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeTab(apiClient: widget.apiClient, sessionStore: widget.sessionStore, onNavigate: (i) => setState(() => selectedIndex = i)),
      NearbyStorePage(apiClient: widget.apiClient),
      CartPage(apiClient: widget.apiClient),
      OrderPage(apiClient: widget.apiClient, sessionStore: widget.sessionStore),
      ProfileTab(apiClient: widget.apiClient, sessionStore: widget.sessionStore, onThemeToggle: widget.onThemeToggle, onLogout: widget.onLogout),
    ];

    final destinations = const [
      NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
      NavigationDestination(icon: Icon(Icons.store_outlined), selectedIcon: Icon(Icons.store), label: 'Nearby'),
      NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), selectedIcon: Icon(Icons.shopping_cart), label: 'Cart'),
      NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
      NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet-Emarket'),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            icon: Icon(Theme.of(context).brightness == Brightness.light
                ? Icons.dark_mode
                : Icons.light_mode),
            onPressed: widget.onThemeToggle,
          ),
        ],
      ),
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
                        Text(user != null ? 'Hello, ' + user.displayName : 'Welcome to Pet-Emarket', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(user != null ? user.memberLevel + ' Member' : 'Sign in for more benefits', style: theme.textTheme.bodySmall),
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
              _QuickAction(icon: Icons.store, label: 'Nearby Stores', onTap: () => widget.onNavigate(1)),
              _QuickAction(icon: Icons.smart_toy_outlined, label: 'AI Assistant', onTap: () => _push(context, AiAssistantPage(apiClient: widget.apiClient))),
              _QuickAction(icon: Icons.recommend_outlined, label: 'Recommendations', onTap: () => _push(context, RecommendationPage(apiClient: widget.apiClient))),
              _QuickAction(icon: Icons.pets, label: 'Live Pets', onTap: () => _push(context, ProductsPage(apiClient: widget.apiClient, sessionStore: widget.sessionStore, filterType: 'PET_LIVE'))),
            ],
          ),
          const SizedBox(height: 20),

          if (loading)
            const Center(child: Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator()))
          else ...[
            // Hot products
            _SectionHeader(title: 'Hot Products', onTap: () => _push(context, ProductsPage(apiClient: widget.apiClient, sessionStore: widget.sessionStore))),
            const SizedBox(height: 8),
            if (hotProducts.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No products yet')))
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
            _SectionHeader(title: 'Featured Pets', onTap: () => _push(context, ProductsPage(apiClient: widget.apiClient, sessionStore: widget.sessionStore, filterType: 'PET_LIVE'))),
            const SizedBox(height: 8),
            if (livePets.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No live pets yet')))
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
        TextButton(onPressed: onTap, child: const Text('More >')),
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
  const ProfileTab({required this.apiClient, required this.sessionStore, required this.onThemeToggle, required this.onLogout, super.key});
  final ApiClient apiClient;
  final SessionStore sessionStore;
  final VoidCallback onThemeToggle;
  final VoidCallback onLogout;

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
            Text('Please sign in first', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            FilledButton(onPressed: onLogout, child: const Text('Go to Login')),
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
                CircleAvatar(radius: 30, backgroundColor: theme.colorScheme.primary, child: Text(user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?', style: TextStyle(fontSize: 24, color: theme.colorScheme.onPrimary))),
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
        _InfoTile(icon: Icons.phone, title: 'Phone', value: user.phone.isNotEmpty ? user.phone : 'Not set'),
        _InfoTile(icon: Icons.email, title: 'Email', value: user.email.isNotEmpty ? user.email : 'Not set'),
        _InfoTile(icon: Icons.verified_user, title: 'Role', value: user.role),
        _InfoTile(icon: Icons.workspace_premium, title: 'Member Level', value: user.memberLevel),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.brightness_6),
          title: const Text('Toggle Theme'),
          onTap: onThemeToggle,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onLogout,
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
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
