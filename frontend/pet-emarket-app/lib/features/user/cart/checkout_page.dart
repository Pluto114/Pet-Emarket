import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/session/session_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/cart_item.dart';
import '../../../models/shipping_address.dart';

/// 结算确认页 —— 购物车 → 确认订单 → 提交（待支付状态）
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({
    required this.apiClient,
    required this.sessionStore,
    required this.items,
    super.key,
  });
  final ApiClient apiClient;
  final SessionStore sessionStore;
  final List<CartItem> items;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool submitting = false;
  List<ShippingAddress> addresses = [];
  ShippingAddress? selectedAddress;
  bool loadingAddresses = true;

  double get totalAmount =>
      widget.items.fold(0.0, (sum, item) => sum + item.subtotal);

  double get memberDiscountRate => widget.sessionStore.user?.discountRate ?? 0.0;

  double get discountAmount => totalAmount * memberDiscountRate;

  double get payAmount {
    return ((totalAmount - discountAmount) * 100).floorToDouble() / 100;
  }

  @override
  void initState() {
    super.initState();
    loadAddresses();
  }

  Future<void> loadAddresses() async {
    setState(() => loadingAddresses = true);
    try {
      addresses = await widget.apiClient.listAddresses();
      final defaultAddr =
          addresses.where((a) => a.defaultAddress).firstOrNull;
      selectedAddress =
          defaultAddr ??
          (addresses.isNotEmpty ? addresses.first : null);
    } catch (_) {
      addresses = [];
    }
    if (mounted) setState(() => loadingAddresses = false);
  }

  Future<void> submitOrder() async {
    if (selectedAddress == null) {
      _snack('请先选择收货地址');
      return;
    }
    setState(() => submitting = true);
    try {
      final order = await widget.apiClient.createOrderFromCart(
        addressId: selectedAddress!.id,
        cartItemIds: widget.items.map((item) => item.id).toList(),
      );
      if (mounted) {
        _snack('订单 ${order.orderNo} 已生成，状态：待支付');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _snack(e.toString());
        setState(() => submitting = false);
      }
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 800;
    final levelLabel = widget.sessionStore.user?.memberLevelLabel ?? '普通会员';

    return Scaffold(
      backgroundColor: PawmartColors.surfaceBg,
      appBar: AppBar(
        title: const Text('确认订单'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          wide ? 40 : 16, 16, wide ? 40 : 16, 100,
        ),
        children: [
          // 收货地址
          _section(Icons.location_on_outlined, '收货地址',
            TextButton.icon(
              onPressed: submitting ? null : () => _showAddressDialog(),
              icon: const Icon(Icons.add_location_alt_outlined, size: 16),
              label: const Text('新增'),
            ),
          ),
          const SizedBox(height: 8),
          if (loadingAddresses)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (addresses.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  const Text('暂无收货地址，请先新增'),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _showAddressDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('新增地址'),
                  ),
                ]),
              ),
            )
          else
            ...addresses.map(_buildAddressTile),

          const SizedBox(height: 20),

          // 商品清单
          _section(Icons.shopping_bag_outlined, '商品清单', null),
          const SizedBox(height: 8),
          ...widget.items.map(_buildItemCard),

          const SizedBox(height: 20),

          // 会员等级
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PawmartColors.surfaceCard,
              borderRadius: BorderRadius.circular(pawmartRadiusMd),
              boxShadow: pawmartShadow1,
            ),
            child: Row(children: [
              Icon(Icons.card_membership,
                  color: PawmartColors.primary500),
              const SizedBox(width: 10),
              Text(
                '$levelLabel  ·  ${(memberDiscountRate * 100).toStringAsFixed(1)}% 折扣',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: PawmartColors.primary500,
                    fontSize: 14),
              ),
            ]),
          ),

          const SizedBox(height: 24),

          // 金额明细
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: PawmartColors.surfaceCard,
              borderRadius: BorderRadius.circular(pawmartRadiusMd),
              boxShadow: pawmartShadow1,
            ),
            child: Column(children: [
              _amountRow('商品总额', '¥${totalAmount.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              _amountRow('会员折扣',
                  '-¥${discountAmount.toStringAsFixed(2)}',
                  valueColor: Colors.red),
              const Divider(height: 20),
              _amountRow('应付金额', '¥${payAmount.toStringAsFixed(2)}',
                  labelBold: true, valueSize: 20),
            ]),
          ),
          const SizedBox(height: 8),
          Text('提交后订单进入待支付状态，可在订单列表完成支付。',
              style: TextStyle(
                  fontSize: 12, color: PawmartColors.textSecondary)),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: PawmartColors.surfaceCard,
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF36322E).withAlpha(15),
                blurRadius: 10,
                offset: const Offset(0, -2))
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(children: [
            Expanded(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('应付',
                        style: TextStyle(
                            fontSize: 12,
                            color: PawmartColors.textSecondary)),
                    Text('¥${payAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: PawmartColors.accent400)),
                  ]),
            ),
            const SizedBox(width: 16),
            SizedBox(
              height: 48,
              width: 180,
              child: FilledButton(
                onPressed: submitting || selectedAddress == null
                    ? null
                    : submitOrder,
                style: FilledButton.styleFrom(
                  backgroundColor: PawmartColors.accent400,
                  foregroundColor: PawmartColors.textOnAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('确认下单',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildAddressTile(ShippingAddress addr) {
    final selected = selectedAddress?.id == addr.id;
    return Card(
      color: selected ? PawmartColors.primary50 : null,
      child: ListTile(
        leading: Icon(
            selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: selected
                ? PawmartColors.primary500
                : PawmartColors.neutral400),
        title: Text('${addr.receiver}  ${addr.phone}',
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(addr.fullAddress,
            style: TextStyle(
                fontSize: 12, color: PawmartColors.textSecondary)),
        trailing: addr.defaultAddress
            ? Chip(
                label: const Text('默认',
                    style: TextStyle(fontSize: 11)),
                backgroundColor: PawmartColors.primary50,
                side: BorderSide.none,
                padding: EdgeInsets.zero,
                materialTapTargetSize:
                    MaterialTapTargetSize.shrinkWrap)
            : null,
        onTap: submitting
            ? null
            : () => setState(() => selectedAddress = addr),
      ),
    );
  }

  Widget _buildItemCard(CartItem item) {
    final product = item.product;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: PawmartColors.primary50,
                borderRadius: BorderRadius.circular(10)),
            child: Icon(
                product.isLivePet
                    ? Icons.pets
                    : Icons.shopping_bag_outlined,
                color: PawmartColors.primary500),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                      '¥${product.price.toStringAsFixed(2)} x ${item.quantity}',
                      style: TextStyle(
                          fontSize: 12,
                          color: PawmartColors.textSecondary)),
                ]),
          ),
          Text('¥${item.subtotal.toStringAsFixed(2)}',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: PawmartColors.primary500)),
        ]),
      ),
    );
  }

  Widget _section(IconData icon, String title, Widget? action) {
    return Row(children: [
      Icon(icon, size: 18, color: PawmartColors.primary500),
      const SizedBox(width: 6),
      Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: PawmartColors.textPrimary)),
      const Spacer(),
      if (action != null) action,
    ]);
  }

  Widget _amountRow(String label, String value,
      {bool labelBold = false, Color? valueColor, double? valueSize}) {
    return Row(children: [
      Text(label,
          style: TextStyle(
              fontSize: labelBold ? 15 : 13,
              fontWeight:
                  labelBold ? FontWeight.w700 : FontWeight.w400,
              color: PawmartColors.textSecondary)),
      const Spacer(),
      Text(value,
          style: TextStyle(
              fontSize: valueSize ?? 15,
              fontWeight: FontWeight.w800,
              color: valueColor ?? PawmartColors.textPrimary)),
    ]);
  }

  Future<void> _showAddressDialog() async {
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => const _AddressDialog(),
    );
    if (payload == null) return;
    try {
      final created = await widget.apiClient.createAddress(payload);
      await loadAddresses();
      setState(() => selectedAddress = created);
    } catch (e) {
      if (mounted) _snack(e.toString());
    }
  }
}

