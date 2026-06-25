import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/session/session_store.dart';
import '../../models/product.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({
    required this.apiClient,
    required this.sessionStore,
    super.key,
  });

  final ApiClient apiClient;
  final SessionStore sessionStore;

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final keywordController = TextEditingController();
  bool loading = true;
  String? errorText;
  List<Product> products = [];

  bool get canManage {
    final role = widget.sessionStore.user?.role;
    return role == 'ADMIN' || role == 'MERCHANT';
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    keywordController.dispose();
    super.dispose();
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
                const Expanded(
                  child: Text('商品管理', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                ),
                FilledButton.icon(
                  onPressed: canManage ? () => showProductDialog() : null,
                  icon: const Icon(Icons.add_business),
                  label: const Text('新增商品'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: keywordController,
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: '按商品名、分类、描述搜索'),
                    onSubmitted: (_) => load(),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  tooltip: '搜索',
                  onPressed: load,
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (loading) const Center(child: Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator())),
            if (errorText != null) Text(errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            if (!loading && errorText == null)
              ...products.map(
                (product) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(product.isLivePet ? Icons.pets : Icons.shopping_bag_outlined),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(product.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                              ),
                              Text('¥${product.price.toStringAsFixed(2)}'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(label: Text(product.type)),
                              Chip(label: Text(product.category)),
                              Chip(label: Text('库存 ${product.stock}')),
                              Chip(label: Text(product.status)),
                            ],
                          ),
                          if (product.description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(product.description),
                          ],
                          if (product.livePet != null) ...[
                            const SizedBox(height: 8),
                            Text('检疫证：${product.livePet?['quarantineCertNo'] ?? '-'}    疫苗证：${product.livePet?['vaccineCertNo'] ?? '-'}'),
                          ],
                          if (canManage) ...[
                            const Divider(height: 22),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: product.stock > 0 ? () => addToCart(product) : null,
                                  icon: const Icon(Icons.add_shopping_cart),
                                  label: const Text('加入购物车'),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => showProductDialog(product: product),
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('编辑'),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => deleteProduct(product),
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('删除'),
                                ),
                              ],
                            ),
                          ],
                          if (!canManage) ...[
                            const Divider(height: 22),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton.icon(
                                onPressed: product.stock > 0 ? () => addToCart(product) : null,
                                icon: const Icon(Icons.add_shopping_cart),
                                label: const Text('加入购物车'),
                              ),
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
      products = await widget.apiClient.listProducts(keyword: keywordController.text);
    } catch (error) {
      errorText = error.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> showProductDialog({Product? product}) async {
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ProductDialog(product: product),
    );
    if (payload == null) return;
    try {
      if (product == null) {
        await widget.apiClient.createProduct(payload);
      } else {
        await widget.apiClient.updateProduct(product.id, payload);
      }
      await load();
    } catch (error) {
      if (mounted) showError(error);
    }
  }

  Future<void> deleteProduct(Product product) async {
    try {
      await widget.apiClient.deleteProduct(product.id);
      await load();
    } catch (error) {
      if (mounted) showError(error);
    }
  }

  Future<void> addToCart(Product product) async {
    try {
      await widget.apiClient.addCartItem(productId: product.id, quantity: 1);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${product.name} 已加入购物车')));
      }
    } catch (error) {
      if (mounted) showError(error);
    }
  }

  void showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
  }
}

class _ProductDialog extends StatefulWidget {
  const _ProductDialog({this.product});

  final Product? product;

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  late final TextEditingController name;
  late final TextEditingController category;
  late final TextEditingController price;
  late final TextEditingController stock;
  late final TextEditingController description;
  late final TextEditingController petCode;
  late final TextEditingController healthStatus;
  late final TextEditingController vaccineCertNo;
  late final TextEditingController quarantineCertNo;
  String type = 'GOODS';
  String status = 'ON_SALE';

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    name = TextEditingController(text: product?.name ?? '');
    category = TextEditingController(text: product?.category ?? '');
    price = TextEditingController(text: product?.price.toString() ?? '');
    stock = TextEditingController(text: product?.stock.toString() ?? '');
    description = TextEditingController(text: product?.description ?? '');
    petCode = TextEditingController(text: product?.livePet?['petCode']?.toString() ?? '');
    healthStatus = TextEditingController(text: product?.livePet?['healthStatus']?.toString() ?? '');
    vaccineCertNo = TextEditingController(text: product?.livePet?['vaccineCertNo']?.toString() ?? '');
    quarantineCertNo = TextEditingController(text: product?.livePet?['quarantineCertNo']?.toString() ?? '');
    type = product?.type ?? 'GOODS';
    status = product?.status ?? 'ON_SALE';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? '新增商品' : '编辑商品'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: '商品名称')),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(labelText: '商品类型'),
                      items: const [
                        DropdownMenuItem(value: 'GOODS', child: Text('周边商品')),
                        DropdownMenuItem(value: 'PET_LIVE', child: Text('活体宠物')),
                      ],
                      onChanged: (value) => setState(() => type = value ?? type),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(labelText: '状态'),
                      items: const ['DRAFT', 'ON_SALE', 'OFF_SALE'].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
                      onChanged: (value) => setState(() => status = value ?? status),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(controller: category, decoration: const InputDecoration(labelText: '分类')),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextField(controller: price, decoration: const InputDecoration(labelText: '价格'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: stock, decoration: const InputDecoration(labelText: '库存'), keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 10),
              TextField(controller: description, decoration: const InputDecoration(labelText: '描述'), maxLines: 3),
              if (type == 'PET_LIVE') ...[
                const SizedBox(height: 14),
                TextField(controller: petCode, decoration: const InputDecoration(labelText: '宠物唯一编号')),
                const SizedBox(height: 10),
                TextField(controller: healthStatus, decoration: const InputDecoration(labelText: '健康状态')),
                const SizedBox(height: 10),
                TextField(controller: vaccineCertNo, decoration: const InputDecoration(labelText: '疫苗证明编号')),
                const SizedBox(height: 10),
                TextField(controller: quarantineCertNo, decoration: const InputDecoration(labelText: '检疫证明编号')),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
          onPressed: () {
            final payload = {
              'name': name.text.trim(),
              'type': type,
              'category': category.text.trim().isEmpty ? 'General' : category.text.trim(),
              'price': double.tryParse(price.text) ?? 0,
              'stock': int.tryParse(stock.text) ?? 0,
              'status': status,
              'description': description.text.trim(),
              if (type == 'PET_LIVE') 'petCode': petCode.text.trim(),
              if (type == 'PET_LIVE') 'healthStatus': healthStatus.text.trim(),
              if (type == 'PET_LIVE') 'vaccineCertNo': vaccineCertNo.text.trim(),
              if (type == 'PET_LIVE') 'quarantineCertNo': quarantineCertNo.text.trim(),
            };
            Navigator.pop(context, payload);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
