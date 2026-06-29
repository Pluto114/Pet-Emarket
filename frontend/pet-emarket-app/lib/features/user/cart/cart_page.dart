import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
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

  ShippingAddress? firstAddressWhere(
    List<ShippingAddress> source,
    bool Function(ShippingAddress address) test,
  ) {
    for (final address in source) {
      if (test(address)) return address;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    load();
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
                    '购物车',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                ),
                FilledButton.icon(
                  onPressed: canCreateOrder ? createOrder : null,
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('生成订单'),
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
            if (!loading) ...[
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
              const SizedBox(height: 12),
              if (items.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('购物车为空。先到商品页加入商品，再回来生成订单。'),
                  ),
                ),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      leading: Icon(
                        item.product.isLivePet
                            ? Icons.pets
                            : Icons.shopping_bag_outlined,
                      ),
                      title: Text(item.product.name),
                      subtitle: Text(
                        '¥${item.product.price.toStringAsFixed(2)} x ${item.quantity} = ¥${item.subtotal.toStringAsFixed(2)}',
                      ),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: '减少',
                            onPressed:
                                item.quantity <= 1
                                    ? null
                                    : () =>
                                        updateQuantity(item, item.quantity - 1),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          IconButton(
                            tooltip: '增加',
                            onPressed:
                                () => updateQuantity(item, item.quantity + 1),
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
              if (items.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '合计',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          '¥${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (items.isNotEmpty && selectedAddress == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '请先新增并选择收货地址。',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
            ],
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
      final nextItems = await widget.apiClient.listCartItems();
      final nextAddresses = await widget.apiClient.listAddresses();
      final defaultAddress = firstAddressWhere(
        nextAddresses,
        (address) => address.defaultAddress,
      );
      final previousSelectedId = selectedAddress?.id;
      final previousSelected = firstAddressWhere(
        nextAddresses,
        (address) => address.id == previousSelectedId,
      );
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
      if (selectedAddress?.id == address.id) {
        selectedAddress = null;
      }
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
      final order = await widget.apiClient.createOrderFromCart(
        addressId: address.id,
      );
      await load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('订单 ${order.orderNo} 已创建')));
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '收货地址',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text('新增'),
                ),
              ],
            ),
            if (addresses.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('暂无收货地址，请新增后再下单。'),
              )
            else
              ...addresses.map(
                (address) => ListTile(
                  selected: selectedAddress?.id == address.id,
                  onTap: () => onSelected(address),
                  leading: Icon(
                    selectedAddress?.id == address.id
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  title: Text('${address.receiver}  ${address.phone}'),
                  subtitle: Text(address.fullAddress),
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
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('删除'),
                          ),
                        ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

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
      title: Text(widget.address == null ? '新增收货地址' : '编辑收货地址'),
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
                title: const Text('设为默认地址'),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
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
          child: const Text('保存'),
        ),
      ],
    );
  }
}
