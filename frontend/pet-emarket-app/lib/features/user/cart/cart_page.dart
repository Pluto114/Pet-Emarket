import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/cart_item.dart';
import '../../../models/shipping_address.dart';

class CartPage extends StatefulWidget {
  const CartPage({required this.apiClient, super.key});
  final ApiClient apiClient;

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool loading = true;
  String? errorText;
  List<CartItem> items = [];
  List<ShippingAddress> addresses = [];
  ShippingAddress? selectedAddress;

  double get total => items.fold(0, (sum, item) => sum + item.subtotal);

  bool get canCreateOrder => items.isNotEmpty && selectedAddress != null;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final wide = w > 800;

    return Scaffold(
      backgroundColor: PawmartColors.surfaceBg,
      appBar: AppBar(
        title: const Text('购物车'),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: canCreateOrder ? createOrder : null,
              child: Text(
                '提交并支付',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color:
                      canCreateOrder
                          ? PawmartColors.primary500
                          : PawmartColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: EdgeInsets.fromLTRB(wide ? 40 : 16, 16, wide ? 40 : 16, 100),
          children: [
            if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: CircularProgressIndicator(),
                ),
              ),
            if (errorText != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  errorText!,
                  style: TextStyle(color: PawmartColors.error, fontSize: 13),
                ),
              ),
            if (!loading) ...[
              // Address Section
              _AddressSection(
                addresses: addresses,
                selectedAddress: selectedAddress,
                onSelected:
                    (address) => setState(() => selectedAddress = address),
                onAdd: () => showAddressDialog(),
                onEdit: (address) => showAddressDialog(address: address),
                onDefault: setDefaultAddress,
                onDelete: deleteAddress,
              ),
              const SizedBox(height: 16),

              // Cart Items
              if (items.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: PawmartColors.surfaceCard,
                    borderRadius: BorderRadius.circular(pawmartRadiusMd),
                    boxShadow: pawmartShadow1,
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 48,
                          color: PawmartColors.neutral300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '购物车为空',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: PawmartColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '先去逛逛，添加喜欢的商品吧',
                          style: TextStyle(
                            fontSize: 13,
                            color: PawmartColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CartItemCard(
                    item: item,
                    onIncrease: () => updateQuantity(item, item.quantity + 1),
                    onDecrease:
                        () =>
                            item.quantity > 1
                                ? updateQuantity(item, item.quantity - 1)
                                : null,
                    onDelete: () => deleteItem(item),
                  ),
                ),
              ),
              if (items.isNotEmpty) ...[
                const SizedBox(height: 8),
                // Total Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: PawmartColors.surfaceCard,
                    borderRadius: BorderRadius.circular(pawmartRadiusMd),
                    boxShadow: pawmartShadow1,
                  ),
                  child: Row(
                    children: [
                      Text(
                        '合计',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: PawmartColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '¥${total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: PawmartColors.primary500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (items.isNotEmpty && selectedAddress == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '请先新增并选择收货地址。',
                    style: TextStyle(fontSize: 13, color: PawmartColors.error),
                  ),
                ),
            ],
          ],
        ),
      ),
      // Sticky bottom bar when has items
      bottomNavigationBar:
          items.isNotEmpty
              ? Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                decoration: BoxDecoration(
                  color: PawmartColors.surfaceCard,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF36322E).withAlpha(15),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '合计',
                              style: TextStyle(
                                fontSize: 12,
                                color: PawmartColors.textSecondary,
                              ),
                            ),
                            Text(
                              '¥${total.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: PawmartColors.primary500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: canCreateOrder ? createOrder : null,
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                canCreateOrder
                                    ? PawmartColors.accent400
                                    : PawmartColors.neutral200,
                            foregroundColor:
                                canCreateOrder
                                    ? PawmartColors.textOnAccent
                                    : PawmartColors.neutral400,
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                          ),
                          child: Text(
                            '提交并支付',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : null,
    );
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      errorText = null;
    });
    try {
      final nextItems = await widget.apiClient.listCartItems();
      final nextAddresses = await widget.apiClient.listAddresses();
      final defaultAddress =
          nextAddresses.isNotEmpty && nextAddresses[0].defaultAddress
              ? nextAddresses[0]
              : null;
      final previousSelectedId = selectedAddress?.id;
      final previousSelected =
          nextAddresses.where((a) => a.id == previousSelectedId).firstOrNull;
      items = nextItems;
      addresses = nextAddresses;
      selectedAddress =
          previousSelected ??
          defaultAddress ??
          (nextAddresses.isEmpty ? null : nextAddresses.first);
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

  Future<void> showAddressDialog({ShippingAddress? address}) async {
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddressDialog(address: address),
    );
    if (payload == null) return;
    try {
      if (address == null) {
        final created = await widget.apiClient.createAddress(payload);
        selectedAddress = created;
      } else {
        selectedAddress = await widget.apiClient.updateAddress(
          address.id,
          payload,
        );
      }
      await load();
    } catch (error) {
      if (mounted) showError(error);
    }
  }

  Future<void> setDefaultAddress(ShippingAddress address) async {
    try {
      selectedAddress = await widget.apiClient.setDefaultAddress(address.id);
      await load();
    } catch (error) {
      if (mounted) showError(error);
    }
  }

  Future<void> deleteAddress(ShippingAddress address) async {
    try {
      await widget.apiClient.deleteAddress(address.id);
      if (selectedAddress?.id == address.id) selectedAddress = null;
      await load();
    } catch (error) {
      if (mounted) showError(error);
    }
  }

  Future<void> createOrder() async {
    final address = selectedAddress;
    if (address == null) {
      showError('请先选择收货地址');
      return;
    }
    try {
      final order = await widget.apiClient.createOrderFromCartAndPay(
        addressId: address.id,
      );
      await load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('订单 ${order.orderNo} 已支付')));
      }
    } catch (error) {
      if (mounted) showError(error);
    }
  }

  void showError(Object error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.toString())));
  }
}

