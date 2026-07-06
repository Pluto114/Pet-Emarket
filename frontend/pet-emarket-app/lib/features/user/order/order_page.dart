import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/session/session_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/order.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({required this.apiClient, required this.sessionStore, super.key});
  final ApiClient apiClient;
  final SessionStore sessionStore;
  @override
  State<OrderPage> createState() => OrderPageState();
}

class OrderPageState extends State<OrderPage> {
  bool loading = true;
  String? errorText;
  List<PetOrder> _allOrders = [];
  int _activeTab = 0;
  static const _tabs = ['全部', '待付款', '待发货', '运输中', '已完成'];

  List<PetOrder> get _filteredOrders {
    if (_activeTab == 0) return _allOrders;
    if (_activeTab == 4) return _allOrders.where((o) => o.status >= 3).toList();
    final s = _activeTab - 1; // 1→0, 2→1, 3→2
    return _allOrders.where((o) => o.status == s).toList();
  }
  int _count(int status) {
    if (status == 4) return _allOrders.where((o) => o.status >= 3).length;
    return _allOrders.where((o) => o.status == status).length;
  }
  bool get isAdmin => widget.sessionStore.user?.role == 'ADMIN';
  bool get isMerchant => widget.sessionStore.user?.role == 'MERCHANT';

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    setState(() { loading = true; errorText = null; });
    try { _allOrders = await widget.apiClient.listOrders(); }
    catch (e) { errorText = e.toString(); }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final wide = w > 900;
    return Scaffold(
      backgroundColor: PawmartColors.surfaceBg,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorText != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(errorText!, style: TextStyle(color: PawmartColors.error)),
                  const SizedBox(height: 8),
                  OutlinedButton(onPressed: load, child: const Text('重试')),
                ]))
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(wide ? 32 : 16, 20, wide ? 32 : 16, 40),
                    children: [_header(), const SizedBox(height: 16), _stats(), const SizedBox(height: 20), _tabBar(), const SizedBox(height: 16),
                      if (wide) _wideLayout() else _narrowLayout()],
                  ),
                ),
    );
  }

  Widget _header() => Row(children: [
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('我的订单', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: PawmartColors.textPrimary)),
      Text('共 ${_allOrders.length} 个订单', style: TextStyle(fontSize: 14, color: PawmartColors.textSecondary)),
    ]),
    const Spacer(),
    IconButton.filledTonal(onPressed: load, icon: const Icon(Icons.refresh, size: 20)),
  ]);

  Widget _stats() => Row(children: [
    _statCard('待付款', _count(0), Icons.schedule_outlined, const Color(0xFFE8BF20), const Color(0xFFFDF7D5)),
    const SizedBox(width: 10),
    _statCard('待发货', _count(1), Icons.inventory_2_outlined, const Color(0xFF388EDC), const Color(0xFFDCEBFB)),
    const SizedBox(width: 10),
    _statCard('待收货', _count(2), Icons.local_shipping_outlined, PawmartColors.accent400, const Color(0xFFFDFEF0)),
  ]);

  Widget _statCard(String label, int count, IconData icon, Color fg, Color bg) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: fg.withAlpha(25), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: fg)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: fg)),
          Text(label, style: TextStyle(fontSize: 12, color: fg.withAlpha(200))),
        ]),
      ]),
    ),
  );

  Widget _tabBar() {
    final counts = [_allOrders.length, _count(0), _count(1), _count(2), _count(4)];
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(
      children: List.generate(5, (i) {
        final active = i == _activeTab;
        return Padding(padding: const EdgeInsets.only(right: 6), child: Material(
          color: active ? PawmartColors.primary50 : Colors.transparent, borderRadius: BorderRadius.circular(10),
          child: InkWell(onTap: () => setState(() => _activeTab = i), borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: active ? PawmartColors.primary500 : Colors.transparent, width: 3))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_tabs[i], style: TextStyle(fontSize: 14, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? PawmartColors.primary500 : PawmartColors.textSecondary)),
                const SizedBox(width: 6),
                Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: active ? PawmartColors.primary100 : PawmartColors.neutral100, borderRadius: BorderRadius.circular(10)),
                    child: Text('${counts[i]}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: active ? PawmartColors.primary700 : PawmartColors.textSecondary))),
              ]),
            ),
          ),
        ));
      }),
    ));
  }

  Widget _wideLayout() => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Expanded(flex: 3, child: _orderList()),
    const SizedBox(width: 24),
    SizedBox(width: 250, child: _sidebar()),
  ]);
  Widget _narrowLayout() => Column(children: [_orderList(), const SizedBox(height: 20), _sidebar()]);

  Widget _orderList() {
    final orders = _filteredOrders;
    if (orders.isEmpty) return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(color: PawmartColors.surfaceCard, borderRadius: BorderRadius.circular(16), boxShadow: pawmartShadow1),
      child: Center(child: Column(children: [
        Icon(Icons.receipt_long_outlined, size: 48, color: PawmartColors.neutral300),
        const SizedBox(height: 12),
        Text(_activeTab == 0 ? '暂无订单' : '暂无${_tabs[_activeTab]}订单', style: TextStyle(fontSize: 15, color: PawmartColors.textSecondary)),
      ])),
    );
    return Column(children: orders.map((o) => Padding(padding: const EdgeInsets.only(bottom: 12),
      child: OrderCard(order: o, isAdmin: isAdmin, isMerchant: isMerchant,
        currentUserId: widget.sessionStore.user?.id ?? '',
        onOperate: (String a, {Map<String, dynamic>? body}) => operate(o, a, body: body ?? {}),
        onReview: () => _reviewOrder(o),
        onReasonedAction: (a, t, r) => _reasonedAction(o, a, t, r),
        onRefundAudit: (ap) => _auditRefund(o, ap),
        onPay: () => _showPayment(o),
        onViewReview: () => _showReviewInfo(o),
      ))).toList());
  }

  Widget _sidebar() {
    final total = _allOrders.fold(0.0, (s, o) => s + o.payAmount);
    final pending = _allOrders.where((o) => o.status == 3).length;
    final logs = <_Log>[];
    for (final o in _allOrders) { for (final l in o.statusLogs) { logs.add(_Log(l.reason, l.createdAt, l.toStatus)); } }
    logs.sort((a, b) => b.time.compareTo(a.time));
    return Column(children: [
      Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: PawmartColors.surfaceCard, borderRadius: BorderRadius.circular(14), boxShadow: pawmartShadow1),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('订单概览', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: PawmartColors.textPrimary)),
          const SizedBox(height: 14), _sideRow('总订单数', '${_allOrders.length}'),
          const SizedBox(height: 10), _sideRow('累计消费', '¥${total.toStringAsFixed(0)}', vc: PawmartColors.primary500),
          const SizedBox(height: 10), _sideRow('待评价', '$pending'),
        ])),
      const SizedBox(height: 16),
      Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: PawmartColors.surfaceCard, borderRadius: BorderRadius.circular(14), boxShadow: pawmartShadow1),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('最近动态', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: PawmartColors.textPrimary)),
          const SizedBox(height: 12),
          if (logs.isEmpty) Text('暂无动态', style: TextStyle(fontSize: 13, color: PawmartColors.textSecondary))
          else ...logs.take(5).map((l) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 5, right: 10), decoration: BoxDecoration(color: _dot(l.status), shape: BoxShape.circle)),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.desc, style: TextStyle(fontSize: 12, color: PawmartColors.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
              Text(_ago(l.time), style: TextStyle(fontSize: 11, color: PawmartColors.textSecondary)),
            ])),
          ]))),
        ])),
    ]);
  }
  Widget _sideRow(String l, String v, {Color? vc}) => Row(children: [Text(l, style: TextStyle(fontSize: 13, color: PawmartColors.textSecondary)), const Spacer(), Text(v, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: vc ?? PawmartColors.textPrimary))]);
  Color _dot(int s) { if (s == 0) return const Color(0xFFE8BF20); if (s <= 2) return const Color(0xFF388EDC); if (s >= 3) return const Color(0xFF3F9E53); return PawmartColors.error; }
  String _ago(String t) { try { final d = DateTime.parse(t); final diff = DateTime.now().difference(d); if (diff.inHours < 1) return '${diff.inMinutes}分钟前'; if (diff.inDays < 1) return '${diff.inHours}小时前'; if (diff.inDays < 7) return '${diff.inDays}天前'; return '${d.month}/${d.day}'; } catch (_) { return ''; } }

  Future<void> operate(PetOrder o, String action, {Map<String, dynamic> body = const {}}) async {
    try { await widget.apiClient.operateOrder(o.id, action, body: body); await load(); }
    catch (e) { if (mounted) showError(e); }
  }
  Future<void> _reasonedAction(PetOrder o, String action, String title, String reason) async {
    final r = await _reasonDialog(title, reason); if (r == null) return;
    await operate(o, action, body: {'reason': r});
  }
  Future<void> _auditRefund(PetOrder o, bool approved) async {
    final r = await _reasonDialog(approved ? '通过退单' : '驳回退单', approved ? '审核通过' : '审核不通过'); if (r == null) return;
    await operate(o, 'audit-refund', body: {'approved': approved, 'auditRemark': r, if (!approved && o.refundRollbackStatus != null) 'rollbackStatus': o.refundRollbackStatus});
  }
  Future<void> _reviewOrder(PetOrder o) async {
    final p = await showDialog<Map<String, dynamic>>(context: context, builder: (_) => ReviewDialog(order: o));
    if (p == null) return; await operate(o, 'review', body: p);
  }
  void _showPayment(PetOrder o) => showDialog(context: context, builder: (_) => PaymentDialog(order: o, onPay: () { Navigator.pop(context); operate(o, 'pay'); }));
  void _showReviewInfo(PetOrder o) => showDialog(context: context, builder: (_) => AlertDialog(
    title: const Text('我的评价'), content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: List.generate(5, (i) => Icon(i < o.reviewRating! ? Icons.star : Icons.star_border, color: const Color(0xFFE8BF20), size: 28))),
      const SizedBox(height: 12), Text(o.reviewContent, style: TextStyle(fontSize: 14, color: PawmartColors.textPrimary)),
    ]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭'))]));
  Future<String?> _reasonDialog(String title, String fallback) async {
    final c = TextEditingController(text: fallback);
    final r = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: Text(title), content: TextField(controller: c, maxLines: 3, decoration: const InputDecoration(labelText: '原因 / 备注')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')), FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim().isEmpty ? fallback : c.text.trim()), child: const Text('确认'))]));
    c.dispose(); return r;
  }
  void showError(Object e) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
}

