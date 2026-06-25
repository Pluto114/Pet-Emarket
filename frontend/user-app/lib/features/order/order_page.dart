import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/session/session_store.dart';
import '../../models/order.dart';

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
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                const Expanded(child: Text('订单状态机', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700))),
                IconButton.filledTonal(onPressed: load, icon: const Icon(Icons.refresh)),
              ],
            ),
            const SizedBox(height: 12),
            if (loading) const Center(child: Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator())),
            if (errorText != null) Text(errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
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
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(order.orderNo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                              ),
                              Chip(label: Text('${order.status} ${order.statusName}')),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('应付 ¥${order.payAmount.toStringAsFixed(2)}，优惠 ¥${order.discountAmount.toStringAsFixed(2)}'),
                          const SizedBox(height: 8),
                          ...order.items.map((item) => Text('${item.productName} x ${item.quantity} = ¥${item.subtotal.toStringAsFixed(2)}')),
                          const Divider(height: 22),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton.tonal(onPressed: order.status == 0 ? () => operate(order, 'pay') : null, child: const Text('支付')),
                              FilledButton.tonal(onPressed: isAdmin && order.status == 1 ? () => operate(order, 'ship') : null, child: const Text('发货')),
                              FilledButton.tonal(onPressed: order.status == 2 ? () => operate(order, 'receive') : null, child: const Text('收货')),
                              FilledButton.tonal(
                                onPressed: order.status == 3
                                    ? () => operate(order, 'review', body: {'rating': 5, 'content': '演示评价：商品状态良好'})
                                    : null,
                                child: const Text('评价'),
                              ),
                              OutlinedButton(onPressed: [0, 1].contains(order.status) ? () => operate(order, 'cancel', body: {'reason': '用户主动取消'}) : null, child: const Text('取消')),
                              OutlinedButton(onPressed: [2, 3].contains(order.status) ? () => operate(order, 'apply-refund', body: {'reason': '演示退单申请'}) : null, child: const Text('申请退单')),
                              OutlinedButton(
                                onPressed: isAdmin && order.status == -2
                                    ? () => operate(order, 'audit-refund', body: {'approved': true, 'auditRemark': '审核通过'})
                                    : null,
                                child: const Text('审核通过'),
                              ),
                            ],
                          ),
                          if (order.statusLogs.isNotEmpty) ...[
                            const Divider(height: 22),
                            const Text('状态日志', style: TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            ...order.statusLogs.map(
                              (log) => Text('${log.fromStatus ?? '-'} -> ${log.toStatus} ${log.toStatusName} / ${log.operatorRole} / ${log.reason}'),
                            ),
                          ],
                        ],
                      ),
                    ),
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

  Future<void> operate(PetOrder order, String action, {Map<String, dynamic> body = const {}}) async {
    try {
      await widget.apiClient.operateOrder(order.id, action, body: body);
      await load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }
}
