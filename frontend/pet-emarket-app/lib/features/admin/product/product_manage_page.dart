import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/session/session_store.dart';
import '../../../models/product.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/toast.dart';

class ProductManagePage extends StatefulWidget {
  const ProductManagePage({required this.apiClient, required this.sessionStore, super.key});
  final ApiClient apiClient;
  final SessionStore sessionStore;

  @override
  State<ProductManagePage> createState() => _ProductManagePageState();
}

class _ProductManagePageState extends State<ProductManagePage> {
  bool loading = true;
  String? errorText;
  List<Product> products = [];
  final keywordCtrl = TextEditingController();

  @override
  void initState() { super.initState(); load(); }
  @override
  void dispose() { keywordCtrl.dispose(); super.dispose(); }

  Future<void> load() async {
    setState(() { loading = true; errorText = null; });
    try {
      products = await widget.apiClient.listProducts(keyword: keywordCtrl.text);
    } catch (e) { errorText = e.toString(); }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Row(children: [
            Expanded(child: Text('商品管理', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700))),
            FilledButton.icon(onPressed: () => _showDialog(), icon: const Icon(Icons.add), label: const Text('添加商品')),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: keywordCtrl, decoration: const InputDecoration(labelText: '搜索', prefixIcon: Icon(Icons.search), isDense: true), onSubmitted: (_) => load())),
            const SizedBox(width: 8),
            IconButton(onPressed: load, icon: const Icon(Icons.search)),
          ]),
          const SizedBox(height: 12),
          if (loading) const Center(child: Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator())),
          if (errorText != null) Text(errorText!, style: TextStyle(color: theme.colorScheme.error)),
          if (!loading && errorText == null)
            ...products.map((p) => Card(
              child: ListTile(
                leading: Icon(p.isLivePet ? Icons.pets : Icons.shopping_bag, color: theme.colorScheme.primary),
                title: Text(p.name),
                subtitle: Text('${p.type} | ${p.category} | ¥${p.price.toStringAsFixed(2)} | 库存${p.stock}'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.edit), onPressed: () => _showDialog(product: p)),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(p)),
                ]),
              ),
            )),
        ]),
      ),
    );
  }

  Future<void> _showDialog({Product? product}) async {
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (ctx) => _ProductDialog(product: product));
    if (result == null) return;
    try {
      if (product == null) {
        await widget.apiClient.createProduct(result);
      } else {
        await widget.apiClient.updateProduct(product.id, result);
      }
      await load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
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
  @override State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  late final nameCtrl = TextEditingController(text: widget.product?.name ?? '');
  late final catCtrl = TextEditingController(text: widget.product?.category ?? '');
  late final priceCtrl = TextEditingController(text: widget.product?.price.toString() ?? '');
  late final stockCtrl = TextEditingController(text: widget.product?.stock.toString() ?? '');
  late final descCtrl = TextEditingController(text: widget.product?.description ?? '');
  late final petCodeCtrl = TextEditingController(text: widget.product?.livePet?['petCode']?.toString() ?? '');
  late final healthCtrl = TextEditingController(text: widget.product?.livePet?['healthStatus']?.toString() ?? '');
  late final vaccineCtrl = TextEditingController(text: widget.product?.livePet?['vaccineCertNo']?.toString() ?? '');
  late final quarantineCtrl = TextEditingController(text: widget.product?.livePet?['quarantineCertNo']?.toString() ?? '');
  String type = 'GOODS';
  String status = 'ON_SALE';

  @override
  void initState() {
    super.initState();
    type = widget.product?.type ?? 'GOODS';
    status = widget.product?.status ?? 'ON_SALE';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? '添加商品' : '编辑商品'),
      content: SizedBox(width: 500, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '商品名称')),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(labelText: '类型'), items: const [DropdownMenuItem(value: 'GOODS', child: Text('周边商品')), DropdownMenuItem(value: 'PET_LIVE', child: Text('活体宠物'))], onChanged: (v) => setState(() => type = v ?? type))),
          const SizedBox(width: 10),
          Expanded(child: DropdownButtonFormField<String>(value: status, decoration: const InputDecoration(labelText: '状态'), items: const [DropdownMenuItem(value: 'DRAFT', child: Text('草稿')), DropdownMenuItem(value: 'ON_SALE', child: Text('在售')), DropdownMenuItem(value: 'OFF_SALE', child: Text('下架'))], onChanged: (v) => setState(() => status = v ?? status))),
        ]),
        const SizedBox(height: 10),
        TextField(controller: catCtrl, decoration: const InputDecoration(labelText: '分类')),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: '价格'), keyboardType: TextInputType.number)),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: stockCtrl, decoration: const InputDecoration(labelText: '库存'), keyboardType: TextInputType.number)),
        ]),
        const SizedBox(height: 10),
        TextField(controller: descCtrl, decoration: const InputDecoration(labelText: '描述'), maxLines: 2),
        if (type == 'PET_LIVE') ...[
          const Divider(height: 24), const Text('活体宠物档案', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(controller: petCodeCtrl, decoration: const InputDecoration(labelText: '宠物编号')),
          const SizedBox(height: 8),
          TextField(controller: healthCtrl, decoration: const InputDecoration(labelText: '健康状态')),
          const SizedBox(height: 8),
          TextField(controller: vaccineCtrl, decoration: const InputDecoration(labelText: '疫苗证明编号')),
          const SizedBox(height: 8),
          TextField(controller: quarantineCtrl, decoration: const InputDecoration(labelText: '检疫证明编号')),
        ],
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(onPressed: () {
          final payload = {
            'name': nameCtrl.text.trim(),
            'type': type, 'category': catCtrl.text.trim().isEmpty ? 'General' : catCtrl.text.trim(),
            'price': double.tryParse(priceCtrl.text) ?? 0,
            'stock': int.tryParse(stockCtrl.text) ?? 0,
            'status': status, 'description': descCtrl.text.trim(),
            if (type == 'PET_LIVE') 'petCode': petCodeCtrl.text.trim(),
            if (type == 'PET_LIVE') 'healthStatus': healthCtrl.text.trim(),
            if (type == 'PET_LIVE') 'vaccineCertNo': vaccineCtrl.text.trim(),
            if (type == 'PET_LIVE') 'quarantineCertNo': quarantineCtrl.text.trim(),
          };
          Navigator.pop(context, payload);
        }, child: const Text('保存')),
      ],
    );
  }
}

