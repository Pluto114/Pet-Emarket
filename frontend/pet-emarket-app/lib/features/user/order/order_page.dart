import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/session/session_store.dart';
import '../../../models/order.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({
    required this.apiClient,
    required this.sessionStore,
    super.key,
  });

  final ApiClient apiClient;
  final SessionStore sessionStore;

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  bool loading = true;
  String? errorText;
  List<PetOrder> orders = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  bool get isAdmin {
    final role = widget.sessionStore.user?.role;
    return role == 'ADMIN' || role == 'MERCHANT';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '订单状态机',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
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
              Text(
                errorText!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            if (!loading && orders.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('暂无订单。先到购物车生成订单。'),
                ),
              ),
            if (!loading)
              ...orders.map(
                (order) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OrderCard(
                    order: order,
                    isAdmin: isAdmin,
                    onOperate: operate,
                    onReview: _reviewOrder,
                    onReasonedAction: _reasonedAction,
                    onRefundAudit: _auditRefund,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
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
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> operate(
    PetOrder order,
    String action, {
    Map<String, dynamic> body = const {},
  }) async {
    try {
      await widget.apiClient.operateOrder(order.id, action, body: body);
      await load();
    } catch (error) {
      if (mounted) showError(error);
    }
  }

  Future<void> _reasonedAction(
    PetOrder order,
    String action,
    String title,
    String fallbackReason,
  ) async {
    final reason = await _showReasonDialog(
      title: title,
      fallbackReason: fallbackReason,
    );
    if (reason == null) return;
    await operate(order, action, body: {'reason': reason});
  }

  Future<void> _auditRefund(PetOrder order, bool approved) async {
    final remark = await _showReasonDialog(
      title: approved ? '通过退单' : '驳回退单',
      fallbackReason: approved ? '审核通过' : '审核不通过',
    );
    if (remark == null) return;
    await operate(
      order,
      'audit-refund',
      body: {
        'approved': approved,
        'auditRemark': remark,
        if (!approved && order.refundRollbackStatus != null)
          'rollbackStatus': order.refundRollbackStatus,
      },
    );
  }

  Future<void> _reviewOrder(PetOrder order) async {
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _ReviewDialog(),
    );
    if (payload == null) return;
    await operate(order, 'review', body: payload);
  }

  Future<String?> _showReasonDialog({
    required String title,
    required String fallbackReason,
  }) async {
    final controller = TextEditingController(text: fallbackReason);
    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(labelText: '原因 / 备注'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed:
                    () => Navigator.pop(
                      context,
                      controller.text.trim().isEmpty
                          ? fallbackReason
                          : controller.text.trim(),
                    ),
                child: const Text('确认'),
              ),
            ],
          ),
    );
    controller.dispose();
    return result;
  }

  void showError(Object error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.toString())));
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.isAdmin,
    required this.onOperate,
    required this.onReview,
    required this.onReasonedAction,
    required this.onRefundAudit,
  });

  final PetOrder order;
  final bool isAdmin;
  final Future<void> Function(
    PetOrder order,
    String action, {
    Map<String, dynamic> body,
  })
  onOperate;
  final Future<void> Function(PetOrder order) onReview;
  final Future<void> Function(
    PetOrder order,
    String action,
    String title,
    String fallbackReason,
  )
  onReasonedAction;
  final Future<void> Function(PetOrder order, bool approved) onRefundAudit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.orderNo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Chip(
                  label: Text('${order.status} ${order.statusName}'),
                  backgroundColor: _statusColor(
                    order.status,
                  ).withValues(alpha: 0.16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '应付 ¥${order.payAmount.toStringAsFixed(2)}，优惠 ¥${order.discountAmount.toStringAsFixed(2)}',
            ),
            if (order.addressDetail.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '收货信息：${order.receiver} ${order.phone} / ${order.addressDetail}',
              ),
            ],
            if (order.paymentNo.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('支付流水：${order.paymentNo}'),
            ],
            if (order.rewardPoints > 0)
              Text(
                '奖励积分：${order.rewardPoints}，冲正：${order.pointsReversed ? '是' : '否'}',
              ),
            const SizedBox(height: 8),
            ...order.items.map(
              (item) => Text(
                '${item.productName} x ${item.quantity} = ¥${item.subtotal.toStringAsFixed(2)}',
              ),
            ),
            if (order.refundReason.isNotEmpty ||
                order.auditRemark.isNotEmpty ||
                order.inventoryRestored) ...[
              const Divider(height: 22),
              if (order.refundReason.isNotEmpty)
                Text('退单原因：${order.refundReason}'),
              if (order.refundAuditStatus.isNotEmpty)
                Text('审核状态：${order.refundAuditStatus}'),
              if (order.auditRemark.isNotEmpty)
                Text('审核备注：${order.auditRemark}'),
              Text(
                '库存回补：${order.inventoryRestored ? '已回补' : '未回补'}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            const Divider(height: 22),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed:
                      order.status == 0 ? () => onOperate(order, 'pay') : null,
                  child: const Text('支付'),
                ),
                FilledButton.tonal(
                  onPressed:
                      isAdmin && order.status == 1
                          ? () => onOperate(order, 'ship')
                          : null,
                  child: const Text('发货'),
                ),
                FilledButton.tonal(
                  onPressed:
                      order.status == 2
                          ? () => onOperate(order, 'receive')
                          : null,
                  child: const Text('收货'),
                ),
                FilledButton.tonal(
                  onPressed: order.status == 3 ? () => onReview(order) : null,
                  child: const Text('评价'),
                ),
                OutlinedButton(
                  onPressed:
                      [0, 1].contains(order.status)
                          ? () => onReasonedAction(
                            order,
                            'cancel',
                            '取消订单',
                            '用户主动取消',
                          )
                          : null,
                  child: const Text('取消'),
                ),
                OutlinedButton(
                  onPressed:
                      [2, 3].contains(order.status)
                          ? () => onReasonedAction(
                            order,
                            'apply-refund',
                            '申请退单',
                            '商品不符合预期，申请退单',
                          )
                          : null,
                  child: const Text('申请退单'),
                ),
                OutlinedButton(
                  onPressed:
                      isAdmin && order.status == -2
                          ? () => onRefundAudit(order, true)
                          : null,
                  child: const Text('退单通过'),
                ),
                OutlinedButton(
                  onPressed:
                      isAdmin && order.status == -2
                          ? () => onRefundAudit(order, false)
                          : null,
                  child: const Text('退单驳回'),
                ),
              ],
            ),
            if (order.statusLogs.isNotEmpty) ...[
              const Divider(height: 22),
              const Text('状态日志', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              ...order.statusLogs.map(
                (log) => Text(
                  '${log.fromStatus ?? '-'} -> ${log.toStatus} ${log.toStatusName} / ${log.operatorRole} / ${log.reason}',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(int status) {
    if (status == 0) return Colors.orange;
    if (status == 1 || status == 2) return Colors.blue;
    if (status == 3 || status == 4) return Colors.green;
    return Colors.red;
  }
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog();

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  int rating = 5;
  final contentCtrl = TextEditingController(text: '商品状态良好，服务流程完整。');

  @override
  void dispose() {
    contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('订单评价'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              initialValue: rating,
              decoration: const InputDecoration(labelText: '评分'),
              items: const [
                DropdownMenuItem(value: 5, child: Text('5 分')),
                DropdownMenuItem(value: 4, child: Text('4 分')),
                DropdownMenuItem(value: 3, child: Text('3 分')),
                DropdownMenuItem(value: 2, child: Text('2 分')),
                DropdownMenuItem(value: 1, child: Text('1 分')),
              ],
              onChanged: (value) => setState(() => rating = value ?? rating),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: contentCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: '评价内容'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed:
              () => Navigator.pop(context, {
                'rating': rating,
                'content':
                    contentCtrl.text.trim().isEmpty
                        ? '默认好评'
                        : contentCtrl.text.trim(),
              }),
          child: const Text('提交'),
        ),
      ],
    );
  }
}
