import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/session/session_store.dart';
import '../../../core/theme/app_theme.dart';
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
  State<OrderPage> createState() => OrderPageState();
}

class OrderPageState extends State<OrderPage> {
  bool loading = true;
  String? errorText;
  List<PetOrder> orders = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  bool get isAdmin => widget.sessionStore.user?.role == 'ADMIN';
  bool get isMerchant => widget.sessionStore.user?.role == 'MERCHANT';
  bool get isManager => isAdmin || isMerchant;

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
                    isMerchant: isMerchant,
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
    required this.isMerchant,
    required this.onOperate,
    required this.onReview,
    required this.onReasonedAction,
    required this.onRefundAudit,
  });

  final PetOrder order;
  final bool isAdmin;
  final bool isMerchant;
  final Future<void> Function(PetOrder, String, {Map<String, dynamic> body}) onOperate;
  final Future<void> Function(PetOrder) onReview;
  final Future<void> Function(PetOrder, String, String, String) onReasonedAction;
  final Future<void> Function(PetOrder, bool) onRefundAudit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRefund = order.status < 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -- 订单号 + 状态 --
            Row(children: [
              Expanded(
                child: Text(order.orderNo,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              _StatusBadge(status: order.status, label: order.statusName),
            ]),
            const SizedBox(height: 10),

            // -- 状态进度条（正向订单）--
            if (!isRefund) ...[
              _StatusProgressBar(status: order.status),
              const SizedBox(height: 12),
            ],

            // -- 支付倒计时（待支付订单）--
            if (order.isUnpaid && order.deadlineDateTime != null)
              _PaymentCountdown(deadline: order.deadlineDateTime!),

            // -- 信息 --
            Text('应付 ¥${order.payAmount.toStringAsFixed(2)}，优惠 ¥${order.discountAmount.toStringAsFixed(2)}'),
            if (order.addressDetail.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('收货：${order.receiver} ${order.phone}', style: theme.textTheme.bodySmall),
              Text(order.addressDetail, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
            if (order.paymentNo.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('支付流水：${order.paymentNo}', style: theme.textTheme.bodySmall),
            ],
            if (order.rewardPoints > 0)
              Text('积分：+${order.rewardPoints}${order.pointsReversed ? '（已冲正）' : ''}',
                  style: theme.textTheme.bodySmall),

            const SizedBox(height: 8),
            ...order.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(children: [
                Icon(item.productType == 'PET_LIVE' ? Icons.pets : Icons.shopping_bag, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(child: Text(item.productName, style: theme.textTheme.bodySmall)),
                Text('x${item.quantity}  ¥${item.subtotal.toStringAsFixed(2)}',
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
              ]),
            )),

            // -- 退单信息 --
            if (isRefund) ...[
              const Divider(height: 22),
              _refundInfo(theme),
            ],

            // -- 操作按钮 --
            const Divider(height: 22),
            _actionButtons(context),

            // -- 状态日志 --
            if (order.statusLogs.isNotEmpty) ...[
              const Divider(height: 22),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('状态日志', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                children: order.statusLogs.map((log) => Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 8),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${log.fromStatus ?? '-'} → ${log.toStatus}  ',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _statusColor(log.toStatus))),
                    Expanded(child: Text('${log.toStatusName} · ${log.reason}',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant))),
                    Text(log.operatorRole, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                  ]),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _refundInfo(ThemeData theme) {
    final auditLabel = switch (order.refundAuditStatus) {
      'PENDING' => '商家审核中',
      'APPROVED' => '已通过',
      'REJECTED' => '已驳回',
      'DIRECT_REFUND' => '管理员直接退单',
      'ESCALATED_TO_ADMIN' => '已升级至管理员裁定',
      _ => order.refundAuditStatus.isEmpty ? '-' : order.refundAuditStatus,
    };
    final auditColor = switch (order.refundAuditStatus) {
      'APPROVED' || 'DIRECT_REFUND' => Colors.green,
      'REJECTED' => Colors.red,
      'ESCALATED_TO_ADMIN' => Colors.purple,
      _ => Colors.orange,
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withAlpha(40)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.info_outline, size: 16, color: Colors.orange),
          const SizedBox(width: 6),
          Text('退单详情', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.orange.shade800)),
        ]),
        const SizedBox(height: 8),
        if (order.refundReason.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('原因：${order.refundReason}', style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: 4),
        Row(children: [
          Text('审核状态：', style: theme.textTheme.bodySmall),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: auditColor.withAlpha(25), borderRadius: BorderRadius.circular(6)),
            child: Text(auditLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: auditColor)),
          ),
        ]),
        if (order.auditRemark.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('审核备注：${order.auditRemark}', style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: 4),
        Text('库存回补：${order.inventoryRestored ? '已回补' : '未回补'}',
            style: theme.textTheme.bodySmall?.copyWith(
                color: order.inventoryRestored ? Colors.green : Colors.red)),
      ]),
    );
  }

  Widget _actionButtons(BuildContext context) {
    final status = order.status;
    return Wrap(spacing: 8, runSpacing: 8, children: [
      // 支付
      if (status == 0)
        FilledButton.tonal(
          onPressed: () => onOperate(order, 'pay'),
          child: const Text('立即支付'),
        ),
      // 发货(admin/merchant)
      if ((isAdmin || isMerchant) && status == 1)
        FilledButton.tonal(
          onPressed: () => onOperate(order, 'ship'),
          child: const Text('确认发货'),
        ),
      // 收货
      if (status == 2)
        FilledButton.tonal(
          onPressed: () => onOperate(order, 'receive'),
          child: const Text('确认收货'),
        ),
      // 评价
      if (status == 3)
        FilledButton.tonal(
          onPressed: () => onReview(order),
          child: const Text('去评价'),
        ),
      // 取消
      if ([0, 1].contains(status))
        OutlinedButton(
          onPressed: () => onReasonedAction(order, 'cancel', '取消订单', '用户主动取消'),
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('取消订单'),
        ),
      // 申请退单
      if ([2, 3].contains(status))
        OutlinedButton(
          onPressed: () => onReasonedAction(order, 'apply-refund', '申请退单', '商品不符合预期'),
          style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
          child: const Text('申请退单'),
        ),
      // 退单审核 — 商家：可批准或升级管理员
      if (isMerchant && status == -2 && order.refundAuditStatus == 'PENDING') ...[
        FilledButton.tonal(
          onPressed: () => onRefundAudit(order, true),
          style: FilledButton.styleFrom(foregroundColor: Colors.green),
          child: const Text('同意退单'),
        ),
        OutlinedButton(
          onPressed: () => onReasonedAction(order, 'escalate-refund', '升级管理员', '商家不同意退单，升级至管理员裁定'),
          style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
          child: const Text('升级管理员'),
        ),
      ],
      // 退单审核 — 管理员：最终裁定（含商家升级来的）
      if (isAdmin && status == -2 && (order.refundAuditStatus == 'PENDING' || order.refundAuditStatus == 'ESCALATED_TO_ADMIN')) ...[
        FilledButton.tonal(
          onPressed: () => onRefundAudit(order, true),
          style: FilledButton.styleFrom(foregroundColor: Colors.green),
          child: const Text('通过退单'),
        ),
        OutlinedButton(
          onPressed: () => onRefundAudit(order, false),
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('驳回退单'),
        ),
      ],
    ]);
  }

  Color _statusColor(int status) {
    if (status == 0) return Colors.orange;
    if (status == 1 || status == 2) return Colors.blue;
    if (status >= 3 && status <= 4) return Colors.green;
    return Colors.red;
  }
}