// ═══════════════════════════════════════════
// Cart Item Card
// ═══════════════════════════════════════════
class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onDelete,
  });
  final CartItem item;
  final VoidCallback onIncrease;
  final VoidCallback? onDecrease;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PawmartColors.surfaceCard,
        borderRadius: BorderRadius.circular(pawmartRadiusMd),
        boxShadow: pawmartShadow1,
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: PawmartColors.primary50,
              borderRadius: BorderRadius.circular(pawmartRadiusMd),
            ),
            child: Icon(
              product.isLivePet ? Icons.pets : Icons.shopping_bag_outlined,
              color: PawmartColors.primary500,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: PawmartColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '¥${product.price.toStringAsFixed(2)} x ${item.quantity}',
                  style: TextStyle(
                    fontSize: 12,
                    color: PawmartColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '小计：¥${item.subtotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: PawmartColors.primary500,
                  ),
                ),
              ],
            ),
          ),
          // Quantity Controls
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(pawmartRadiusMd),
              border: Border.all(color: PawmartColors.neutral200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 16),
                  onPressed: onDecrease,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                Text(
                  '${item.quantity}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: PawmartColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  onPressed: onIncrease,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          // Delete
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: onDelete,
            color: PawmartColors.error.withAlpha(180),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Address Section
// ═══════════════════════════════════════════
class _AddressSection extends StatelessWidget {
  const _AddressSection({
    required this.addresses,
    required this.selectedAddress,
    required this.onSelected,
    required this.onAdd,
    required this.onEdit,
    required this.onDefault,
    required this.onDelete,
  });

  final List<ShippingAddress> addresses;
  final ShippingAddress? selectedAddress;
  final ValueChanged<ShippingAddress> onSelected;
  final VoidCallback onAdd;
  final ValueChanged<ShippingAddress> onEdit;
  final ValueChanged<ShippingAddress> onDefault;
  final ValueChanged<ShippingAddress> onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PawmartColors.surfaceCard,
        borderRadius: BorderRadius.circular(pawmartRadiusMd),
        boxShadow: pawmartShadow1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: PawmartColors.primary500,
              ),
              const SizedBox(width: 6),
              Text(
                '收货地址',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: PawmartColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_location_alt_outlined, size: 16),
                label: Text(
                  '新增',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (addresses.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '暂无收货地址，请新增后再下单。',
                style: TextStyle(
                  fontSize: 13,
                  color: PawmartColors.textSecondary,
                ),
              ),
            )
          else
            ...addresses.map(
              (address) => ListTile(
                selected: selectedAddress?.id == address.id,
                selectedTileColor: PawmartColors.primary50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(pawmartRadiusSm),
                ),
                dense: true,
                onTap: () => onSelected(address),
                leading: Icon(
                  selectedAddress?.id == address.id
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color:
                      selectedAddress?.id == address.id
                          ? PawmartColors.primary500
                          : PawmartColors.neutral400,
                ),
                title: Text(
                  '${address.receiver}  ${address.phone}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: PawmartColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  address.fullAddress,
                  style: TextStyle(
                    fontSize: 12,
                    color: PawmartColors.textSecondary,
                  ),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit(address);
                    if (value == 'default') onDefault(address);
                    if (value == 'delete') onDelete(address);
                  },
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('编辑')),
                        if (!address.defaultAddress)
                          const PopupMenuItem(
                            value: 'default',
                            child: Text('设为默认'),
                          ),
                        const PopupMenuItem(value: 'delete', child: Text('删除')),
                      ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Address Dialog
// ═══════════════════════════════════════════
class _AddressDialog extends StatefulWidget {
  const _AddressDialog({this.address});
  final ShippingAddress? address;

  @override
  State<_AddressDialog> createState() => _AddressDialogState();
}

class _AddressDialogState extends State<_AddressDialog> {
  late final receiverCtrl = TextEditingController(
    text: widget.address?.receiver ?? '',
  );
  late final phoneCtrl = TextEditingController(
    text: widget.address?.phone ?? '',
  );
  late final provinceCtrl = TextEditingController(
    text: widget.address?.province ?? '',
  );
  late final cityCtrl = TextEditingController(text: widget.address?.city ?? '');
  late final districtCtrl = TextEditingController(
    text: widget.address?.district ?? '',
  );
  late final detailCtrl = TextEditingController(
    text: widget.address?.detail ?? '',
  );
  late bool defaultAddress = widget.address?.defaultAddress ?? true;

  @override
  void dispose() {
    receiverCtrl.dispose();
    phoneCtrl.dispose();
    provinceCtrl.dispose();
    cityCtrl.dispose();
    districtCtrl.dispose();
    detailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.address == null ? '新增收货地址' : '编辑收货地址',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: receiverCtrl,
                decoration: const InputDecoration(labelText: '收货人'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: '手机号'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: provinceCtrl,
                      decoration: const InputDecoration(labelText: '省份'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: cityCtrl,
                      decoration: const InputDecoration(labelText: '城市'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: districtCtrl,
                      decoration: const InputDecoration(labelText: '区县'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: detailCtrl,
                decoration: const InputDecoration(labelText: '详细地址'),
                maxLines: 3,
              ),
              SwitchListTile(
                value: defaultAddress,
                onChanged: (value) => setState(() => defaultAddress = value),
                title: Text('设为默认地址', style: TextStyle(fontSize: 14)),
                activeColor: PawmartColors.primary500,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('取消', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        FilledButton(
          onPressed: () {
            final payload = {
              'receiver': receiverCtrl.text.trim(),
              'phone': phoneCtrl.text.trim(),
              'province': provinceCtrl.text.trim(),
              'city': cityCtrl.text.trim(),
              'district': districtCtrl.text.trim(),
              'detail': detailCtrl.text.trim(),
              'defaultAddress': defaultAddress,
            };
            Navigator.pop(context, payload);
          },
          child: Text('保存', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
