import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/api/api_client.dart';
import '../../../core/session/session_store.dart';
import '../../../models/order.dart';
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
  int userCount = 0, productCount = 0, orderCount = 0, refundCount = 0;
  List<dynamic> recentOrders = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => loading = true);
    try {
      final results = await Future.wait([
        widget.apiClient.listUsers(),
        widget.apiClient.listProducts(),
        widget.apiClient.listOrders(),
      ]);
      userCount = (results[0] as List).length;
      productCount = (results[1] as List).length;
      final orders = results[2] as List<PetOrder>;
      orderCount = orders.length;
      refundCount = orders.where((o) => o.status == -2).length;
      _allOrders = orders;
      recentOrders = orders.take(5).toList();
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  List<PetOrder> _allOrders = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (loading) {
      return const SkeletonLoader(count: 6, height: 100);
    }
    return RefreshIndicator(
      onRefresh: loadData,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Dashboard', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          // Stat cards
          LayoutBuilder(
            builder: (ctx, constraints) {
              final wide = constraints.maxWidth > 600;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _StatCard(icon: Icons.group, label: 'Total Users', value: userCount.toString(), color: Colors.blue, wide: wide),
                  _StatCard(icon: Icons.inventory_2, label: 'Total Products', value: productCount.toString(), color: Colors.green, wide: wide),
                  _StatCard(icon: Icons.receipt_long, label: 'Total Orders', value: orderCount.toString(), color: Colors.orange, wide: wide),
                  _StatCard(icon: Icons.money_off, label: 'Pending Refunds', value: refundCount.toString(), color: Colors.red, wide: wide),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          // Chart section
          if (_allOrders.isNotEmpty) ...[
            Text('Order Status Distribution', style: theme.textTheme.titleLarge),
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
          // Recent orders
          Text('Recent Orders', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          if (recentOrders.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No orders yet')))
          else
            ...recentOrders.map((o) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _statusColor(o.status).withAlpha(30),
                  child: Icon(Icons.receipt, color: _statusColor(o.status), size: 20),
                ),
                title: Text(o.orderNo, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Amount: ' + (o.payAmount.toStringAsFixed(2))),
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
    final statusCounts = <String, int>{};
    for (final o in _allOrders) {
      statusCounts[o.statusName] = (statusCounts[o.statusName] ?? 0) + 1;
    }
    final colors = [
      Colors.blue, Colors.green, Colors.orange, Colors.purple,
      Colors.teal, Colors.red, Colors.amber,
    ];
    return statusCounts.entries.toList().asMap().entries.map((e) {
      final i = e.key;
      final entry = e.value;
      return PieChartSectionData(
        color: colors[i % colors.length],
        value: entry.value.toDouble(),
        title: entry.value.toString(),
        radius: 60,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  List<Widget> _buildLegend(ThemeData theme) {
    final statusCounts = <String, int>{};
    for (final o in _allOrders) {
      statusCounts[o.statusName] = (statusCounts[o.statusName] ?? 0) + 1;
    }
    final colors = [
      Colors.blue, Colors.green, Colors.orange, Colors.purple,
      Colors.teal, Colors.red, Colors.amber,
    ];
    return statusCounts.entries.toList().asMap().entries.map((e) {
      final i = e.key;
      final entry = e.value;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[i % colors.length], borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 6),
          Text('${entry.key}: ${entry.value}', style: theme.textTheme.bodySmall),
        ],
      );
    }).toList();
  }

  Color _statusColor(int s) {
    switch (s) {
      case 0: return Colors.orange;
      case 1: return Colors.blue;
      case 2: case 3: case 4: return Colors.green;
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
    return SizedBox(
      width: wide ? 220 : null,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
                    const SizedBox(height: 2),
                    Text(label, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
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