class OrderCard extends StatelessWidget {
  const OrderCard({required this.order, required this.isAdmin, required this.isMerchant,
    required this.onOperate, required this.onReview, required this.onReasonedAction, required this.onRefundAudit,
    this.onPay, this.onViewReview, required this.currentUserId, super.key});
  final PetOrder order;
  final bool isAdmin, isMerchant;
  final String currentUserId;
  final Future<void> Function(String, {Map<String, dynamic> body}) onOperate;
  final Future<void> Function() onReview;
  final Future<void> Function(String, String, String) onReasonedAction;
  final Future<void> Function(bool) onRefundAudit;
  final VoidCallback? onPay;
  final VoidCallback? onViewReview;

  (Color, Color) _sc() => switch (order.status) {
    0 => (const Color(0xFFE8BF20), const Color(0xFFFDF7D5)),
    1 => (const Color(0xFF388EDC), const Color(0xFFDCEBFB)),
    2 => (PawmartColors.accent400, const Color(0xFFFDFEF0)),
    3 || 4 => (const Color(0xFF3F9E53), const Color(0xFFDCF5DF)),
    _ => (PawmartColors.error, const Color(0xFFFDE0E0)),
  };

  @override
  Widget build(BuildContext context) {
    final (sc, sbg) = _sc();
    final cnt = order.items.fold<int>(0, (s, i) => s + i.quantity);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: PawmartColors.surfaceCard, borderRadius: BorderRadius.circular(16), boxShadow: pawmartShadow1),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: PawmartColors.primary50, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.store_outlined, size: 16, color: PawmartColors.primary500)),
          const SizedBox(width: 10),
          const Expanded(child: Text('PawMart', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: PawmartColors.textPrimary))),
          Text(order.orderNo, style: TextStyle(fontSize: 12, color: PawmartColors.textSecondary)),
          const SizedBox(width: 10),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: sbg, borderRadius: BorderRadius.circular(6)),
              child: Text(order.statusName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sc))),
        ]),
        const SizedBox(height: 14),
        ...order.items.map((item) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [
          Container(width: 64, height: 64, decoration: BoxDecoration(color: PawmartColors.primary50, borderRadius: BorderRadius.circular(10)),
              child: Center(child: Icon(item.productType == 'PET_LIVE' ? Icons.pets : Icons.shopping_bag_outlined, size: 24, color: PawmartColors.primary300))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.productName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: PawmartColors.textPrimary)),
            const SizedBox(height: 4),
            Text('¥${item.unitPrice.toStringAsFixed(2)} x${item.quantity}', style: TextStyle(fontSize: 12, color: PawmartColors.textSecondary)),
          ])),
          Text('¥${item.subtotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: PawmartColors.textPrimary)),
        ]))),
        if (order.status < 0) _refund(),
        Container(height: 1, color: PawmartColors.neutral100, margin: const EdgeInsets.symmetric(vertical: 12)),
        Row(children: [
          Text('共$cnt件，合计：', style: TextStyle(fontSize: 13, color: PawmartColors.textSecondary)),
          Text('¥${order.payAmount.toStringAsFixed(0)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: PawmartColors.primary500)),
          const Spacer(), ..._actions(),
        ]),
      ]),
    );
  }

  Widget _refund() {
    final label = switch (order.refundAuditStatus) {
      'PENDING' => '商家审核中', 'APPROVED' => '已通过', 'REJECTED' => '已驳回',
      'DIRECT_REFUND' => '管理员直接退单', 'ESCALATED_TO_ADMIN' => '已升级至管理员裁定',
      _ => order.refundAuditStatus,
    };
    return Container(
      margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.orange.withAlpha(12), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.orange.withAlpha(40))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.info_outline, size: 14, color: Colors.orange), const SizedBox(width: 6), Text('退单详情', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.orange.shade800))]),
        const SizedBox(height: 6),
        if (order.refundReason.isNotEmpty) Text('原因：${order.refundReason}', style: TextStyle(fontSize: 12, color: PawmartColors.textSecondary)),
        Text('审核状态：$label', style: TextStyle(fontSize: 12, color: PawmartColors.textSecondary)),
      ]),
    );
  }

  List<Widget> _actions() {
    final s = order.status;
    final btns = <Widget>[];
    void btn(String label, VoidCallback fn, {bool primary = false, bool danger = false}) {
      final w = SizedBox(height: 34, child: primary
          ? FilledButton(onPressed: fn, style: FilledButton.styleFrom(backgroundColor: PawmartColors.accent400, foregroundColor: PawmartColors.textOnAccent, padding: const EdgeInsets.symmetric(horizontal: 14), minimumSize: const Size(0, 34), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)), child: Text(label))
          : OutlinedButton(onPressed: fn, style: OutlinedButton.styleFrom(foregroundColor: danger ? PawmartColors.error : PawmartColors.textPrimary, padding: const EdgeInsets.symmetric(horizontal: 14), minimumSize: const Size(0, 34), side: BorderSide(color: danger ? PawmartColors.error.withAlpha(100) : PawmartColors.neutral200), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), textStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: danger ? PawmartColors.error : null)), child: Text(label)));
      btns.add(w); btns.add(const SizedBox(width: 8));
    }
    if (s == 0) { btn('取消订单', () => onReasonedAction('cancel', '取消订单', '用户主动取消'), danger: true); btn('去支付', () { if (onPay != null) { onPay!(); } else { onOperate('pay'); } }, primary: true); }
    final isOwnOrder = order.userId == currentUserId;
    if ((isAdmin || isMerchant) && s == 1 && !isOwnOrder) btn('确认发货', () => onOperate('ship'), primary: true);
    if (s == 2) btn('确认收货', () => onOperate('receive'), primary: true);
    if (s == 3) btn('去评价', () => onReview(), primary: true);
    if (s == 4 && order.reviewRating != null && order.reviewRating! > 0) btn('查看评价', () => onViewReview?.call());
    if (s == 4) btn('再次购买', () {});
    if ([2, 3].contains(s)) btn('申请退单', () => onReasonedAction('apply-refund', '申请退单', '商品不符合预期'), danger: true);
    if (isMerchant && s == -2 && order.refundAuditStatus == 'PENDING') { btn('升级管理员', () => onReasonedAction('escalate-refund', '升级管理员', '商家不同意')); btn('同意退单', () => onRefundAudit(true), primary: true); }
    if (isAdmin && s == -2) { btn('驳回退单', () => onRefundAudit(false), danger: true); btn('通过退单', () => onRefundAudit(true), primary: true); }
    if (btns.isNotEmpty) btns.removeLast();
    return btns;
  }
}