// ========================================
// Status Badge
// ========================================
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.label});
  final int status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      0 => Colors.orange,
      1 || 2 => Colors.blue,
      3 || 4 => Colors.green,
      _ => Colors.red,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('$label', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ========================================
// Status Progress Bar
// ========================================
class _StatusProgressBar extends StatelessWidget {
  const _StatusProgressBar({required this.status});
  final int status;

  static const _steps = ['待支付', '待发货', '待收货', '待评价', '已完成'];

  @override
  Widget build(BuildContext context) {
    final current = status >= 4 ? 4 : (status < 0 ? 0 : status);
    final color = Theme.of(context).colorScheme;
    return SizedBox(
      height: 52,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (int i = 0; i < _steps.length; i++) ...[
          if (i > 0) Expanded(
            child: Center(
              child: Container(
                height: 3,
                color: i <= current ? Colors.green : Colors.grey.shade300,
              ),
            ),
          ),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: i <= current ? Colors.green : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: i < current
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : Text('${i + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: i <= current ? Colors.white : Colors.grey)),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 48,
              child: Text(_steps[i], textAlign: TextAlign.center, style: TextStyle(
                fontSize: 10,
                fontWeight: i <= current ? FontWeight.w600 : FontWeight.w400,
                color: i <= current ? Colors.green : Colors.grey,
              )),
            ),
          ]),
        ],
      ]),
    );
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
              value: rating,
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

// ═══════════════════════════════════════════
// Payment Countdown Timer
// ═══════════════════════════════════════════
class _PaymentCountdown extends StatefulWidget {
  const _PaymentCountdown({required this.deadline});
  final DateTime deadline;

  @override
  State<_PaymentCountdown> createState() => _PaymentCountdownState();
}

class _PaymentCountdownState extends State<_PaymentCountdown> {
  Duration _remaining = Duration.zero;
  late final StreamSubscription _sub;

  @override
  void initState() {
    super.initState();
    _tick();
    _sub = Stream.periodic(const Duration(seconds: 1)).listen((_) {
      if (mounted) _tick();
    });
  }

  void _tick() {
    final now = DateTime.now();
    if (now.isAfter(widget.deadline)) {
      if (mounted) setState(() => _remaining = Duration.zero);
      return;
    }
    setState(() => _remaining = widget.deadline.difference(now));
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  String get _text {
    if (_remaining.inSeconds <= 0) return '已超时';
    final h = _remaining.inHours;
    final m = _remaining.inMinutes.remainder(60);
    final s = _remaining.inSeconds.remainder(60);
    if (h > 0) return '剩余 ${h}时${m}分${s}秒';
    if (m > 0) return '剩余 ${m}分${s}秒';
    return '剩余 ${s}秒';
  }

  bool get _urgent => _remaining.inMinutes < 5;

  @override
  Widget build(BuildContext context) {
    final expired = _remaining.inSeconds <= 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: expired
            ? PawmartColors.error.withAlpha(20)
            : _urgent
                ? const Color(0xFFFDF7D5)
                : PawmartColors.neutral50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: expired
              ? PawmartColors.error.withAlpha(60)
              : _urgent
                  ? const Color(0xFFF6E478)
                  : PawmartColors.neutral200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            expired ? Icons.timer_off : Icons.timer_outlined,
            size: 16,
            color: expired ? PawmartColors.error : (_urgent ? const Color(0xFFCCA218) : PawmartColors.textSecondary),
          ),
          const SizedBox(width: 6),
          Text(
            _text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: expired ? PawmartColors.error : (_urgent ? const Color(0xFFCCA218) : PawmartColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
