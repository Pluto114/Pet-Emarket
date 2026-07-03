import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../models/order.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/toast.dart';

class MerchantOrderPage extends StatefulWidget {
  const MerchantOrderPage({required this.apiClient, super.key});

  final ApiClient apiClient;

  @override
  State<MerchantOrderPage> createState() => _MerchantOrderPageState();
}

class _MerchantOrderPageState extends State<MerchantOrderPage> {
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
                  '订单管理',
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Card(
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
                      TextButton(onPressed: load, child: const Text('重试')),
                    ],
                  ),
                ),
              ),
            ),
          if (!loading && orders.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant.withAlpha(100),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '暂无订单',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '顾客下单后会显示在这里',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
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
                          label: Text(
                            order.statusName,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: _statusColor(
                            order.status,
                          ).withAlpha(25),
                          side: BorderSide.none,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Order items
                    ...order.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          children: [
                            Icon(
                              item.productType == 'PET_LIVE'
                                  ? Icons.pets
                                  : Icons.shopping_bag,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item.productName,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                            Text(
                              '×${item.quantity}',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '¥${item.subtotal.toStringAsFixed(2)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 16),
                    Row(
                      children: [
                        Text(
                          '合计：',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '¥${order.payAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        if (order.discountAmount > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '(优惠 ¥${order.discountAmount.toStringAsFixed(2)})',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (order.receiver.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${order.receiver} ${order.phone} · ${order.addressDetail}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (order.paymentNo.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '支付号: ${order.paymentNo}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (order.refundReason.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha(15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '退款原因: ${order.refundReason}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                              ),
                            ),
                            if (order.refundAuditStatus.isNotEmpty)
                              Text(
                                '退款审核: ${order.refundAuditStatus}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed:
                              order.status == 1
                                  ? () => _operate(order, 'ship')
                                  : null,
                          icon: const Icon(Icons.local_shipping, size: 18),
                          label: const Text('发货'),
                        ),
                        OutlinedButton.icon(
                          onPressed:
                              [0, 1].contains(order.status)
                                  ? () => _cancelOrder(order)
                                  : null,
                          icon: const Icon(Icons.cancel, size: 18),
                          label: const Text('取消订单'),
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
      if (mounted) showSuccess(context, action == 'ship' ? '已发货' : '操作成功');
      await load();
    } catch (error) {
      if (mounted) {
        showError(context, error.toString());
      }
    }
  }

  Future<void> _cancelOrder(PetOrder order) async {
    final confirmed = await showConfirmDialog(
      context,
      title: '取消订单',
      message: '确定要取消订单 "${order.orderNo}" 吗？取消后需要填写原因。',
      confirmLabel: '取消订单',
      destructive: true,
    );
    if (!confirmed) return;

    // Show reason dialog
    if (!mounted) return;
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('取消原因'),
            content: TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: '请输入取消原因',
                hintText: '如：缺货、顾客要求等',
              ),
              maxLines: 2,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('返回'),
              ),
              FilledButton(
                onPressed:
                    () => Navigator.pop(
                      ctx,
                      reasonCtrl.text.trim().isEmpty
                          ? '商家取消订单'
                          : reasonCtrl.text.trim(),
                    ),
                child: const Text('确认取消'),
              ),
            ],
          ),
    );
    reasonCtrl.dispose();
    if (reason == null) return;
    await _operate(order, 'cancel', reason: reason);
  }
}
