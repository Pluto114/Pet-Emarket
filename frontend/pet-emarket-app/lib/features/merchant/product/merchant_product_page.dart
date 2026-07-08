import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/session/session_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/media_asset.dart';
import '../../../models/product.dart';
import '../../../models/store.dart';
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
  List<PetStore> stores = [];
  PetStore? selectedStore;
  final keywordCtrl = TextEditingController();
  String _categoryFilter = '';
  int _currentPage = 0;
  static const _pageSize = 10;

  // 从商品列表中提取所有分类
  Set<String> get _categories => products.map((p) => p.category).where((c) => c.isNotEmpty).toSet();

  // 按分类过滤
  List<Product> get _filteredProducts {
    if (_categoryFilter.isEmpty) return products;
    return products.where((p) => p.category == _categoryFilter).toList();
  }

  int get _totalPages => (_filteredProducts.length / _pageSize).ceil();

  List<Product> get _pagedProducts {
    final filtered = _filteredProducts;
    final start = _currentPage * _pageSize;
    if (start >= filtered.length) return [];
    final end = (start + _pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  @override
  void initState() {
    super.initState();
    loadStores();
  }

  @override
  void dispose() {
    keywordCtrl.dispose();
    super.dispose();
  }

  Future<void> loadStores() async {
    setState(() {
      loading = true;
      errorText = null;
    });
    try {
      stores = await widget.apiClient.listStores(authenticated: true);
      if (stores.isNotEmpty && selectedStore == null) {
        selectedStore = stores.first;
      }
    } catch (e) {
      errorText = e.toString();
    }
    await loadProducts();
  }

  Future<void> loadProducts() async {
    if (selectedStore == null) {
      if (mounted) setState(() => loading = false);
      return;
    }
    setState(() {
      loading = true;
      errorText = null;
    });
    try {
      products = await widget.apiClient.listStoreProducts(selectedStore!.id);
    } catch (e) {
      errorText = e.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  void _selectStore(PetStore store) {
    if (selectedStore?.id == store.id) return; // skip if already selected
    setState(() {
      selectedStore = store;
      products = [];
      errorText = null;
    });
    loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (loading) return const Center(child: CircularProgressIndicator());

    if (errorText != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.red), const SizedBox(height: 12),
        Text(errorText!, style: const TextStyle(color: Colors.red)), const SizedBox(height: 16),
        ElevatedButton(onPressed: loadStores, child: const Text('重试')),
      ]));
    }

    return ListView(padding: const EdgeInsets.all(24), children: [
      Text('商品管理', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 16),

      // Store selector
      if (stores.isEmpty)
        const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('暂未关联店铺', style: TextStyle(color: Colors.grey)))))
      else ...[
        Text('选择店铺', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final s in stores) ChoiceChip(label: Text(s.name), selected: selectedStore?.id == s.id, onSelected: (_) => _selectStore(s), avatar: const Icon(Icons.store, size: 16)),
        ]),
        const SizedBox(height: 16),
      ],

      // Selected store header
      if (selectedStore != null) ...[
        Row(children: [
          Expanded(child: Text('${selectedStore!.name} 的商品', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
          ElevatedButton.icon(onPressed: () => _showDialog(), icon: const Icon(Icons.add, size: 16), label: const Text('发布商品')),
        ]),
        const SizedBox(height: 12),

        // Category filter
        if (products.isNotEmpty) ...[
          Row(children: [
            const Text('分类：', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 8),
            SizedBox(width: 150, child: DropdownButtonFormField<String>(
              value: _categoryFilter,
              decoration: InputDecoration(isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
              items: [
                const DropdownMenuItem(value: '', child: Text('所有类型', style: TextStyle(fontSize: 13))),
                for (final cat in _categories) DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 13))),
              ],
              onChanged: (v) => setState(() { _categoryFilter = v ?? ''; _currentPage = 0; }),
            )),
          ]),
          const SizedBox(height: 8),
        ],

        // Page info
        Text('共 ${_filteredProducts.length} 件  |  第 ${_currentPage + 1}/${_totalPages} 页', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        const SizedBox(height: 8),

        if (_filteredProducts.isEmpty)
          const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('暂无商品', style: TextStyle(color: Colors.grey, fontSize: 15))))
        else
          for (final p in _pagedProducts)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showProductDetail(p),
                child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
                    _chip(p.status == 'ON_SALE' ? '在售' : p.status == 'DRAFT' ? '草稿' : p.status == 'OFF_SALE' ? '下架' : p.status, p.status == 'ON_SALE' ? Colors.green : p.status == 'DRAFT' ? Colors.grey : Colors.orange),
                  ]),
                  const SizedBox(height: 6),
                  Text('${p.type == 'PET_LIVE' ? '活体宠物' : '周边商品'}  |  ${p.category}  |  ¥${p.price.toStringAsFixed(2)}  |  库存 ${p.stock}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    if (p.status != 'ON_SALE' && p.stock > 0) TextButton.icon(onPressed: () => _changeStatus(p, 'ON_SALE'), icon: const Icon(Icons.arrow_upward, size: 14), label: const Text('上架', style: TextStyle(fontSize: 11))),
                    if (p.status != 'OFF_SALE') TextButton.icon(onPressed: () => _changeStatus(p, 'OFF_SALE'), icon: const Icon(Icons.arrow_downward, size: 14), label: const Text('下架', style: TextStyle(fontSize: 11))),
                    TextButton.icon(onPressed: () => _showDialog(product: p), icon: const Icon(Icons.edit, size: 14), label: const Text('编辑', style: TextStyle(fontSize: 11))),
                    TextButton.icon(onPressed: () => _delete(p), icon: const Icon(Icons.delete, size: 14, color: Colors.red), label: const Text('删除', style: TextStyle(color: Colors.red, fontSize: 11))),
                  ]),
                ]),
              ),
            )),
        // Pagination
        if (_totalPages > 1) ...[
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(icon: const Icon(Icons.chevron_left), onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null),
            Text('${_currentPage + 1} / $_totalPages', style: const TextStyle(fontSize: 13)),
            IconButton(icon: const Icon(Icons.chevron_right), onPressed: _currentPage < _totalPages - 1 ? () => setState(() => _currentPage++) : null),
          ]),
        ],
      ],
    ]);
  }

  void _showProductDetail(Product p) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text(p.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      content: SizedBox(width: 500, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        if (p.coverUrl.isNotEmpty)
          ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(p.coverUrl, width: double.infinity, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Container(height: 120, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)), child: const Center(child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey)))))
        else
          Container(height: 120, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)), child: const Center(child: Icon(Icons.image, size: 40, color: Colors.grey))),
        const SizedBox(height: 16),
        _dr('类型', p.type == 'PET_LIVE' ? '活体宠物' : '周边商品'),
        _dr('分类', p.category.isNotEmpty ? p.category : '未分类'),
        _dr('价格', '¥${p.price.toStringAsFixed(2)}'),
        _dr('库存', '${p.stock}'),
        _dr('状态', p.status == 'ON_SALE' ? '在售' : p.status == 'DRAFT' ? '草稿' : p.status == 'OFF_SALE' ? '下架' : p.status),
        if (p.description.isNotEmpty) ...[const SizedBox(height: 8), const Text('描述', style: TextStyle(fontSize: 12, color: Colors.grey)), const SizedBox(height: 4), Text(p.description, style: const TextStyle(fontSize: 14))],
        if (p.isLivePet) ...[
          const SizedBox(height: 16), const Divider(), const Text('活体宠物档案', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)), const SizedBox(height: 8),
          if (p.livePet?['petCode']?.toString().isNotEmpty == true) _dr('宠物编号', p.livePet!['petCode'].toString()),
          if (p.livePet?['breed']?.toString().isNotEmpty == true) _dr('品种', p.livePet!['breed'].toString()),
          if (p.livePet?['healthStatus']?.toString().isNotEmpty == true) _dr('健康状态', p.livePet!['healthStatus'].toString()),
          if (p.livePet?['vaccineCertNo']?.toString().isNotEmpty == true) _dr('疫苗证明', p.livePet!['vaccineCertNo'].toString()),
          if (p.livePet?['quarantineCertNo']?.toString().isNotEmpty == true) _dr('检疫证明', p.livePet!['quarantineCertNo'].toString()),
        ],
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭'))],
    ));
  }

  Widget _dr(String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 70, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
    ]));
  }

  Widget _chip(String label, Color color) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)));
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
      builder: (ctx) => _ProductDialog(product: product, apiClient: widget.apiClient),
    );
    if (result == null) return;
    // Attach selected storeId when creating new product
    if (product == null && selectedStore != null) {
      result['storeId'] = int.tryParse(selectedStore!.id) ?? 0;
    }
    try {
      if (product == null) {
        await widget.apiClient.createProduct(result);
        if (mounted) showSuccess(context, '商品已发布');
      } else {
        await widget.apiClient.updateProduct(product.id, result);
        if (mounted) showSuccess(context, '商品更新成功');
      }
      await loadProducts();
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
      await loadProducts();
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
      await loadProducts();
      if (mounted) showSuccess(context, '${p.name} 已删除');
    } catch (e) {
      if (mounted) showError(context, e.toString());
    }
  }

  // ── Video Upload ──
  Future<void> _showVideoUploadDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _VideoUploadDialog(),
    );
    if (result == null || !mounted) return;
    try {
      await widget.apiClient.uploadMedia(
        title: result['title'] as String,
        mediaType: 'VIDEO',
        fileName: result['fileName'] as String,
        fileBytes: result['fileBytes'] as List<int>,
        productId: result['productId']?.toString() ?? '',
        description: result['description']?.toString() ?? '',
        fileContentType: result['contentType']?.toString() ?? '',
      );
      if (mounted) showSuccess(context, '视频已上传，等待审核');
    } catch (e) {
      if (mounted) showError(context, e.toString());
    }
  }
}

