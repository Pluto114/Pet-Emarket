import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/api/api_client.dart';
import '../../../core/session/session_store.dart';
import '../../../models/admin_dashboard.dart';
import '../../../shared/widgets/skeleton_loader.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({required this.apiClient, required this.sessionStore, super.key});
  final ApiClient apiClient;
  final SessionStore sessionStore;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool loading = true;
  String? errorText;
  AdminDashboard? dashboard;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() { loading = true; errorText = null; });
    try {
      dashboard = await widget.apiClient.adminDashboard();
    } catch (e) {
      errorText = e.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (loading) {
      return const SkeletonLoader(count: 6, height: 100);
    }
    final data = dashboard;
    return RefreshIndicator(
      onRefresh: loadData,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('仪表盘', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          if (errorText != null) ...[
            Text(errorText!, style: TextStyle(color: theme.colorScheme.error)),
            const SizedBox(height: 12),
          ],
          // Stat cards
          LayoutBuilder(
            builder: (ctx, constraints) {
              final wide = constraints.maxWidth > 600;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _StatCard(icon: Icons.group, label: '用户总数', value: (data?.userCount ?? 0).toString(), color: const Color(0xFF2196F3), wide: wide),
                  _StatCard(icon: Icons.inventory_2, label: '在售商品', value: (data?.onSaleProductCount ?? 0).toString(), color: const Color(0xFF6FDA44), wide: wide),
                  _StatCard(icon: Icons.receipt_long, label: '订单总数', value: (data?.orderCount ?? 0).toString(), color: const Color(0xFFEC7357), wide: wide),
                  _StatCard(icon: Icons.money_off, label: '待处理退款', value: (data?.refundPendingCount ?? 0).toString(), color: const Color(0xFFE53935), wide: wide),
                  _StatCard(icon: Icons.pets, label: '待审核宠物', value: (data?.pendingLivePetAuditCount ?? 0).toString(), color: const Color(0xFF7C4DFF), wide: wide),
                  _StatCard(icon: Icons.store, label: '营业店铺', value: (data?.openStoreCount ?? 0).toString(), color: const Color(0xFF204E4A), wide: wide),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          if (data != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Icon(Icons.payments_outlined, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Text('总支付金额', style: theme.textTheme.titleMedium),
                    const Spacer(),
                    Text('¥${data.totalPayAmount.toStringAsFixed(2)}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],
          // Chart section
          if (data != null && data.orderStatusDistribution.isNotEmpty) ...[
            Text('订单状态分布', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  height: 220,
                  child: PieChart(
                    PieChartData(
                      sections: _buildPieSections(theme),
                      centerSpaceRadius: 50,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: _buildLegend(theme),
            ),
            const SizedBox(height: 28),
          ],
          if (data != null && data.topProducts.isNotEmpty) ...[
            Text('热销商品', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            ...data.topProducts.map((p) => Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.trending_up)),
                title: Text(p.productName),
                subtitle: Text('${p.category} · 销量 ${p.quantity}'),
                trailing: Text('¥${p.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            )),
            const SizedBox(height: 28),
          ],
          // Recent orders
          Text('最近订单', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          if (data == null || data.recentOrders.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('暂无订单')))
          else
            ...data.recentOrders.map((o) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _statusColor(o.status).withAlpha(30),
                  child: Icon(Icons.receipt, color: _statusColor(o.status), size: 20),
                ),
                title: Text(o.orderNo, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('金额：¥' + (o.payAmount.toStringAsFixed(2))),
                trailing: Chip(
                  label: Text(o.statusName, style: const TextStyle(fontSize: 12)),
                  backgroundColor: _statusColor(o.status).withAlpha(20),
                  side: BorderSide.none,
                ),
              ),
            )),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(ThemeData theme) {
    final counts = dashboard?.orderStatusDistribution ?? const <OrderStatusCount>[];
    final colors = [
      const Color(0xFF204E4A), const Color(0xFF6FDA44), const Color(0xFFEC7357),
      const Color(0xFFE1E53F), const Color(0xFF2196F3), const Color(0xFF9C27B0),
      const Color(0xFFFF9800),
    ];
    return counts.asMap().entries.map((e) {
      final i = e.key;
      final entry = e.value;
      return PieChartSectionData(
        color: colors[i % colors.length],
        value: entry.count.toDouble(),
        title: entry.count.toString(),
        radius: 60,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  List<Widget> _buildLegend(ThemeData theme) {
    final counts = dashboard?.orderStatusDistribution ?? const <OrderStatusCount>[];
    final colors = [
      const Color(0xFF204E4A), const Color(0xFF6FDA44), const Color(0xFFEC7357),
      const Color(0xFFE1E53F), const Color(0xFF2196F3), const Color(0xFF9C27B0),
      const Color(0xFFFF9800),
    ];
    return counts.asMap().entries.map((e) {
      final i = e.key;
      final entry = e.value;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[i % colors.length], borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 6),
          Text('${entry.statusName}: ${entry.count}', style: theme.textTheme.bodySmall),
        ],
      );
    }).toList();
  }

  Color _statusColor(int s) {
    switch (s) {
      case 0: return const Color(0xFFEC7357);
      case 1: return const Color(0xFF2196F3);
      case 2: case 3: case 4: return const Color(0xFF6FDA44);
      default: return Colors.red;
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  final bool wide;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color, this.wide = true});

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
          side: isLight
              ? BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(50))
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
                  color: isLight
                      ? color.withAlpha(20)
                      : color.withAlpha(30),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface, height: 1.1)),
                    const SizedBox(height: 4),
                    Text(label, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
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

