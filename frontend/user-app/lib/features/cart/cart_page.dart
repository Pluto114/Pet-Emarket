import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../models/cart_item.dart';

class CartPage extends StatefulWidget {
  const CartPage({
    required this.apiClient,
    super.key,
  });

  final ApiClient apiClient;

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool loading = true;
  String? errorText;
  List<CartItem> items = [];

  double get total => items.fold(0, (sum, item) => sum + item.subtotal);

  @override
  void initState() {
    super.initState();
    load();
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
                const Expanded(child: Text('购物车', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700))),
                FilledButton.icon(
                  onPressed: items.isEmpty ? null : createOrder,
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('生成订单'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (loading) const Center(child: Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator())),
            if (errorText != null) Text(errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            if (!loading && items.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('购物车为空。先到商品页加入商品，再回来生成订单。'),
                ),
              ),
            if (!loading)
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      leading: Icon(item.product.isLivePet ? Icons.pets : Icons.shopping_bag_outlined),
                      title: Text(item.product.name),
                      subtitle: Text('¥${item.product.price.toStringAsFixed(2)} x ${item.quantity} = ¥${item.subtotal.toStringAsFixed(2)}'),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: '减少',
                            onPressed: item.quantity <= 1 ? null : () => updateQuantity(item, item.quantity - 1),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          IconButton(
                            tooltip: '增加',
                            onPressed: () => updateQuantity(item, item.quantity + 1),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                          IconButton(
                            tooltip: '删除',
                            onPressed: () => deleteItem(item),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (!loading && items.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Expanded(child: Text('合计', style: TextStyle(fontWeight: FontWeight.w700))),
                      Text('¥${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    ],
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
      items = await widget.apiClient.listCartItems();
    } catch (error) {
      errorText = error.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> updateQuantity(CartItem item, int quantity) async {
    try {
      await widget.apiClient.updateCartItem(item.id, quantity);
      await load();
    } catch (error) {
      if (mounted) showError(error);
    }
  }

  Future<void> deleteItem(CartItem item) async {
    try {
      await widget.apiClient.deleteCartItem(item.id);
      await load();
    } catch (error) {
      if (mounted) showError(error);
    }
  }

  Future<void> createOrder() async {
    try {
      final order = await widget.apiClient.createOrderFromCart();
      await load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('订单 ${order.orderNo} 已创建')));
      }
    } catch (error) {
      if (mounted) showError(error);
    }
  }

  void showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
  }
}
