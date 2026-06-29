import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../models/order.dart';

class OrderManagePage extends StatefulWidget {
  const OrderManagePage({required this.apiClient, super.key});

  final ApiClient apiClient;

  @override
  State<OrderManagePage> createState() => _OrderManagePageState();
}

class _OrderManagePageState extends State<OrderManagePage> {
  bool loading = true;
  String? errorText;
  List<PetOrder> orders = [];

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
      orders = await widget.apiClient.listOrders();
    } catch (error) {
      errorText = error.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  Color _statusColor(int status) {
    if (status == 0) return Colors.orange;
    if (status == 1 || status == 2) return Colors.blue;
    if (status >= 3 && status <= 4) return Colors.green;
    return Colors.red;
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
                  'Order Management',
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
          if (!loading && orders.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No orders'),
              ),
            ),
          ...orders.map(
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
                        Chip(
                          label: Text(order.statusName),
                          backgroundColor: _statusColor(
                            order.status,
                          ).withValues(alpha: 0.2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pay ¥${order.payAmount.toStringAsFixed(2)} / Discount ¥${order.discountAmount.toStringAsFixed(2)}',
                    ),
                    ...order.items.map(
                      (item) => Text('  ${item.productName} x${item.quantity}'),
                    ),
                    if (order.refundReason.isNotEmpty ||
                        order.inventoryRestored) ...[
                      const SizedBox(height: 8),
                      if (order.refundReason.isNotEmpty)
                        Text('Refund reason: ${order.refundReason}'),
                      if (order.refundAuditStatus.isNotEmpty)
                        Text('Refund audit: ${order.refundAuditStatus}'),
                      Text(
                        'Inventory restored: ${order.inventoryRestored ? 'yes' : 'no'}',
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton(
                          onPressed:
                              order.status == 1
                                  ? () => _operate(order, 'ship')
                                  : null,
                          child: const Text('Ship'),
                        ),
                        OutlinedButton(
                          onPressed:
                              [0, 1].contains(order.status)
                                  ? () => _operate(
                                    order,
                                    'cancel',
                                    reason: 'Admin canceled order',
                                  )
                                  : null,
                          child: const Text('Cancel'),
                        ),
                        OutlinedButton(
                          onPressed:
                              [3, 4].contains(order.status)
                                  ? () => _operate(
                                    order,
                                    'admin-refund',
                                    reason: 'Admin direct refund',
                                  )
                                  : null,
                          child: const Text('Direct Refund'),
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

  Future<void> _operate(
    PetOrder order,
    String action, {
    String reason = '',
  }) async {
    try {
      await widget.apiClient.operateOrder(
        order.id,
        action,
        body: reason.isEmpty ? const {} : {'reason': reason},
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
}