class _StoreChip extends StatelessWidget {
  final PetStore store;
  final bool isSelected;
  final VoidCallback onTap;
  const _StoreChip({
    required this.store,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 160,
      height: 90,
      child: Card(
        elevation: isSelected ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        color: isSelected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(Icons.store,
                        size: 16,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        store.name,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${store.rating} ★ · ${store.status == 'OPEN' ? '营业中' : '已关闭'}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductDialog extends StatefulWidget {
  final Product? product;
  final dynamic apiClient;
  const _ProductDialog({this.product, required this.apiClient});
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
  bool _uploading = false;

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

  Future<void> _pickAndUploadCover() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false, withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null || file.bytes!.isEmpty) {
      if (mounted) showError(context, '无法读取文件');
      return;
    }
    setState(() => _uploading = true);
    try {
      final media = await widget.apiClient.uploadMedia(
        title: file.name,
        mediaType: 'IMAGE',
        fileName: file.name,
        fileBytes: file.bytes!,
        fileContentType: _imageContentType(file.name),
      );
      coverUrlCtrl.text = media.url;
      if (mounted) showSuccess(context, '封面上传成功');
    } catch (e) {
      if (mounted) showError(context, e.toString());
    }
    if (mounted) setState(() => _uploading = false);
  }

  String _imageContentType(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) { 'png' => 'image/png', 'gif' => 'image/gif', 'webp' => 'image/webp', _ => 'image/jpeg' };
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
                      value: type,
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
                      value: status,
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
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _uploading ? null : _pickAndUploadCover,
                  icon: _uploading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.cloud_upload, size: 18),
                  label: Text(_uploading ? '上传中…' : '选择本地上传'),
                ),
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

// ── Video Upload Dialog ──
class _VideoUploadDialog extends StatefulWidget {
  const _VideoUploadDialog();
  @override
  State<_VideoUploadDialog> createState() => _VideoUploadDialogState();
}

class _VideoUploadDialogState extends State<_VideoUploadDialog> {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final productIdCtrl = TextEditingController();
  String? fileName;
  List<int>? fileBytes;
  String? contentType;
  bool uploading = false;

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    productIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) {
      if (mounted) showError(context, '无法读取文件');
      return;
    }
    setState(() {
      fileName = file.name;
      fileBytes = file.bytes!;
      contentType = _videoContentType(file.name);
      if (titleCtrl.text.isEmpty) {
        titleCtrl.text = file.name.replaceAll(RegExp(r'\.[^.]+'), '');
      }
    });
  }

