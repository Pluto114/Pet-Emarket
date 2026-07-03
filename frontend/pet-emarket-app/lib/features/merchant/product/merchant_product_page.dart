import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/session/session_store.dart';
import '../../../models/product.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/toast.dart';

class MerchantProductPage extends StatefulWidget {
  const MerchantProductPage({
    required this.apiClient,
    required this.sessionStore,
    super.key,
  });
  final ApiClient apiClient;
  final SessionStore sessionStore;

  @override
  State<MerchantProductPage> createState() => _MerchantProductPageState();
}

class _MerchantProductPageState extends State<MerchantProductPage> {
  bool loading = true;
  String? errorText;
  List<Product> products = [];
  final keywordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    keywordCtrl.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      errorText = null;
    });
    try {
      products = await widget.apiClient.listManagedProducts(
        keyword: keywordCtrl.text,
      );
    } catch (e) {
      errorText = e.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '商品管理',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: () => _showDialog(),
                  icon: const Icon(Icons.publish),
                  label: const Text('发布商品'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(
                          Icons.storefront,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '发布后会进入真实商品库',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '填写封面图片 URL、简介、价格和库存；选择“在售”后会展示在用户首页。库存为 0 会自动下架。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: () => _showDialog(),
                      icon: const Icon(Icons.add_business),
                      label: const Text('发布新商品'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: keywordCtrl,
                  decoration: const InputDecoration(
                    labelText: '搜索商品',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onSubmitted: (_) => load(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(onPressed: load, icon: const Icon(Icons.search)),
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
          if (!loading && errorText == null && products.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.inventory_2,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant.withAlpha(100),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '暂无商品',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '点击“发布商品”填写封面、简介、库存并选择上架状态。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (!loading && errorText == null)
            ...products.map((p) => _productManageCard(p, theme)),
        ],
      ),
    );
  }

  Widget _productManageCard(Product product, ThemeData theme) {
    final soldOut = product.stock <= 0;
    final onSale = product.status == 'ON_SALE' && !soldOut;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _productThumb(product, theme),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _statusChip(soldOut ? 'SOLD_OUT' : product.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${product.type == 'PET_LIVE' ? '活体宠物' : '周边商品'} | ${product.category} | ¥${product.price.toStringAsFixed(2)} | 库存 ${product.stock}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (product.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      product.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                  if (soldOut) ...[
                    const SizedBox(height: 6),
                    Text(
                      '库存为 0，系统已按下架处理；补充库存后可重新上架。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed:
                            !onSale && !soldOut
                                ? () => _changeStatus(product, 'ON_SALE')
                                : null,
                        icon: const Icon(Icons.arrow_upward, size: 16),
                        label: const Text('上架到首页'),
                      ),
                      OutlinedButton.icon(
                        onPressed:
                            product.status != 'OFF_SALE'
                                ? () => _changeStatus(product, 'OFF_SALE')
                                : null,
                        icon: const Icon(Icons.arrow_downward, size: 16),
                        label: const Text('下架'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _showDialog(product: product),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('编辑图片/简介/库存'),
                      ),
                      TextButton.icon(
                        onPressed: () => _delete(product),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('删除'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productThumb(Product product, ThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 96,
        height: 96,
        color:
            product.isLivePet
                ? const Color(0xFF7C4DFF).withAlpha(18)
                : theme.colorScheme.primaryContainer,
        child:
            product.coverUrl.isNotEmpty
                ? Image.network(
                  product.coverUrl,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => _productFallbackIcon(product, theme),
                )
                : _productFallbackIcon(product, theme),
      ),
    );
  }

  Widget _productFallbackIcon(Product product, ThemeData theme) {
    return Icon(
      product.isLivePet ? Icons.pets : Icons.shopping_bag,
      color:
          product.isLivePet
              ? const Color(0xFF7C4DFF)
              : theme.colorScheme.primary,
      size: 30,
    );
  }

  Widget _statusChip(String status) {
    final theme = Theme.of(context);
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case 'ON_SALE':
        bg = Colors.green.withAlpha(25);
        fg = Colors.green;
        label = '在售';
        break;
      case 'DRAFT':
        bg = Colors.grey.withAlpha(25);
        fg = Colors.grey;
        label = '草稿';
        break;
      case 'OFF_SALE':
        bg = Colors.orange.withAlpha(25);
        fg = Colors.orange;
        label = '下架';
        break;
      case 'SOLD_OUT':
        bg = Colors.red.withAlpha(25);
        fg = Colors.red;
        label = '售罄下架';
        break;
      default:
        bg = theme.colorScheme.surfaceContainerHighest;
        fg = theme.colorScheme.onSurfaceVariant;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }

  Future<void> _showDialog({Product? product}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _ProductDialog(product: product),
    );
    if (result == null) return;
    try {
      if (product == null) {
        await widget.apiClient.createProduct(result);
        if (mounted) showSuccess(context, '商品已发布');
      } else {
        await widget.apiClient.updateProduct(product.id, result);
        if (mounted) showSuccess(context, '商品更新成功');
      }
      await load();
    } catch (e) {
      if (mounted) showError(context, e.toString());
    }
  }

  Future<void> _changeStatus(Product product, String status) async {
    if (status == 'ON_SALE' && product.stock <= 0) {
      showError(context, '库存为 0，补充库存后才能上架');
      return;
    }
    try {
      await widget.apiClient.updateProduct(
        product.id,
        _productPayload(product, status),
      );
      await load();
      if (mounted) {
        showSuccess(
          context,
          status == 'ON_SALE'
              ? '${product.name} 已上架到首页'
              : '${product.name} 已下架',
        );
      }
    } catch (e) {
      if (mounted) showError(context, e.toString());
    }
  }

  Map<String, dynamic> _productPayload(Product product, String status) {
    return {
      'name': product.name,
      'type': product.type,
      'category': product.category,
      'price': product.price,
      'stock': product.stock,
      'status': status,
      'description': product.description,
      'coverUrl': product.coverUrl,
      if (product.isLivePet)
        'petCode': product.livePet?['petCode']?.toString() ?? '',
      if (product.isLivePet)
        'breed': product.livePet?['breed']?.toString() ?? '',
      if (product.isLivePet)
        'healthStatus': product.livePet?['healthStatus']?.toString() ?? '',
      if (product.isLivePet)
        'vaccineCertNo': product.livePet?['vaccineCertNo']?.toString() ?? '',
      if (product.isLivePet)
        'quarantineCertNo':
            product.livePet?['quarantineCertNo']?.toString() ?? '',
      if (product.isLivePet)
        'traceSource': product.livePet?['traceSource']?.toString() ?? '',
    };
  }

  Future<void> _delete(Product p) async {
    final confirmed = await showConfirmDialog(
      context,
      title: '删除商品',
      message: '确定要删除商品 "${p.name}" 吗？此操作不可撤销。',
      confirmLabel: '删除',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await widget.apiClient.deleteProduct(p.id);
      await load();
      if (mounted) showSuccess(context, '${p.name} 已删除');
    } catch (e) {
      if (mounted) showError(context, e.toString());
    }
  }
}

class _ProductDialog extends StatefulWidget {
  final Product? product;
  const _ProductDialog({this.product});
  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  late final nameCtrl = TextEditingController(text: widget.product?.name ?? '');
  late final catCtrl = TextEditingController(
    text: widget.product?.category ?? '',
  );
  late final priceCtrl = TextEditingController(
    text: widget.product?.price.toString() ?? '',
  );
  late final stockCtrl = TextEditingController(
    text: widget.product?.stock.toString() ?? '',
  );
  late final descCtrl = TextEditingController(
    text: widget.product?.description ?? '',
  );
  late final coverUrlCtrl = TextEditingController(
    text: widget.product?.coverUrl ?? '',
  );
  late final petCodeCtrl = TextEditingController(
    text: widget.product?.livePet?['petCode']?.toString() ?? '',
  );
  late final healthCtrl = TextEditingController(
    text: widget.product?.livePet?['healthStatus']?.toString() ?? '',
  );
  late final vaccineCtrl = TextEditingController(
    text: widget.product?.livePet?['vaccineCertNo']?.toString() ?? '',
  );
  late final quarantineCtrl = TextEditingController(
    text: widget.product?.livePet?['quarantineCertNo']?.toString() ?? '',
  );
  String type = 'GOODS';
  String status = 'ON_SALE';

  @override
  void initState() {
    super.initState();
    type = widget.product?.type ?? 'GOODS';
    status = widget.product?.status ?? 'ON_SALE';
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    catCtrl.dispose();
    priceCtrl.dispose();
    stockCtrl.dispose();
    descCtrl.dispose();
    coverUrlCtrl.dispose();
    petCodeCtrl.dispose();
    healthCtrl.dispose();
    vaccineCtrl.dispose();
    quarantineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? '发布商品' : '编辑商品'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: '商品名称'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: const InputDecoration(labelText: '类型'),
                      items: const [
                        DropdownMenuItem(value: 'GOODS', child: Text('周边商品')),
                        DropdownMenuItem(
                          value: 'PET_LIVE',
                          child: Text('活体宠物'),
                        ),
                      ],
                      onChanged: (v) => setState(() => type = v ?? type),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: const InputDecoration(labelText: '状态'),
                      items: const [
                        DropdownMenuItem(value: 'ON_SALE', child: Text('立即上架')),
                        DropdownMenuItem(value: 'DRAFT', child: Text('保存草稿')),
                        DropdownMenuItem(
                          value: 'OFF_SALE',
                          child: Text('下架隐藏'),
                        ),
                      ],
                      onChanged: (v) => setState(() => status = v ?? status),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: catCtrl,
                decoration: const InputDecoration(labelText: '分类'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: priceCtrl,
                      decoration: const InputDecoration(labelText: '价格'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: stockCtrl,
                      decoration: const InputDecoration(labelText: '库存'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: '描述'),
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: coverUrlCtrl,
                decoration: const InputDecoration(labelText: '封面图片 URL'),
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '提示：库存为 0 时系统会自动下架，补库存后再选择“立即上架”。',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ),
              if (type == 'PET_LIVE') ...[
                const Divider(height: 24),
                const Text(
                  '活体宠物档案',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: petCodeCtrl,
                  decoration: const InputDecoration(labelText: '宠物编号'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: healthCtrl,
                  decoration: const InputDecoration(labelText: '健康状态'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: vaccineCtrl,
                  decoration: const InputDecoration(labelText: '疫苗证明编号'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: quarantineCtrl,
                  decoration: const InputDecoration(labelText: '检疫证明编号'),
                ),
              ],
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
            final payload = <String, dynamic>{
              'name': nameCtrl.text.trim(),
              'type': type,
              'category':
                  catCtrl.text.trim().isEmpty ? 'General' : catCtrl.text.trim(),
              'price': double.tryParse(priceCtrl.text) ?? 0,
              'stock': int.tryParse(stockCtrl.text) ?? 0,
              'status': status,
              'description': descCtrl.text.trim(),
              'coverUrl': coverUrlCtrl.text.trim(),
              if (type == 'PET_LIVE') 'petCode': petCodeCtrl.text.trim(),
              if (type == 'PET_LIVE') 'healthStatus': healthCtrl.text.trim(),
              if (type == 'PET_LIVE') 'vaccineCertNo': vaccineCtrl.text.trim(),
              if (type == 'PET_LIVE')
                'quarantineCertNo': quarantineCtrl.text.trim(),
            };
            Navigator.pop(context, payload);
          },
          child: Text(widget.product == null ? '发布商品' : '保存修改'),
        ),
      ],
    );
  }
}
