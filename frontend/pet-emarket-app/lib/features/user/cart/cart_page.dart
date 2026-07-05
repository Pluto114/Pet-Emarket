import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/session/session_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/cart_item.dart';
import '../../../models/shipping_address.dart';
import 'checkout_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({required this.apiClient, required this.sessionStore, super.key});
  final ApiClient apiClient;
  final SessionStore sessionStore;

  @override
  State<CartPage> createState() => CartPageState();
}

class CartPageState extends State<CartPage> {
  bool loading = true;
  String? errorText;
  List<CartItem> items = [];
  List<ShippingAddress> addresses = [];
  ShippingAddress? selectedAddress;
  final Set<String> _selectedIds = {};

  List<CartItem> get selectedItems => items.where((item) => _selectedIds.contains(item.id)).toList();
  double get total => selectedItems.fold(0, (sum, item) => sum + item.subtotal);
  double get memberDiscountRate => widget.sessionStore.user?.discountRate ?? 0.0;
  double get discountAmount => (total * memberDiscountRate * 100).floorToDouble() / 100;
  double get payAmount => ((total - discountAmount) * 100).floorToDouble() / 100;
  String get memberLevelLabel => widget.sessionStore.user?.memberLevelLabel ?? '普通会员';
  bool get canCheckout => selectedItems.isNotEmpty;
  bool get allSelected => items.isNotEmpty && _selectedIds.length == items.length;

  @override
  void initState() {
    super.initState();
    load();
  }

