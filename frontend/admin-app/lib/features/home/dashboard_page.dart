import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/session/session_store.dart';
import '../../models/order.dart';

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
      recentOrders = orders.take(5).toList();
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: loadData,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('数据看板', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _StatCard(icon: Icons.group, label: '用户总数', value: userCount.toString(), color: Colors.blue),
              _StatCard(icon: Icons.inventory_2, label: '商品总数', value: productCount.toString(), color: Colors.green),
              _StatCard(icon: Icons.receipt_long, label: '订单总数', value: orderCount.toString(), color: Colors.orange),
              _StatCard(icon: Icons.money_off, label: '待处理退单', value: refundCount.toString(), color: Colors.red),
            ],
          ),
          const SizedBox(height: 24),
          Text('最近订单', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          if (loading)
            const Center(child: Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator()))
          else if (recentOrders.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('暂无订单')))
          else
            ...recentOrders.map((o) => Card(
              child: ListTile(
                title: Text(o.orderNo ?? ''),
                subtitle: Text('状态: ${o.statusName ?? ''}  金额: ¥${o.payAmount?.toStringAsFixed(2) ?? '0.00'}'),
                trailing: Chip(label: Text(o.statusName ?? '')),
              ),
            )),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                  Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

