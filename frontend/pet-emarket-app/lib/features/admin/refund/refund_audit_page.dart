import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../models/order.dart';

class RefundAuditPage extends StatefulWidget {
  const RefundAuditPage({required this.apiClient, super.key});
  final ApiClient apiClient;
  @override State<RefundAuditPage> createState() => _RefundAuditPageState();
}

class _RefundAuditPageState extends State<RefundAuditPage> {
  bool loading = true;
  List<PetOrder> refundOrders = [];

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final all = await widget.apiClient.listOrders();
      refundOrders = all.where((o) => o.status == -2).toList();
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  Future<void> _audit(PetOrder o, bool approved) async {
    try {
      await widget.apiClient.operateOrder(o.id, 'audit-refund', body: {'approved': approved, 'auditRemark': approved ? 'Approved' : 'Rejected'});
      await load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(padding: const EdgeInsets.all(20), children: [
        Text('Refund Audit', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (loading) const Center(child: Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator())),
        if (!loading && refundOrders.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No pending refunds'))),
        ...refundOrders.map((o) => Card(
          child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(o.orderNo, style: const TextStyle(fontWeight: FontWeight.w700))),
              const Chip(label: Text('Refund Requested'), backgroundColor: Colors.red),
            ]),
            const SizedBox(height: 4),
            Text('¥${o.payAmount.toStringAsFixed(2)}'),
            ...o.items.map((i) => Text('  ${i.productName} x${i.quantity}')),
            const SizedBox(height: 8),
            Row(children: [
              FilledButton(onPressed: () => _audit(o, true), child: const Text('Approve Refund')),
              const SizedBox(width: 12),
              OutlinedButton(onPressed: () => _audit(o, false), style: OutlinedButton.styleFrom(foregroundColor: Colors.red), child: const Text('Reject Refund')),
            ]),
          ])),
        )),
      ]),
    );
  }
}

