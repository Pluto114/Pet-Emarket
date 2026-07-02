import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/session/session_store.dart';
import '../../../models/order.dart';
import '../../../models/product.dart';
import '../../../models/store.dart';
import '../../../shared/widgets/skeleton_loader.dart';

class MerchantDashboardPage extends StatefulWidget {
  const MerchantDashboardPage({
    required this.apiClient,
    required this.sessionStore,
    super.key,
  });

  final ApiClient apiClient;
  final SessionStore sessionStore;

  @override
  State<MerchantDashboardPage> createState() => _MerchantDashboardPageState();
}

class _MerchantDashboardPageState extends State<MerchantDashboardPage> {
  bool loading = true;
  String? errorText;
  List<Product> products = [];
  List<PetStore> stores = [];
  List<PetOrder> orders = [];

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
      stores = await widget.apiClient.listStores(authenticated: true);
      products = await widget.apiClient.listManagedProducts();
      orders = await widget.apiClient.listOrders();
    } catch (e) {
      errorText = e.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (loading) {
      return const SkeletonLoader(count: 4, height: 100);
    }

    final onSale = products.where((item) => item.status == 'ON_SALE').length;
    final livePets = products.where((item) => item.isLivePet).length;
    final openStores = stores.where((item) => item.status == 'OPEN').length;
    final payableOrders = orders.where((item) => item.status >= 1).toList();
    final sales = payableOrders.fold<double>(
      0,
      (total, item) => total + item.payAmount,
    );
    final pendingOrders =
        orders.where((item) => item.status == 0 || item.status == 1).length;

    return RefreshIndicator(
      onRefresh: loadData,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '商家概览',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '欢迎回来，${widget.sessionStore.user?.displayName ?? "商家"}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: loadData,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (errorText != null) ...[
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: theme.colorScheme.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        errorText!,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    TextButton(onPressed: loadData, child: const Text('重试')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          LayoutBuilder(
            builder: (ctx, constraints) {
              final wide = constraints.maxWidth > 600;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _StatCard(
                    icon: Icons.store,
                    label: '营业店铺',
                    value: '$openStores/${stores.length}',
                    color: const Color(0xFF204E4A),
                    wide: wide,
                  ),
                  _StatCard(
                    icon: Icons.inventory_2,
                    label: '在售商品',
                    value: onSale.toString(),
                    color: const Color(0xFF6FDA44),
                    wide: wide,
                  ),
                  _StatCard(
                    icon: Icons.receipt_long,
                    label: '待处理订单',
                    value: pendingOrders.toString(),
                    color: const Color(0xFFEC7357),
                    wide: wide,
                  ),
                  _StatCard(
                    icon: Icons.pets,
                    label: '活体宠物',
                    value: livePets.toString(),
                    color: const Color(0xFF7C4DFF),
                    wide: wide,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.payments_outlined,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '已支付销售额',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '¥${sales.toStringAsFixed(2)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '最近订单',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (orders.isEmpty)
            const Card(
              child: Padding(padding: EdgeInsets.all(20), child: Text('暂无订单')),
            )
          else
            ...orders
                .take(5)
                .map(
                  (order) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _statusColor(
                          order.status,
                        ).withAlpha(30),
                        child: Icon(
                          Icons.receipt,
                          color: _statusColor(order.status),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        order.orderNo,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '金额：¥${order.payAmount.toStringAsFixed(2)}',
                      ),
                      trailing: Chip(
                        label: Text(
                          order.statusName,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: _statusColor(
                          order.status,
                        ).withAlpha(20),
                        side: BorderSide.none,
                      ),
                    ),
                  ),
                ),
          const SizedBox(height: 24),
          Text(
            '商品概况',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (products.isEmpty)
            const Card(
              child: Padding(padding: EdgeInsets.all(20), child: Text('暂无商品')),
            )
          else
            ...products
                .take(5)
                .map(
                  (product) => Card(
                    child: ListTile(
                      leading: Icon(
                        product.isLivePet ? Icons.pets : Icons.inventory_2,
                      ),
                      title: Text(product.name),
                      subtitle: Text(
                        '${product.category} · 库存 ${product.stock}',
                      ),
                      trailing: _StatusChip(status: product.status),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Color _statusColor(int status) {
    switch (status) {
      case 0:
        return const Color(0xFFEC7357);
      case 1:
      case 2:
        return const Color(0xFF2196F3);
      case 3:
      case 4:
        return const Color(0xFF6FDA44);
      default:
        return Colors.red;
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      'ON_SALE' => '在售',
      'OFF_SALE' => '下架',
      'DRAFT' => '草稿',
      _ => status,
    };
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.wide = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    return SizedBox(
      width: wide ? 220 : null,
      child: Card(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withAlpha(6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side:
              isLight
                  ? BorderSide(
                    color: theme.colorScheme.outlineVariant.withAlpha(50),
                  )
                  : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withAlpha(isLight ? 20 : 30),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