class ReviewDialog extends StatefulWidget {
  final PetOrder order;
  const ReviewDialog({required this.order, super.key});
  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}
class _ReviewDialogState extends State<ReviewDialog> {
  int rating = 5;
  final ctrl = TextEditingController(text: '商品状态良好，服务流程完整。');
  @override
  void dispose() { ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('订单评价'),
    content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (widget.order.items.isNotEmpty) Container(
        padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: PawmartColors.neutral50, borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: PawmartColors.primary50, borderRadius: BorderRadius.circular(8)), child: Icon(widget.order.items.first.productType == 'PET_LIVE' ? Icons.pets : Icons.shopping_bag_outlined, color: PawmartColors.primary300)),
          const SizedBox(width: 12),
          Expanded(child: Text(widget.order.items.first.productName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: PawmartColors.textPrimary))),
        ]),
      ),
      const Text('评分', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => IconButton(
        icon: Icon(i < rating ? Icons.star : Icons.star_border, size: 36, color: const Color(0xFFE8BF20)),
        onPressed: () => setState(() => rating = i + 1),
      ))),
      const SizedBox(height: 16),
      TextField(controller: ctrl, maxLines: 3, decoration: const InputDecoration(labelText: '评价内容', hintText: '分享你和宠物的使用体验…')),
    ])),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')), FilledButton(onPressed: () => Navigator.pop(context, {'rating': rating, 'content': ctrl.text.trim().isEmpty ? '默认好评' : ctrl.text.trim()}), child: const Text('提交评价'))],
  );
}

