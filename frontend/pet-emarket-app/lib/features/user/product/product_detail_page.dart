import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/api/api_client.dart';
import '../../../core/session/session_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/product.dart';

// ═══════════════════════════════════════════
// ProductsPage — Admin product management
// ═══════════════════════════════════════════
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
    final t = Theme.of(context);
    final s = t.colorScheme;
    return Scaffold(
      backgroundColor: PawmartColors.surfaceBg,
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '商品管理',
                    style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w700, color: PawmartColors.textPrimary),
                  ),
                ),
                FilledButton.icon(
                  onPressed: canManage ? () => showProductDialog() : null,
                  icon: const Icon(Icons.add_business),
                  label: Text('新增商品', style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
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
                      hintText: '按商品名、分类、描述搜索',
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
              Text(errorText!, style: TextStyle(color: s.error)),
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
                                product.isLivePet ? Icons.pets : Icons.shopping_bag_outlined,
                                color: PawmartColors.primary500,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  product.name,
                                  style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w700, color: PawmartColors.textPrimary),
                                ),
                              ),
                              Text('¥${product.price.toStringAsFixed(2)}',
                                style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: PawmartColors.primary500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(label: Text(product.type, style: GoogleFonts.nunito(fontSize: 12))),
                              Chip(label: Text(product.category, style: GoogleFonts.nunito(fontSize: 12))),
                              Chip(label: Text('库存 ${product.stock}', style: GoogleFonts.nunito(fontSize: 12))),
                              Chip(label: Text(product.status, style: GoogleFonts.nunito(fontSize: 12))),
                            ],
                          ),
                          if (product.description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(product.description,
                              style: GoogleFonts.nunito(fontSize: 13, color: PawmartColors.textSecondary),
                            ),
                          ],
                          if (product.livePet != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '检疫证：${product.livePet!['quarantineCertNo'] ?? '-'}    疫苗证：${product.livePet!['vaccineCertNo'] ?? '-'}',
                              style: GoogleFonts.nunito(fontSize: 12, color: PawmartColors.textSecondary),
                            ),
                          ],
                          if (canManage) ...[
                            const Divider(height: 22),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: product.stock > 0 ? () => addToCart(product) : null,
                                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                                  label: Text('加入购物车', style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => showProductDialog(product: product),
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  label: Text('编辑', style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => deleteProduct(product),
                                  icon: const Icon(Icons.delete_outline, size: 18),
                                  label: Text('删除', style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
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
                                label: Text('加入购物车', style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
                                style: FilledButton.styleFrom(
                                  backgroundColor: PawmartColors.accent400,
                                  foregroundColor: PawmartColors.textOnAccent,
                                ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product.name} 已加入购物车')),
        );
      }
    } catch (error) {
      if (mounted) showError(error);
    }
  }

  void showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString())),
    );
  }
}

