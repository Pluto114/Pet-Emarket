import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../models/order.dart';

class RefundAuditPage extends StatefulWidget {
  const RefundAuditPage({required this.apiClient, super.key});

  final ApiClient apiClient;

  @override
  State<RefundAuditPage> createState() => _RefundAuditPageState();
}

class _RefundAuditPageState extends State<RefundAuditPage> {
  bool loading = true;
  String? errorText;
  List<PetOrder> refundOrders = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      errorText = null;
    });
    try {
      final all = await widget.apiClient.listOrders();
      refundOrders = all.where((order) => order.status == -2).toList();
    } catch (error) {
      errorText = error.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _audit(PetOrder order, bool approved) async {
    try {
      await widget.apiClient.operateOrder(
        order.id,
        'audit-refund',
        body: {
          'approved': approved,
          'auditRemark': approved ? 'Approved by admin' : 'Rejected by admin',
          if (!approved && order.refundRollbackStatus != null)
            'rollbackStatus': order.refundRollbackStatus,
        },
      );
      await load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Refund Audit',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: CircularProgressIndicator(),
              ),
            ),
          if (errorText != null)
            Text(errorText!, style: TextStyle(color: theme.colorScheme.error)),
          if (!loading && refundOrders.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No pending refunds'),
              ),
            ),
          ...refundOrders.map(
            (order) => Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            order.orderNo,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const Chip(
                          label: Text('Refund Requested'),
                          backgroundColor: Colors.red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Pay ¥${order.payAmount.toStringAsFixed(2)}'),
                    ...order.items.map(
                      (item) => Text('  ${item.productName} x${item.quantity}'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Reason: ${order.refundReason.isEmpty ? 'No reason' : order.refundReason}',
                    ),
                    Text(
                      'Reject rollback status: ${order.refundRollbackStatus ?? 2}',
                    ),
                    Text(
                      'Inventory restored after approval: ${order.inventoryRestored ? 'yes' : 'no'}',
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        FilledButton(
                          onPressed: () => _audit(order, true),
                          child: const Text('Approve Refund'),
                        ),
                        OutlinedButton(
                          onPressed: () => _audit(order, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Reject Refund'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