  void _toggleItem(String id) {
    setState(() {
      if (_selectedIds.contains(id)) _selectedIds.remove(id);
      else _selectedIds.add(id);
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (allSelected) _selectedIds.clear();
      else _selectedIds.addAll(items.map((item) => item.id));
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final wide = w > 800;

    return Scaffold(
      backgroundColor: PawmartColors.surfaceBg,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('我的购物车'),
            if (items.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                '(${items.length})',
                style: TextStyle(
                  fontSize: 16,
                  color: PawmartColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () async {
                final toDelete = _selectedIds.isNotEmpty ? selectedItems : items;
                for (final item in toDelete) {
                  await widget.apiClient.deleteCartItem(item.id);
                }
                await load();
              },
              child: Text(
                '删除',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: PawmartColors.error.withAlpha(200),
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

              if (items.isEmpty)
                _emptyCart()
              else if (wide)
                _wideLayout()
              else
                _narrowLayout(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emptyCart() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: PawmartColors.surfaceCard,
        borderRadius: BorderRadius.circular(pawmartRadiusLg),
        boxShadow: pawmartShadow1,
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: PawmartColors.neutral100,
                borderRadius: BorderRadius.circular(pawmartRadiusFull),
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 36,
                color: PawmartColors.neutral300,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '购物车空空如也',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: PawmartColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '快去挑选心仪的宠物好物吧',
              style: TextStyle(
                fontSize: 14,
                color: PawmartColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Wide layout: two-column (items + order summary)
  Widget _wideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children:
                items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CartItemCard(
                    item: item,
                    selected: _selectedIds.contains(item.id),
                    onToggleSelect: () => _toggleItem(item.id),
                    onIncrease: () => updateQuantity(item, item.quantity + 1),
                    onDecrease: () => item.quantity > 1
                        ? updateQuantity(item, item.quantity - 1)
                        : null,
                    onDelete: () => deleteItem(item),
                  ),
                )).toList(),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 2,
          child: _buildOrderSummary(),
        ),
      ],
    );
  }

  Widget _narrowLayout() {
    return Column(
      children: [
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _CartItemCard(
              item: item,
              selected: _selectedIds.contains(item.id),
              onToggleSelect: () => _toggleItem(item.id),
              onIncrease: () => updateQuantity(item, item.quantity + 1),
              onDecrease: () => item.quantity > 1
                  ? updateQuantity(item, item.quantity - 1)
                  : null,
              onDelete: () => deleteItem(item),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildOrderSummary(),
      ],
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PawmartColors.surfaceCard,
        borderRadius: BorderRadius.circular(pawmartRadiusLg),
        boxShadow: pawmartShadow1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '订单摘要',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: PawmartColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Select all
          Row(children: [
            SizedBox(width: 20, height: 20, child: Checkbox(value: allSelected, onChanged: (v) { if (v != null) _toggleSelectAll(); }, activeColor: PawmartColors.primary500, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)),
            const SizedBox(width: 8),
            Text('全选', style: TextStyle(fontSize: 14, color: PawmartColors.textPrimary)),
            const Spacer(),
            Text('已选 ${selectedItems.length} 件', style: TextStyle(fontSize: 13, color: PawmartColors.textSecondary)),
          ]),
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 12),
          _summaryRow('商品总价', '¥${total.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          if (memberDiscountRate > 0) ...[
            _summaryRow('$memberLevelLabel折扣', '-¥${discountAmount.toStringAsFixed(2)}', valueColor: Colors.red),
            const SizedBox(height: 4),
          ],
          _summaryRow('运费', '免运费', valueColor: PawmartColors.success),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '应付总额',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: PawmartColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '¥${payAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: PawmartColors.primary500,
                ),
              ),
            ],
          ),
          if (selectedAddress == null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PawmartColors.error.withAlpha(15),
                borderRadius: BorderRadius.circular(pawmartRadiusSm),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 16, color: PawmartColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '请先新增并选择收货地址',
                      style: TextStyle(fontSize: 12, color: PawmartColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: canCheckout ? goToCheckout : null,
              style: FilledButton.styleFrom(
                backgroundColor: canCheckout
                    ? PawmartColors.accent400
                    : PawmartColors.neutral200,
                foregroundColor: canCheckout
                    ? PawmartColors.textOnAccent
                    : PawmartColors.neutral400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(pawmartRadiusMd),
                ),
              ),
              child: Text(
                '去结算',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: PawmartColors.textSecondary),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? PawmartColors.textPrimary,
          ),
        ),
      ],
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
      _selectedIds.addAll(nextItems.map((item) => item.id));
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
    if (quantity > item.product.stock) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.product.name} 库存仅剩 ${item.product.stock} 件'),
            backgroundColor: const Color(0xFFE8BF20),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
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

  Future<void> goToCheckout() async {
    if (selectedItems.isEmpty) return;
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutPage(
          apiClient: widget.apiClient,
          sessionStore: widget.apiClient.sessionStore,
          items: selectedItems,
        ),
      ),
    );
    if (created == true) {
      await load();
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
    required this.selected,
    required this.onToggleSelect,
    required this.onIncrease,
    required this.onDecrease,
    required this.onDelete,
  });
  final CartItem item;
  final bool selected;
  final VoidCallback onToggleSelect;
  final VoidCallback onIncrease;
  final VoidCallback? onDecrease;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final stock = product.stock;
    final isLowStock = stock > 0 && stock <= 5;
    final isOos = stock <= 0;
    final atLimit = item.quantity >= stock;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PawmartColors.surfaceCard,
        borderRadius: BorderRadius.circular(pawmartRadiusMd),
        boxShadow: pawmartShadow1,
        border: Border.all(color: isLowStock ? const Color(0xFFE8BF20).withAlpha(80) : PawmartColors.neutral200),
      ),
      child: Row(
        children: [
          // Checkbox
          SizedBox(
            width: 24, height: 24,
            child: Checkbox(
              value: selected,
              onChanged: (v) { if (v != null) onToggleSelect(); },
              activeColor: PawmartColors.primary500,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          // Product Image
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: PawmartColors.neutral100,
              borderRadius: BorderRadius.circular(pawmartRadiusSm),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(pawmartRadiusSm),
              child: product.coverUrl.isNotEmpty
                  ? Image.network(
                      product.coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _productIcon(product),
                    )
                  : _productIcon(product),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: PawmartColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      product.category.isNotEmpty ? product.category : '通用',
                      style: TextStyle(fontSize: 12, color: PawmartColors.textSecondary),
                    ),
                    const Spacer(),
                    if (isLowStock)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8BF20).withAlpha(30),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '库存仅剩 $stock',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFFCCA218)),
                        ),
                      ),
                    if (isOos)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: PawmartColors.error.withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '已售罄',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: PawmartColors.error),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '¥${product.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: PawmartColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    // Quantity Controls
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(pawmartRadiusSm),
                        border: Border.all(color: PawmartColors.neutral200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: onDecrease,
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(pawmartRadiusSm),
                            ),
                            child: Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              child: Icon(Icons.remove, size: 16, color: PawmartColors.textSecondary),
                            ),
                          ),
                          Container(
                            width: 36,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(color: PawmartColors.neutral200),
                                right: BorderSide(color: PawmartColors.neutral200),
                              ),
                            ),
                            child: Text(
                              '${item.quantity}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: atLimit ? PawmartColors.error : PawmartColors.textPrimary,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: atLimit ? null : onIncrease,
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(pawmartRadiusSm),
                            ),
                            child: Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              child: Icon(Icons.add, size: 16, color: atLimit ? PawmartColors.neutral300 : PawmartColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '¥${item.subtotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: PawmartColors.primary500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Delete
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: onDelete,
            color: PawmartColors.error.withAlpha(180),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Widget _productIcon(dynamic product) {
    return Center(
      child: Icon(
        product.isLivePet ? Icons.pets : Icons.shopping_bag_outlined,
        size: 24,
        color: PawmartColors.neutral400,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PawmartColors.surfaceCard,
        borderRadius: BorderRadius.circular(pawmartRadiusMd),
        boxShadow: pawmartShadow1,
        border: Border.all(color: PawmartColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: PawmartColors.primary50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: PawmartColors.primary500,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '收货地址',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: PawmartColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_location_alt_outlined, size: 16),
                label: Text(
                  '新增地址',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (addresses.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
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
              (address) => Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selectedAddress?.id == address.id
                      ? PawmartColors.primary50
                      : PawmartColors.neutral50,
                  borderRadius: BorderRadius.circular(pawmartRadiusSm),
                  border: Border.all(
                    color: selectedAddress?.id == address.id
                        ? PawmartColors.primary200
                        : Colors.transparent,
                  ),
                ),
                child: InkWell(
                  onTap: () => onSelected(address),
                  borderRadius: BorderRadius.circular(pawmartRadiusSm),
                  child: Row(
                    children: [
                      Icon(
                        selectedAddress?.id == address.id
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 20,
                        color: selectedAddress?.id == address.id
                            ? PawmartColors.primary500
                            : PawmartColors.neutral400,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${address.receiver}  ${address.phone}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: PawmartColors.textPrimary,
                                  ),
                                ),
                                if (address.defaultAddress) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: PawmartColors.primary500,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '默认',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              address.fullAddress,
                              style: TextStyle(
                                fontSize: 12,
                                color: PawmartColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') onEdit(address);
                          if (value == 'default') onDefault(address);
                          if (value == 'delete') onDelete(address);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('编辑')),
                          if (!address.defaultAddress)
                            const PopupMenuItem(value: 'default', child: Text('设为默认')),
                          const PopupMenuItem(value: 'delete', child: Text('删除')),
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