  String _videoContentType(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'mov' => 'video/quicktime',
      'avi' => 'video/x-msvideo',
      'webm' => 'video/webm',
      'm4v' => 'video/mp4',
      _ => 'video/mp4',
    };
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('上传视频'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: _pickVideo,
                icon: const Icon(Icons.videocam_outlined),
                label: Text(fileName ?? '选择视频文件'),
              ),
              if (fileName != null) ...[
                const SizedBox(height: 4),
                Text(fileName!, style: TextStyle(fontSize: 12, color: PawmartColors.textSecondary)),
              ],
              const SizedBox(height: 14),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: '视频标题 *'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: '视频描述'),
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: productIdCtrl,
                decoration: const InputDecoration(
                  labelText: '关联商品ID（可选）',
                  helperText: '填写商品数字ID可将视频关联到该商品',
                ),
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
          onPressed: (titleCtrl.text.trim().isEmpty || fileBytes == null || uploading)
              ? null
              : () {
                  setState(() => uploading = true);
                  Navigator.pop(context, {
                    'title': titleCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'productId': productIdCtrl.text.trim(),
                    'fileName': fileName,
                    'fileBytes': fileBytes,
                    'contentType': contentType,
                  });
                },
          child: const Text('上传'),
        ),
      ],
    );
  }
}
