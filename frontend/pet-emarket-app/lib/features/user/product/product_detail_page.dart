import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/session/session_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/media_asset.dart';
import '../../../models/product.dart';
import '../../../shared/widgets/toast.dart';
import '../../../shared/widgets/video_factory_stub.dart'
    if (dart.library.html) '../../../shared/widgets/video_factory_web.dart';
import '../../../shared/widgets/web_helpers_stub.dart'
    if (dart.library.html) '../../../shared/widgets/web_helpers_web.dart';

/// Register HTML5 video player view factory (call once)
void _ensureVideoFactoryRegistered() {
  ensureVideoFactoryRegistered();
}

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
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: PawmartColors.textPrimary,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: canManage ? () => showProductDialog() : null,
                  icon: const Icon(Icons.add_business),
                  label: Text(
                    '新增商品',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
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
                                product.isLivePet
                                    ? Icons.pets
                                    : Icons.shopping_bag_outlined,
                                color: PawmartColors.primary500,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  product.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: PawmartColors.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                '¥${product.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: PawmartColors.primary500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(
                                label: Text(
                                  product.type,
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                              Chip(
                                label: Text(
                                  product.category,
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                              Chip(
                                label: Text(
                                  '库存 ${product.stock}',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                              Chip(
                                label: Text(
                                  product.status,
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          if (product.description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              product.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: PawmartColors.textSecondary,
                              ),
                            ),
                          ],
                          if (product.livePet != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '检疫证：${product.livePet!['quarantineCertNo'] ?? '-'}    疫苗证：${product.livePet!['vaccineCertNo'] ?? '-'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: PawmartColors.textSecondary,
                              ),
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
                                  icon: const Icon(
                                    Icons.add_shopping_cart,
                                    size: 18,
                                  ),
                                  label: Text(
                                    '加入购物车',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed:
                                      () => showProductDialog(product: product),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                  ),
                                  label: Text(
                                    '编辑',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => deleteProduct(product),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                  ),
                                  label: Text(
                                    '删除',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
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
                                label: Text(
                                  '加入购物车',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
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
      products =
          canManage
              ? await widget.apiClient.listManagedProducts(
                keyword: keywordController.text,
                type: widget.filterType,
              )
              : await widget.apiClient.listProducts(
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
  late final TextEditingController coverUrl;
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
    coverUrl = TextEditingController(text: p?.coverUrl ?? '');
    petCode = TextEditingController(
      text: p?.livePet?['petCode']?.toString() ?? '',
    );
    healthStatus = TextEditingController(
      text: p?.livePet?['healthStatus']?.toString() ?? '',
    );
    vaccineCertNo = TextEditingController(
      text: p?.livePet?['vaccineCertNo']?.toString() ?? '',
    );
    quarantineCertNo = TextEditingController(
      text: p?.livePet?['quarantineCertNo']?.toString() ?? '',
    );
    type = p?.type ?? 'GOODS';
    status = p?.status ?? 'ON_SALE';
  }

  @override
  void dispose() {
    name.dispose();
    category.dispose();
    price.dispose();
    stock.dispose();
    description.dispose();
    coverUrl.dispose();
    petCode.dispose();
    healthStatus.dispose();
    vaccineCertNo.dispose();
    quarantineCertNo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.product == null ? '新增商品' : '编辑商品',
        style: TextStyle(fontWeight: FontWeight.w700),
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
              const SizedBox(height: 10),
              TextField(
                controller: coverUrl,
                decoration: const InputDecoration(labelText: '封面图片 URL'),
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
          child: Text('取消', style: TextStyle(fontWeight: FontWeight.w600)),
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
              'coverUrl': coverUrl.text.trim(),
              if (type == 'PET_LIVE') 'petCode': petCode.text.trim(),
              if (type == 'PET_LIVE') 'healthStatus': healthStatus.text.trim(),
              if (type == 'PET_LIVE')
                'vaccineCertNo': vaccineCertNo.text.trim(),
              if (type == 'PET_LIVE')
                'quarantineCertNo': quarantineCertNo.text.trim(),
            };
            Navigator.pop(context, payload);
          },
          child: Text('保存', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════
// ProductDetailPage — 参照原型图重构
// ═══════════════════════════════════════════
class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({required this.product, required this.apiClient, super.key});
  final Product product;
  final ApiClient apiClient;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Product product;
  List<ProductReview> reviews = [];
  List<MediaAsset> _mediaAssets = [];
  String? reviewError;
  int _qty = 1;
  int _selectedTab = 0;

  List<MediaAsset> get _videos => _mediaAssets.where((m) => m.mediaType == 'VIDEO' && m.status == 'APPROVED').toList();

  @override
  void initState() {
    super.initState();
    product = widget.product;
    _loadProductDetail();
    widget.apiClient.trackBehavior(productId: widget.product.id, behaviorType: 'VIEW', scene: 'PRODUCT_DETAIL').catchError((_) {});
  }

  Future<void> _loadProductDetail() async {
    try {
      final nextProduct = await widget.apiClient.getProduct(widget.product.id);
      final nextReviews = await widget.apiClient.listProductReviews(widget.product.id);
      if (!mounted) return;
      setState(() {
        product = nextProduct;
        reviews = nextReviews;
        reviewError = null;
        if (_qty > product.stock) _qty = product.stock <= 0 ? 1 : product.stock;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => reviewError = error.toString());
    }
    // Load media independently — failure does not break the page
    try {
      _mediaAssets = await widget.apiClient.listProductMedia(widget.product.id);
      if (mounted) setState(() {});
    } catch (_) {
      _mediaAssets = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final wide = w > 800;

    return Scaffold(
      backgroundColor: PawmartColors.surfaceBg,
      appBar: AppBar(
        title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () => showInfo(context, '分享功能待接入')),
          IconButton(icon: const Icon(Icons.favorite_outline), onPressed: () => showInfo(context, '收藏功能已加入待办队列')),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.only(bottom: 100),
        children: [
          // Breadcrumb
          Padding(
            padding: EdgeInsets.fromLTRB(wide ? 40 : 16, 12, wide ? 40 : 16, 4),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Text('首页', style: TextStyle(fontSize: 13, color: PawmartColors.primary500)),
              ),
              Icon(Icons.chevron_right, size: 14, color: PawmartColors.textSecondary),
              Text(product.category.isNotEmpty ? product.category : '全部', style: TextStyle(fontSize: 13, color: PawmartColors.primary500)),
              Icon(Icons.chevron_right, size: 14, color: PawmartColors.textSecondary),
              Expanded(child: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: PawmartColors.textSecondary))),
            ]),
          ),

          const SizedBox(height: 12),

          // Two-column layout (wide) / stacked (narrow)
          if (wide)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 5, child: _buildImageSection(wide)),
              const SizedBox(width: 32),
              Expanded(flex: 5, child: _buildInfoSection(wide)),
            ])
          else ...[
            _buildImageSection(wide),
            const SizedBox(height: 20),
            _buildInfoSection(wide),
          ],

          const SizedBox(height: 24),

          // Trust badges
          Padding(
            padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 16),
            child: Row(children: [
              _trustBadge(Icons.verified_user_outlined, '正品保障'),
              const SizedBox(width: 12),
              _trustBadge(Icons.local_shipping_outlined, '极速配送'),
              const SizedBox(width: 12),
              _trustBadge(Icons.replay_outlined, '7天无理由'),
            ]),
          ),

          // ── Product Videos ──
          if (_videos.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildVideoSection(wide),
          ],

          const SizedBox(height: 24),

          // Tabs
          Padding(
            padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 16),
            child: Row(
              children: [
                _tabItem('商品详情', 0),
                const SizedBox(width: 24),
                _tabItem('用户评价${reviews.isNotEmpty ? " (${reviews.length})" : ""}', 1),
                const SizedBox(width: 24),
                _tabItem('活体档案', 2),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tab content
          if (_selectedTab == 0) _buildDetailTab(wide),
          if (_selectedTab == 1) _buildReviewsTab(wide),
          if (_selectedTab == 2) _buildLivePetTab(wide),
        ],
      ),
      // Sticky bottom bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(color: PawmartColors.surfaceCard, boxShadow: [BoxShadow(color: const Color(0xFF36322E).withAlpha(15), blurRadius: 10, offset: const Offset(0, -2))]),
        child: SafeArea(top: false, child: Row(children: [
          Expanded(child: SizedBox(height: 48, child: FilledButton(
            onPressed: product.stock > 0 ? () => _addToCart(product) : null,
            style: FilledButton.styleFrom(backgroundColor: PawmartColors.primary500, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(pawmartRadiusMd))),
            child: Text(product.stock > 0 ? '加入购物车' : '已售罄', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ))),
          const SizedBox(width: 12),
          Expanded(child: SizedBox(height: 48, child: FilledButton(
            onPressed: product.stock > 0 ? () => _addToCart(product, checkoutHint: true) : null,
            style: FilledButton.styleFrom(backgroundColor: PawmartColors.accent400, foregroundColor: PawmartColors.textOnAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(pawmartRadiusMd))),
            child: const Text('立即购买', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ))),
        ])),
      ),
    );
  }

  // Image section
  Widget _buildImageSection(bool wide) {
    return Column(children: [
      Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: wide ? 420 : 300),
        decoration: BoxDecoration(
          color: PawmartColors.neutral100,
          borderRadius: BorderRadius.circular(pawmartRadiusLg),
        ),
        child: AspectRatio(
          aspectRatio: 1,
          child: product.coverUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(pawmartRadiusLg),
                  child: Image.network(product.coverUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _bigIcon()),
                )
              : _bigIcon(),
        ),
      ),
      const SizedBox(height: 8),
      Text('点击图片可放大查看', style: TextStyle(fontSize: 11, color: PawmartColors.textSecondary)),
    ]);
  }

  Widget _bigIcon() {
    return Center(child: Icon(
      product.isLivePet ? Icons.pets : Icons.shopping_bag_outlined,
      size: 80, color: PawmartColors.primary300,
    ));
  }

  // Info section (right side on wide)
  Widget _buildInfoSection(bool wide) {
    final fakeListPrice = (product.price * 1.25).ceilToDouble();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Name
      Text(product.name, style: TextStyle(fontSize: wide ? 24 : 20, fontWeight: FontWeight.w700, color: PawmartColors.textPrimary, height: 1.2)),
      const SizedBox(height: 12),
      // Price row
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('¥${product.price.toStringAsFixed(0)}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: PawmartColors.error)),
        const SizedBox(width: 10),
        Text('¥${fakeListPrice.toStringAsFixed(0)}', style: TextStyle(fontSize: 16, color: PawmartColors.textSecondary, decoration: TextDecoration.lineThrough)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: PawmartColors.error.withAlpha(20), borderRadius: BorderRadius.circular(4)),
          child: Text('省 ¥${(fakeListPrice - product.price).toStringAsFixed(0)}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: PawmartColors.error)),
        ),
      ]),
      const SizedBox(height: 12),
      // Stock
      Row(children: [
        Icon(Icons.inventory_2_outlined, size: 14, color: product.stock > 0 ? PawmartColors.success : PawmartColors.error),
        const SizedBox(width: 4),
        Text(product.stock > 0 ? '库存 ${product.stock} 件' : '已售罄', style: TextStyle(fontSize: 13, color: product.stock > 0 ? PawmartColors.textSecondary : PawmartColors.error)),
      ]),
      const SizedBox(height: 14),
      // Description
      if (product.description.isNotEmpty)
        Text(product.description, style: TextStyle(fontSize: 14, color: PawmartColors.textSecondary, height: 1.6)),
      const SizedBox(height: 16),
      // Category tag
      Row(children: [
        Text('分类：', style: TextStyle(fontSize: 13, color: PawmartColors.textSecondary)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: PawmartColors.primary50, borderRadius: BorderRadius.circular(pawmartRadiusFull)),
          child: Text(product.category.isNotEmpty ? product.category : '通用', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: PawmartColors.primary600)),
        ),
      ]),
      const SizedBox(height: 16),
      // Quantity selector
      Text('数量', style: TextStyle(fontSize: 13, color: PawmartColors.textSecondary)),
      const SizedBox(height: 8),
      Row(children: [
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(pawmartRadiusSm), border: Border.all(color: PawmartColors.neutral200)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            InkWell(
              onTap: _qty > 1 ? () => setState(() => _qty--) : null,
              child: Container(width: 36, height: 36, alignment: Alignment.center, child: Icon(Icons.remove, size: 18, color: _qty > 1 ? PawmartColors.textPrimary : PawmartColors.neutral300)),
            ),
            Container(width: 44, height: 36, alignment: Alignment.center, decoration: BoxDecoration(border: Border(left: BorderSide(color: PawmartColors.neutral200), right: BorderSide(color: PawmartColors.neutral200))), child: Text('$_qty', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: PawmartColors.textPrimary))),
            InkWell(
              onTap: _qty < product.stock ? () => setState(() => _qty++) : null,
              child: Container(width: 36, height: 36, alignment: Alignment.center, child: Icon(Icons.add, size: 18, color: _qty < product.stock ? PawmartColors.textPrimary : PawmartColors.neutral300)),
            ),
          ]),
        ),
        const SizedBox(width: 12),
        Text('共 ¥${(product.price * _qty).toStringAsFixed(0)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: PawmartColors.textPrimary)),
      ]),
    ]);
  }

  Widget _trustBadge(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: PawmartColors.surfaceCard, borderRadius: BorderRadius.circular(pawmartRadiusSm), border: Border.all(color: PawmartColors.neutral200)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: PawmartColors.primary500),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: PawmartColors.textPrimary)),
        ]),
      ),
    );
  }

  Widget _tabItem(String label, int index) {
    final active = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: active ? PawmartColors.primary500 : Colors.transparent, width: 2))),
        child: Text(label, style: TextStyle(fontSize: 15, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? PawmartColors.primary500 : PawmartColors.textSecondary)),
      ),
    );
  }

  // Detail tab
  Widget _buildDetailTab(bool wide) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        pawmartSectionHeader('产品特点'),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: wide ? 2 : 1,
          childAspectRatio: wide ? 4 : 5,
          mainAxisSpacing: 10, crossAxisSpacing: 10,
          children: [
            _featureItem(Icons.pets, '${product.category}', '专为${product.category}精选优质商品'),
            _featureItem(Icons.check_circle_outline, '品质保证', '正品授权，品质有保障'),
            _featureItem(Icons.eco_outlined, '安全健康', '符合宠物食品安全标准'),
            _featureItem(Icons.auto_awesome, '精选推荐', '根据${product.category}需求精准匹配'),
          ],
        ),
        const SizedBox(height: 24),
        if (product.description.isNotEmpty) ...[
          pawmartSectionHeader('商品描述'),
          const SizedBox(height: 10),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: PawmartColors.surfaceCard, borderRadius: BorderRadius.circular(pawmartRadiusMd), boxShadow: pawmartShadow1),
            child: Text(product.description, style: TextStyle(fontSize: 14, color: PawmartColors.textSecondary, height: 1.7)),
          ),
        ],
      ]),
    );
  }

  Widget _featureItem(IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: PawmartColors.neutral50, borderRadius: BorderRadius.circular(pawmartRadiusSm)),
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: PawmartColors.primary50, borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 20, color: PawmartColors.primary500)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: PawmartColors.textPrimary)),
          const SizedBox(height: 2),
          Text(desc, style: TextStyle(fontSize: 11, color: PawmartColors.textSecondary)),
        ])),
      ]),
    );
  }

  // Reviews tab
  Widget _buildReviewsTab(bool wide) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 16),
      child: Container(
        width: double.infinity, padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: PawmartColors.surfaceCard, borderRadius: BorderRadius.circular(pawmartRadiusMd), boxShadow: pawmartShadow1),
        child: reviewError != null
            ? Text(reviewError!, style: TextStyle(fontSize: 13, color: PawmartColors.error))
            : reviews.isEmpty
                ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('暂无评价，购买后即可评价', style: TextStyle(fontSize: 14, color: PawmartColors.textSecondary))))
                : Column(children: reviews.map((r) => _reviewItem(r)).toList()),
      ),
    );
  }

  Widget _reviewItem(ProductReview review) {
    final rating = review.rating.clamp(0, 5);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 16, backgroundColor: PawmartColors.primary100, child: const Icon(Icons.person, size: 16, color: PawmartColors.primary500)),
          const SizedBox(width: 8),
          Text('用户 ${review.userId}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: PawmartColors.textPrimary)),
          const Spacer(),
          Row(mainAxisSize: MainAxisSize.min, children: List.generate(5, (i) => Icon(i < rating ? Icons.star_rounded : Icons.star_outline_rounded, size: 14, color: PawmartColors.accent400))),
        ]),
        if (review.content.isNotEmpty) ...[const SizedBox(height: 6), Text(review.content, style: TextStyle(fontSize: 13, color: PawmartColors.textSecondary, height: 1.5))],
        const Divider(height: 20),
      ]),
    );
  }

  // Live pet tab
  Widget _buildLivePetTab(bool wide) {
    if (product.livePet == null) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 16),
        child: Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('此商品不是活体宠物', style: TextStyle(fontSize: 14, color: PawmartColors.textSecondary)))),
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 16),
      child: Column(children: [
        Container(
          width: double.infinity, padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: PawmartColors.surfaceCard, borderRadius: BorderRadius.circular(pawmartRadiusMd), boxShadow: pawmartShadow1),
          child: Column(children: [
            _lr('宠物编号', product.livePet!['petCode']?.toString() ?? '-'),
            const Divider(height: 16),
            _lr('健康状态', product.livePet!['healthStatus']?.toString() ?? '-'),
            const Divider(height: 16),
            _lr('疫苗证明', product.livePet!['vaccineCertNo']?.toString() ?? '-'),
            const Divider(height: 16),
            _lr('检疫证明', product.livePet!['quarantineCertNo']?.toString() ?? '-'),
          ]),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: PawmartColors.accent50, borderRadius: BorderRadius.circular(pawmartRadiusMd), border: Border.all(color: PawmartColors.accent200)),
          child: Row(children: [
            const Icon(Icons.warning_amber_rounded, size: 18, color: PawmartColors.accent600),
            const SizedBox(width: 8),
            const Expanded(child: Text('活体宠物购买后请及时确认健康状况，如有异常请立即联系客服', style: TextStyle(fontSize: 13, color: PawmartColors.accent700))),
          ]),
        ),
      ]),
    );
  }

  // ── Video Section ──
  Widget _buildVideoSection(bool wide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 16),
          child: pawmartSectionHeader('商品视频', actionLabel: '${_videos.length}个视频'),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 16),
            itemCount: _videos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, i) => _videoCard(_videos[i]),
          ),
        ),
      ],
    );
  }

  Widget _videoCard(MediaAsset video) {
    return GestureDetector(
      onTap: () => _playVideo(video),
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          color: PawmartColors.neutral900,
          borderRadius: BorderRadius.circular(pawmartRadiusMd),
          boxShadow: pawmartShadow1,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Cover or placeholder
            if (video.coverUrl.isNotEmpty)
              Image.network(video.coverUrl, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _videoPlaceholder(),
              )
            else
              _videoPlaceholder(),
            // Gradient overlay
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withAlpha(180), Colors.transparent],
                  ),
                ),
              ),
            ),
            // Play button
            Center(
              child: Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(220),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(60), blurRadius: 12)],
                ),
                child: const Icon(Icons.play_arrow_rounded, size: 32, color: PawmartColors.primary500),
              ),
            ),
            // Title overlay
            Positioned(
              bottom: 12, left: 14, right: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(video.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                  if (video.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(video.description, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(180))),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _videoPlaceholder() {
    return Container(
      color: PawmartColors.neutral800,
      child: Center(
        child: Icon(Icons.videocam_rounded, size: 48, color: Colors.white.withAlpha(80)),
      ),
    );
  }

  void _playVideo(MediaAsset video) {
    _ensureVideoFactoryRegistered();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: Colors.black87,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(video.title,
                        style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.open_in_new, color: Colors.white70, size: 20),
                          tooltip: '在新标签页打开',
                          onPressed: () => openUrlInNewTab(video.url),
                          padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70, size: 22),
                          onPressed: () => Navigator.pop(ctx),
                          padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // HTML5 Video Player
              const SizedBox(
                width: 800,
                height: 450,
                child: HtmlElementView(viewType: 'pawmart-video-player'),
              ),
            ],
          ),
        ),
      ),
    );
    // Set video source after dialog is shown
    Future.delayed(const Duration(milliseconds: 100), () {
      final el = getFirstVideoElement();
      if (el != null) {
        el.src = _resolveMediaUrl(video.url);
        el.load();
      }
    });
  }

  String _resolveMediaUrl(String url) {
    if (url.startsWith('/uploads/')) {
      return 'http://localhost:8080$url';
    }
    return url;
  }

  Widget _lr(String label, String value) {
    return Row(children: [
      SizedBox(width: 80, child: Text(label, style: TextStyle(fontSize: 13, color: PawmartColors.textSecondary))),
      Expanded(child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: PawmartColors.textPrimary))),
    ]);
  }

  Future<void> _addToCart(Product product, {bool checkoutHint = false}) async {
    try {
      await widget.apiClient.addCartItem(productId: product.id, quantity: _qty);
      if (mounted) {
        showSuccess(context, checkoutHint ? '${product.name} x$_qty 已加入购物车，请到购物车结算' : '${product.name} x$_qty 已加入购物车');
      }
    } catch (e) {
      if (mounted) showError(context, e.toString());
    }
  }
}
