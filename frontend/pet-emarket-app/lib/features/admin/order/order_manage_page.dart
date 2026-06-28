import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../models/order.dart';

class OrderManagePage extends StatefulWidget {
  const OrderManagePage({required this.apiClient, super.key});
  final ApiClient apiClient;
  @override State<OrderManagePage> createState() => _OrderManagePageState();
}

class _OrderManagePageState extends State<OrderManagePage> {
  bool loading = true;
  List<PetOrder> orders = [];

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    setState(() => loading = true);
    try { orders = await widget.apiClient.listOrders(); } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  Color _statusColor(int s) {
    if (s == 0) return Colors.orange;
    if (s == 1) return Colors.blue;
    if (s >= 2 && s <= 4) return Colors.green;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(padding: const EdgeInsets.all(20), children: [
        Text('Order Management', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (loading) const Center(child: Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator())),
        if (!loading && orders.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No orders'))),
        ...orders.map((o) => Card(
          child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(o.orderNo, style: const TextStyle(fontWeight: FontWeight.w700))),
              Chip(label: Text(o.statusName), backgroundColor: _statusColor(o.status).withValues(alpha: 0.2)),
            ]),
            const SizedBox(height: 6),
            Text('¥${o.payAmount.toStringAsFixed(2)}'),
            ...o.items.map((i) => Text('  ${i.productName} x${i.quantity}')),
            if (o.status == 1) ...[
              const SizedBox(height: 8),
              FilledButton(onPressed: () => _ship(o), child: const Text('Ship')),
            ],
          ])),
        )),
      ]),
    );
  }

  Future<void> _ship(PetOrder o) async {
    try {
      await widget.apiClient.operateOrder(o.id, 'ship');
      await load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