// ═══════════════════════════════════════════
// Product Dialog — Create/Edit Product
// ═══════════════════════════════════════════
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
    final p = widget.product;
    name = TextEditingController(text: p?.name ?? '');
    category = TextEditingController(text: p?.category ?? '');
    price = TextEditingController(text: p?.price.toString() ?? '');
    stock = TextEditingController(text: p?.stock.toString() ?? '');
    description = TextEditingController(text: p?.description ?? '');
    petCode = TextEditingController(text: p?.livePet?['petCode']?.toString() ?? '');
    healthStatus = TextEditingController(text: p?.livePet?['healthStatus']?.toString() ?? '');
    vaccineCertNo = TextEditingController(text: p?.livePet?['vaccineCertNo']?.toString() ?? '');
    quarantineCertNo = TextEditingController(text: p?.livePet?['quarantineCertNo']?.toString() ?? '');
    type = p?.type ?? 'GOODS';
    status = p?.status ?? 'ON_SALE';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? '新增商品' : '编辑商品',
        style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
      ),
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
                      items: const ['DRAFT', 'ON_SALE', 'OFF_SALE']
                          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                          .toList(),
                      onChanged: (value) => setState(() => status = value ?? status),
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
          child: Text('取消', style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
        ),
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
          child: Text('保存', style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════
// ProductDetailPage — User-facing product detail
// ═══════════════════════════════════════════
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
  int _qty = 1;

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
    final product = widget.product;
    final w = MediaQuery.of(context).size.width;
    final wide = w > 800;

    return Scaffold(
      backgroundColor: PawmartColors.surfaceBg,
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.favorite_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(wide ? 40 : 16, 16, wide ? 40 : 16, 100),
        children: [
          // ——— Product Image ———
          Container(
            height: wide ? 400 : 280,
            decoration: BoxDecoration(
              color: PawmartColors.primary50,
              borderRadius: BorderRadius.circular(pawmartRadiusLg),
            ),
            child: Center(
              child: Icon(
                product.isLivePet ? Icons.pets : Icons.shopping_bag_outlined,
                size: wide ? 100 : 72,
                color: PawmartColors.primary300,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ——— Product Name & Price ———
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  product.name,
                  style: GoogleFonts.nunito(
                    fontSize: wide ? 24 : 20,
                    fontWeight: FontWeight.w700,
                    color: PawmartColors.textPrimary,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '¥${product.price.toStringAsFixed(2)}',
                    style: GoogleFonts.nunito(
                      fontSize: wide ? 26 : 22,
                      fontWeight: FontWeight.w800,
                      color: PawmartColors.primary500,
                    ),
                  ),
                  if (product.stock > 0)
                    Text(
                      '库存 ${product.stock}',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: PawmartColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ——— Tags ———
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: Icon(
                  product.isLivePet ? Icons.pets : Icons.category_outlined,
                  size: 14,
                  color: PawmartColors.primary500,
                ),
                label: Text(
                  product.isLivePet ? '活体宠物' : '周边商品',
                  style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              Chip(
                avatar: const Icon(Icons.label_outline, size: 14, color: PawmartColors.primary500),
                label: Text(
                  product.category,
                  style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              Chip(
                avatar: Icon(
                  product.status == 'ON_SALE' ? Icons.check_circle_outline : Icons.block_outlined,
                  size: 14,
                  color: product.status == 'ON_SALE' ? PawmartColors.success : PawmartColors.error,
                ),
                label: Text(
                  product.status == 'ON_SALE' ? '在售' : product.status,
                  style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ——— Description ———
          if (product.description.isNotEmpty) ...[
            pawmartSectionHeader('商品描述'),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: PawmartColors.surfaceCard,
                borderRadius: BorderRadius.circular(pawmartRadiusMd),
                boxShadow: pawmartShadow1,
              ),
              child: Text(
                product.description,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: PawmartColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ——— Live Pet Info ———
          if (product.livePet != null) ...[
            pawmartSectionHeader('活体宠物档案'),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: PawmartColors.surfaceCard,
                borderRadius: BorderRadius.circular(pawmartRadiusMd),
                boxShadow: pawmartShadow1,
              ),
              child: Column(
                children: [
                  _infoRow('宠物编号', product.livePet!['petCode']?.toString() ?? '-'),
                  const Divider(height: 16),
                  _infoRow('健康状态', product.livePet!['healthStatus']?.toString() ?? '-'),
                  const Divider(height: 16),
                  _infoRow('疫苗证明', product.livePet!['vaccineCertNo']?.toString() ?? '-'),
                  const Divider(height: 16),
                  _infoRow('检疫证明', product.livePet!['quarantineCertNo']?.toString() ?? '-'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PawmartColors.accent50,
                borderRadius: BorderRadius.circular(pawmartRadiusMd),
                border: Border.all(color: PawmartColors.accent200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 18, color: PawmartColors.accent600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '活体宠物购买后请及时确认健康状况',
                      style: GoogleFonts.nunito(fontSize: 13, color: PawmartColors.accent700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ——— Quantity Selector ———
          pawmartSectionHeader('购买数量'),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(pawmartRadiusMd),
                  border: Border.all(color: PawmartColors.neutral200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '$_qty',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: PawmartColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: () => setState(() => _qty++),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '库存 ${product.stock} 件',
                style: GoogleFonts.nunito(fontSize: 13, color: PawmartColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ——— Reviews Section ———
          pawmartSectionHeader('商品评价 (12)', actionLabel: '查看全部'),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
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
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: PawmartColors.primary100,
                      child: const Icon(Icons.person, size: 16, color: PawmartColors.primary500),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '宠物爱好者',
                      style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: PawmartColors.textPrimary),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (i) => Icon(
                        i < 5 ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 16,
                        color: PawmartColors.accent400,
                      )),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '质量很好，物流很快，毛孩子非常喜欢！推荐购买。',
                  style: GoogleFonts.nunito(fontSize: 13, color: PawmartColors.textSecondary, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
      // ——— Sticky Bottom Bar ———
      bottomNavigationBar: Container(
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
              // Favorite button
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(pawmartRadiusMd),
                  border: Border.all(color: PawmartColors.neutral200),
                ),
                child: IconButton(
                  icon: const Icon(Icons.favorite_outline),
                  onPressed: () {},
                  color: PawmartColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              // Cart button
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: product.stock > 0
                        ? () async {
                            try {
                              for (int i = 0; i < _qty; i++) {
                                await widget.apiClient.addCartItem(productId: product.id, quantity: 1);
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${product.name} x$_qty 已加入购物车')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            }
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: PawmartColors.primary500,
                    ),
                    child: Text(
                      product.stock > 0 ? '加入购物车' : '已售罄',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Buy now button
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: product.stock > 0 ? () {} : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: PawmartColors.accent400,
                      foregroundColor: PawmartColors.textOnAccent,
                    ),
                    child: Text(
                      '立即购买',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: GoogleFonts.nunito(fontSize: 13, color: PawmartColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: PawmartColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
