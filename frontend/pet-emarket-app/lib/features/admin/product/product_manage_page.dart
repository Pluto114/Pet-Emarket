import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../models/product.dart';
import '../../../models/store.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/toast.dart';

class ProductManagePage extends StatefulWidget {
  const ProductManagePage({required this.apiClient, required this.sessionStore, super.key});
  final ApiClient apiClient;
  final dynamic sessionStore;
  @override
  State<ProductManagePage> createState() => _State();
}

class _State extends State<ProductManagePage> {
  bool _loading = true;
  String? _error;
  List<PetStore> _stores = [];
  final Map<String, List<Product>> _storeProducts = {};
  PetStore? _selectedStore;
  int _storePage = 0;
  String _storeKeyword = '';
  String _productKeyword = '';
  final _storeSearchCtrl = TextEditingController();
  final _productSearchCtrl = TextEditingController();
  static const _storesPerPage = 6;

  List<PetStore> get _filteredStores {
    if (_storeKeyword.isEmpty) return _stores;
    return _stores.where((s) => s.name.toLowerCase().contains(_storeKeyword.toLowerCase()) || s.city.toLowerCase().contains(_storeKeyword.toLowerCase())).toList();
  }

  List<Product> _filteredProducts(List<Product> products) {
    if (_productKeyword.isEmpty) return products;
    return products.where((p) => p.name.toLowerCase().contains(_productKeyword.toLowerCase()) || p.category.toLowerCase().contains(_productKeyword.toLowerCase())).toList();
  }

  List<PetStore> get _pagedStores {
    final filtered = _filteredStores;
    final start = _storePage * _storesPerPage;
    return filtered.skip(start).take(_storesPerPage).toList();
  }

  int get _totalStorePages => (_filteredStores.length / _storesPerPage).ceil();

  @override
  void dispose() {
    _storeSearchCtrl.dispose();
    _productSearchCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _stores = await widget.apiClient.listStores(authenticated: true);
      _storeProducts.clear();
      for (final s in _stores) {
        try {
          _storeProducts[s.id] = await widget.apiClient.listStoreProducts(s.id);
        } catch (_) { _storeProducts[s.id] = []; }
      }
    } catch (e) { _error = e.toString(); }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadProducts(String storeId) async {
    try {
      final products = await widget.apiClient.listStoreProducts(storeId);
      if (mounted) setState(() => _storeProducts[storeId] = products);
    } catch (_) {}
  }

