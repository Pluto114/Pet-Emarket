import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/session/session_store.dart';
import '../../../models/product.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({
    required this.apiClient,
    required this.sessionStore,
    this.filterType = '',
    super.key,
  });

  final ApiClient apiClient;
  final SessionStore sessionStore;
  final String filterType;

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
                  child: Text(
                    '商品管理',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
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
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: '按商品名、分类、描述搜索',
                    ),
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
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
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
                              Icon(
                                product.isLivePet
                                    ? Icons.pets
                                    : Icons.shopping_bag_outlined,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
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
                            Text(
                              '检疫证：${product.livePet?['quarantineCertNo'] ?? '-'}    疫苗证：${product.livePet?['vaccineCertNo'] ?? '-'}',
                            ),
                          ],
                          if (canManage) ...[
                            const Divider(height: 22),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed:
                                      product.stock > 0
                                          ? () => addToCart(product)
                                          : null,
                                  icon: const Icon(Icons.add_shopping_cart),
                                  label: const Text('加入购物车'),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed:
                                      () => showProductDialog(product: product),
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
                                onPressed:
                                    product.stock > 0
                                        ? () => addToCart(product)
                                        : null,
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
      products = await widget.apiClient.listProducts(
        keyword: keywordController.text,
        type: widget.filterType,
      );
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${product.name} 已加入购物车')));
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
    petCode = TextEditingController(
      text: product?.livePet?['petCode']?.toString() ?? '',
    );
    healthStatus = TextEditingController(
      text: product?.livePet?['healthStatus']?.toString() ?? '',
    );
    vaccineCertNo = TextEditingController(
      text: product?.livePet?['vaccineCertNo']?.toString() ?? '',
    );
    quarantineCertNo = TextEditingController(
      text: product?.livePet?['quarantineCertNo']?.toString() ?? '',
    );
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
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: '商品名称'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(labelText: '商品类型'),
                      items: const [
                        DropdownMenuItem(value: 'GOODS', child: Text('周边商品')),
                        DropdownMenuItem(
                          value: 'PET_LIVE',
                          child: Text('活体宠物'),
                        ),
                      ],
                      onChanged:
                          (value) => setState(() => type = value ?? type),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(labelText: '状态'),
                      items:
                          const ['DRAFT', 'ON_SALE', 'OFF_SALE']
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(item),
                                ),
                              )
                              .toList(),
                      onChanged:
                          (value) => setState(() => status = value ?? status),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: category,
                decoration: const InputDecoration(labelText: '分类'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: price,
                      decoration: const InputDecoration(labelText: '价格'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: stock,
                      decoration: const InputDecoration(labelText: '库存'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: description,
                decoration: const InputDecoration(labelText: '描述'),
                maxLines: 3,
              ),
              if (type == 'PET_LIVE') ...[
                const SizedBox(height: 14),
                TextField(
                  controller: petCode,
                  decoration: const InputDecoration(labelText: '宠物唯一编号'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: healthStatus,
                  decoration: const InputDecoration(labelText: '健康状态'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: vaccineCertNo,
                  decoration: const InputDecoration(labelText: '疫苗证明编号'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: quarantineCertNo,
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
            final payload = {
              'name': name.text.trim(),
              'type': type,
              'category':
                  category.text.trim().isEmpty
                      ? 'General'
                      : category.text.trim(),
              'price': double.tryParse(price.text) ?? 0,
              'stock': int.tryParse(stock.text) ?? 0,
              'status': status,
              'description': description.text.trim(),
              if (type == 'PET_LIVE') 'petCode': petCode.text.trim(),
              if (type == 'PET_LIVE') 'healthStatus': healthStatus.text.trim(),
              if (type == 'PET_LIVE')
                'vaccineCertNo': vaccineCertNo.text.trim(),
              if (type == 'PET_LIVE')
                'quarantineCertNo': quarantineCertNo.text.trim(),
            };
            Navigator.pop(context, payload);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}

// ==================== Product Detail Page ====================
class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({
    required this.product,
    required this.apiClient,
    super.key,
  });
  final Product product;
  final ApiClient apiClient;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  @override
  void initState() {
    super.initState();
    widget.apiClient
        .trackBehavior(
          productId: widget.product.id,
          behaviorType: 'VIEW',
          scene: 'PRODUCT_DETAIL',
        )
        .catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = widget.product;
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                product.isLivePet ? Icons.pets : Icons.shopping_bag_outlined,
                size: 80,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  product.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '¥' + product.price.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(product.type == 'PET_LIVE' ? '活体宠物' : '周边商品')),
              Chip(label: Text(product.category)),
              Chip(label: Text('库存 ' + product.stock.toString())),
              Chip(label: Text(product.status)),
            ],
          ),
          const SizedBox(height: 16),
          if (product.description.isNotEmpty) ...[
            Text(
              '商品描述',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(product.description),
            const SizedBox(height: 16),
          ],
          if (product.livePet != null) ...[
            const Divider(),
            const SizedBox(height: 12),
            Text(
              '活体宠物档案',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _DetailRow(
              label: '宠物编号',
              value: product.livePet!['petCode']?.toString() ?? '-',
            ),
            _DetailRow(
              label: '健康状态',
              value: product.livePet!['healthStatus']?.toString() ?? '-',
            ),
            _DetailRow(
              label: '疫苗证明',
              value: product.livePet!['vaccineCertNo']?.toString() ?? '-',
            ),
            _DetailRow(
              label: '检疫证明',
              value: product.livePet!['quarantineCertNo']?.toString() ?? '-',
            ),
            const SizedBox(height: 12),
            const Text(
              '⚠️ 活体宠物购买后请及时确认健康状况',
              style: TextStyle(color: Colors.orange, fontSize: 13),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed:
                product.stock > 0
                    ? () async {
                      try {
                        await widget.apiClient.addCartItem(
                          productId: product.id,
                          quantity: 1,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(product.name + ' 已加入购物车')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      }
                    }
                    : null,
            icon: const Icon(Icons.add_shopping_cart),
            label: Text(product.stock > 0 ? '加入购物车' : '已售罄'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