class PaymentDialog extends StatelessWidget {
  final PetOrder order;
  final VoidCallback onPay;
  const PaymentDialog({required this.order, required this.onPay, super.key});

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('确认支付'),
    content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Order summary
      Container(
        padding: const EdgeInsets.all(14), margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: PawmartColors.neutral50, borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          if (order.items.isNotEmpty) Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: PawmartColors.primary50, borderRadius: BorderRadius.circular(8)), child: Icon(order.items.first.productType == 'PET_LIVE' ? Icons.pets : Icons.shopping_bag_outlined, color: PawmartColors.primary300, size: 20)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(order.items.first.productName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: PawmartColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('共${order.items.fold<int>(0, (s, i) => s + i.quantity)}件商品', style: TextStyle(fontSize: 12, color: PawmartColors.textSecondary)),
            ])),
          ]),
          const SizedBox(height: 10), const Divider(),
          Row(children: [const Text('支付金额', style: TextStyle(fontSize: 14)), const Spacer(), Text('¥${order.payAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: PawmartColors.primary500))]),
        ]),
      ),
      // Payment methods
      const Text('支付方式', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 10),
      _payMethod(context, Icons.phone_android, '微信支付', true),
      const SizedBox(height: 8),
      _payMethod(context, Icons.account_balance_wallet, '支付宝', false),
      const SizedBox(height: 8),
      _payMethod(context, Icons.credit_card, '银行卡', false),
    ])),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')), FilledButton(onPressed: onPay, style: FilledButton.styleFrom(backgroundColor: PawmartColors.accent400, foregroundColor: PawmartColors.textOnAccent), child: Text('确认支付 ¥${order.payAmount.toStringAsFixed(2)}'))],
  );

  Widget _payMethod(BuildContext context, IconData icon, String name, bool selected) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(color: selected ? PawmartColors.primary50 : PawmartColors.surfaceCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: selected ? PawmartColors.primary300 : PawmartColors.neutral200)),
    child: Row(children: [
      Icon(icon, size: 20, color: selected ? PawmartColors.primary500 : PawmartColors.textSecondary),
      const SizedBox(width: 12),
      Text(name, style: TextStyle(fontSize: 14, color: selected ? PawmartColors.primary500 : PawmartColors.textPrimary)),
      const Spacer(),
      Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked, size: 20, color: selected ? PawmartColors.primary500 : PawmartColors.neutral300),
    ]),
  );
}

class _Log { final String desc, time; final int status; _Log(this.desc, this.time, this.status); }