class _AddressDialog extends StatefulWidget {
  const _AddressDialog();
  @override
  State<_AddressDialog> createState() => _AddressDialogState();
}

class _AddressDialogState extends State<_AddressDialog> {
  final _r = TextEditingController();
  final _p = TextEditingController();
  final _pr = TextEditingController();
  final _c = TextEditingController();
  final _d = TextEditingController();
  final _dt = TextEditingController();
  bool _def = true;

  @override
  void dispose() {
    _r.dispose();
    _p.dispose();
    _pr.dispose();
    _c.dispose();
    _d.dispose();
    _dt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新增收货地址'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
            TextField(
                controller: _r,
                decoration:
                    const InputDecoration(labelText: '收货人 *')),
            const SizedBox(height: 10),
            TextField(
                controller: _p,
                decoration:
                    const InputDecoration(labelText: '手机号 *'),
                keyboardType: TextInputType.phone),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: _pr,
                      decoration: const InputDecoration(
                          labelText: '省份'))),
              const SizedBox(width: 8),
              Expanded(
                  child: TextField(
                      controller: _c,
                      decoration: const InputDecoration(
                          labelText: '城市'))),
              const SizedBox(width: 8),
              Expanded(
                  child: TextField(
                      controller: _d,
                      decoration: const InputDecoration(
                          labelText: '区县'))),
            ]),
            const SizedBox(height: 10),
            TextField(
                controller: _dt,
                decoration:
                    const InputDecoration(labelText: '详细地址 *'),
                maxLines: 3),
            SwitchListTile(
                value: _def,
                onChanged: (v) => setState(() => _def = v),
                title: const Text('设为默认地址',
                    style: TextStyle(fontSize: 14)),
                activeColor: PawmartColors.primary500,
                contentPadding: EdgeInsets.zero),
          ]),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消')),
        FilledButton(
            onPressed: () {
              if (_r.text.trim().isEmpty ||
                  _p.text.trim().isEmpty ||
                  _dt.text.trim().isEmpty) return;
              Navigator.pop(context, {
                'receiver': _r.text.trim(),
                'phone': _p.text.trim(),
                'province': _pr.text.trim(),
                'city': _c.text.trim(),
                'district': _d.text.trim(),
                'detail': _dt.text.trim(),
                'defaultAddress': _def,
              });
            },
            child: const Text('保存')),
      ],
    );
  }
}