  Map<String, List<Product>> _byCategory(List<Product> products) {
    final map = <String, List<Product>>{};
    for (final p in products) {
      final cat = p.category.isNotEmpty ? p.category : '未分类';
      map.putIfAbsent(cat, () => []).add(p);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, size: 48, color: Colors.red), const SizedBox(height: 12),
      Text(_error!, style: const TextStyle(color: Colors.red)), const SizedBox(height: 16),
      ElevatedButton(onPressed: _load, child: const Text('重试')),
    ]));

    final totalProducts = _storeProducts.values.fold(0, (s, l) => s + l.length);

    return ListView(padding: const EdgeInsets.all(24), children: [
      Text('商品管理', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Text('${_filteredStores.length} 家店铺  ·  $totalProducts 件商品', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
      const SizedBox(height: 16),

      // ===== Store Grid with Search =====
      Row(children: [
        Text('选择店铺 (${_stores.length}家)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _storeSearchCtrl,
            decoration: InputDecoration(hintText: '搜索店铺…', isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)), suffixIcon: _storeKeyword.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () { _storeSearchCtrl.clear(); setState(() => _storeKeyword = ''); }) : null),
            onChanged: (v) => setState(() => _storeKeyword = v.trim()),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      if (_stores.isEmpty)
        const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('暂无店铺', style: TextStyle(color: Colors.grey, fontSize: 15))))
      else ...[
        // Grid of stores: 3 per row, 2 rows = 6 per page
        for (var row = 0; row < 2; row++)
          if (row * 3 < _pagedStores.length)
            Padding(
              padding: EdgeInsets.only(bottom: row == 0 ? 10 : 0),
              child: Row(children: [
                for (var col = 0; col < 3; col++)
                  if (row * 3 + col < _pagedStores.length) ...[
                    if (col > 0) const SizedBox(width: 10),
                    Expanded(child: _buildStoreCard(_pagedStores[row * 3 + col])),
                  ] else ...[
                    if (col > 0) const SizedBox(width: 10),
                    const Expanded(child: SizedBox()),
                  ],
              ]),
            ),
        // Pagination
        if (_totalStorePages > 1) ...[
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(icon: const Icon(Icons.chevron_left), onPressed: _storePage > 0 ? () => setState(() => _storePage--) : null),
            Text('${_storePage + 1} / $_totalStorePages', style: const TextStyle(fontSize: 13)),
            IconButton(icon: const Icon(Icons.chevron_right), onPressed: _storePage < _totalStorePages - 1 ? () => setState(() => _storePage++) : null),
          ]),
        ],
      ],

      // ===== Selected Store Products =====
      if (_selectedStore != null) ...[
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Text('${_selectedStore!.name} 的商品', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
          TextButton(onPressed: () => setState(() => _selectedStore = null), child: const Text('收起', style: TextStyle(fontSize: 12))),
        ]),
        // Product search
        TextField(
          controller: _productSearchCtrl,
          decoration: InputDecoration(hintText: '搜索商品名称或分类…', isDense: true, prefixIcon: const Icon(Icons.search, size: 18),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
              suffixIcon: _productKeyword.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () { _productSearchCtrl.clear(); setState(() => _productKeyword = ''); }) : null),
          onChanged: (v) => setState(() => _productKeyword = v.trim()),
        ),
        const SizedBox(height: 8),
        _buildProductList(_selectedStore!.id),
      ],
    ]);
  }

  Widget _buildProductList(String storeId) {
    final products = _filteredProducts(_storeProducts[storeId] ?? []);
    if (products.isEmpty) {
      return const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('该店铺暂无商品', style: TextStyle(color: Colors.grey, fontSize: 14))));
    }
    final grouped = _byCategory(products);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final entry in grouped.entries)
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(width: 3, height: 20, decoration: BoxDecoration(color: const Color(0xFF7A8B3C), borderRadius: BorderRadius.circular(2))),
            title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF7A8B3C))),
            subtitle: Text('${entry.value.length} 件商品', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            initiallyExpanded: grouped.length <= 3,
            children: entry.value.map((p) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _showDetail(p),
                child: Card(
                  color: Colors.grey.shade50,
                  margin: EdgeInsets.zero,
                  child: Padding(padding: const EdgeInsets.all(10), child: Row(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: p.coverUrl.isNotEmpty
                          ? Image.network(p.coverUrl, width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 48, height: 48, color: Colors.grey.shade200, child: const Icon(Icons.image, size: 20, color: Colors.grey)))
                          : Container(width: 48, height: 48, color: Colors.grey.shade200, child: const Icon(Icons.image, size: 20, color: Colors.grey)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 3),
                      Text('${p.type == 'PET_LIVE' ? '活体宠物' : '周边'}  |  ¥${p.price.toStringAsFixed(2)}  |  库存 ${p.stock}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    ])),
                    _badge(p.status == 'ON_SALE' ? '在售' : p.status == 'DRAFT' ? '草稿' : p.status == 'OFF_SALE' ? '下架' : p.status,
                        p.status == 'ON_SALE' ? Colors.green : p.status == 'DRAFT' ? Colors.grey : Colors.orange),
                    const SizedBox(width: 4),
                    if (p.status == 'ON_SALE')
                      IconButton(icon: const Icon(Icons.arrow_downward, size: 16, color: Colors.orange), tooltip: '下架', onPressed: () => _delistProduct(p, storeId), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 28, minHeight: 28)),
                    IconButton(icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red), tooltip: '删除', onPressed: () => _deleteProduct(p), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 28, minHeight: 28)),
                  ])),
                ),
              ),
            )).toList(),
          ),
        ),
    ]);
  }

  void _showDetail(Product p) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text(p.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      content: SizedBox(width: 500, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        // 封面图
        if (p.coverUrl.isNotEmpty)
          ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(p.coverUrl, width: double.infinity, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox(height: 120, child: Center(child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey)))))
        else
          Container(height: 120, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)), child: const Center(child: Icon(Icons.image, size: 40, color: Colors.grey))),
        const SizedBox(height: 16),

        // 基本信息
        _detailRow('类型', p.type == 'PET_LIVE' ? '活体宠物' : '周边商品'),
        _detailRow('分类', p.category.isNotEmpty ? p.category : '未分类'),
        _detailRow('价格', '¥${p.price.toStringAsFixed(2)}'),
        _detailRow('库存', '${p.stock}'),
        _detailRow('状态', p.status == 'ON_SALE' ? '在售' : p.status == 'DRAFT' ? '草稿' : p.status == 'OFF_SALE' ? '下架' : p.status),
        if (p.description.isNotEmpty) ...[const SizedBox(height: 8), Text('描述', style: const TextStyle(fontSize: 12, color: Colors.grey)), const SizedBox(height: 4), Text(p.description, style: const TextStyle(fontSize: 14))],

        // 活体宠物档案
        if (p.isLivePet) ...[
          const SizedBox(height: 16), const Divider(),
          const Text('活体宠物档案', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          if (p.livePet?['petCode']?.toString().isNotEmpty == true) _detailRow('宠物编号', p.livePet!['petCode'].toString()),
          if (p.livePet?['breed']?.toString().isNotEmpty == true) _detailRow('品种', p.livePet!['breed'].toString()),
          if (p.livePet?['healthStatus']?.toString().isNotEmpty == true) _detailRow('健康状态', p.livePet!['healthStatus'].toString()),
          if (p.livePet?['vaccineCertNo']?.toString().isNotEmpty == true) _detailRow('疫苗证明', p.livePet!['vaccineCertNo'].toString()),
          if (p.livePet?['quarantineCertNo']?.toString().isNotEmpty == true) _detailRow('检疫证明', p.livePet!['quarantineCertNo'].toString()),
          if (p.livePet?['traceSource']?.toString().isNotEmpty == true) _detailRow('溯源信息', p.livePet!['traceSource'].toString()),
        ],
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭'))],
    ));
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 70, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
      ]),
    );
  }

  Widget _buildStoreCard(PetStore s) {
    final selected = _selectedStore?.id == s.id;
    return Card(
      color: selected ? const Color(0xFF7A8B3C).withAlpha(15) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: selected ? const Color(0xFF7A8B3C) : Colors.grey.shade200, width: selected ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          setState(() => _selectedStore = s);
          _loadProducts(s.id);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Row(children: [
            CircleAvatar(radius: 20, backgroundColor: s.status == 'OPEN' ? Colors.green.withAlpha(30) : Colors.red.withAlpha(30),
                child: Icon(Icons.store, size: 20, color: s.status == 'OPEN' ? Colors.green : Colors.red)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text('${_storeProducts[s.id]?.length ?? 0} 件商品  ·  ${s.city}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)));
  }

  // ---- 下架商品并通知店主 ----
  Future<void> _delistProduct(Product p, String storeId) async {
    final reasonCtrl = TextEditingController();
    final result = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: Text('下架商品 — ${p.name}'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('请填写下架原因，将自动通知对应店长。', style: TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 12),
        TextField(controller: reasonCtrl, maxLines: 3, decoration: const InputDecoration(hintText: '下架原因', border: OutlineInputBorder())),
      ]),
      actions: [
        TextButton(onPressed: () { reasonCtrl.dispose(); Navigator.pop(context, false); }, child: const Text('取消')),
        ElevatedButton(onPressed: () { reasonCtrl.dispose(); Navigator.pop(context, true); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white), child: const Text('确认下架')),
      ],
    ));
    if (result != true) return;
    try {
      await widget.apiClient.updateProduct(p.id, {'status': 'OFF_SALE'});
      // 通知店主
      final store = _stores.firstWhere((s) => s.id == storeId);
      if (store.ownerUserId.isNotEmpty) {
        final uid = int.tryParse(store.ownerUserId);
        if (uid != null) {
          await widget.apiClient.createAnnouncement({
            'title': '商品下架通知 — ${p.name}',
            'content': '您的商品「${p.name}」已被管理员下架。原因：${reasonCtrl.text.trim().isEmpty ? "违反平台规定" : reasonCtrl.text.trim()}。如有疑问请联系平台客服。',
            'targetUserId': uid,
          });
        }
      }
      await _loadProducts(storeId);
      if (mounted) showSuccess(context, '已下架并通知店长');
    } catch (e) { if (mounted) showError(context, e.toString()); }
  }

  Future<void> _deleteProduct(Product p) async {
    final ok = await showConfirmDialog(context, title: '删除商品', message: '确定删除"${p.name}"？', confirmLabel: '删除', destructive: true);
    if (!ok) return;
    try { await widget.apiClient.deleteProduct(p.id); if (_selectedStore != null) await _loadProducts(_selectedStore!.id); if (mounted) showSuccess(context, '已删除'); }
    catch (e) { if (mounted) showError(context, e.toString()); }
  }
}
