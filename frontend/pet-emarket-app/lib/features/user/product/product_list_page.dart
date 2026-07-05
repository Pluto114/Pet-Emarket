/// 商品列表页 — 参照原型图：侧边筛选栏 + 商品网格 + 分页
library;

import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/product.dart';
import '../../../shared/widgets/toast.dart';
import 'product_detail_page.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({required this.apiClient, super.key});
  final ApiClient apiClient;

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  bool loading = true;
  String? errorText;
  List<Product> allProducts = [];
  List<Product> filteredProducts = [];

  // Filter state
  String _petType = '全部';
  final Set<String> _selectedPriceRanges = {};
  final Set<String> _selectedCategories = {};
  String _sortBy = '综合排序';

  final _searchCtrl = TextEditingController();

  // Pagination
  int _currentPage = 1;
  static const int _pageSize = 9;
  int get _totalPages => (filteredProducts.length / _pageSize).ceil();
  List<Product> get _pagedProducts {
    final start = (_currentPage - 1) * _pageSize;
    if (start >= filteredProducts.length) return [];
    final end = (start + _pageSize).clamp(0, filteredProducts.length);
    return filteredProducts.sublist(start, end);
  }

  List<String> get _categories {
    final categories = allProducts.map((p) => p.category.trim()).where((c) => c.isNotEmpty).toSet().toList()..sort();
    return categories;
  }

  static const _petTypes = ['全部', '狗狗', '猫猫'];
  static const _priceRanges = ['¥0-50', '¥50-100', '¥100-200', '¥200+'];
  static const _sortOptions = ['综合排序', '价格升序', '价格降序', '销量优先'];

  @override
  void initState() { super.initState(); load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> load() async {
    setState(() { loading = true; errorText = null; });
    try {
      allProducts = await widget.apiClient.listProducts(keyword: _searchCtrl.text);
      _applyFilters();
    } catch (e) {
      errorText = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _applyFilters() {
    var list = List<Product>.from(allProducts);
    if (_petType == '狗狗') {
      list = list.where((p) => p.category.contains('狗') || p.category.toLowerCase().contains('dog')).toList();
    } else if (_petType == '猫猫') {
      list = list.where((p) => p.category.contains('猫') || p.category.toLowerCase().contains('cat')).toList();
    }
    if (_selectedPriceRanges.isNotEmpty) {
      list = list.where((p) {
        final price = p.price;
        return _selectedPriceRanges.any((range) {
          switch (range) {
            case '¥0-50': return price <= 50;
            case '¥50-100': return price > 50 && price <= 100;
            case '¥100-200': return price > 100 && price <= 200;
            case '¥200+': return price > 200;
            default: return true;
          }
        });
      }).toList();
    }
    if (_selectedCategories.isNotEmpty) {
      list = list.where((p) => _selectedCategories.contains(p.category)).toList();
    }
    switch (_sortBy) {
      case '价格升序': list.sort((a, b) => a.price.compareTo(b.price));
      case '价格降序': list.sort((a, b) => b.price.compareTo(a.price));
      case '销量优先': list.sort((a, b) => (b.stock).compareTo(a.stock));
      default: break;
    }
    filteredProducts = list;
    _currentPage = 1;
  }

  void _resetFilters() {
    setState(() {
      _petType = '全部';
      _selectedPriceRanges.clear();
      _selectedCategories.clear();
      _sortBy = '综合排序';
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final wide = w > 900;
    return Scaffold(
      backgroundColor: PawmartColors.surfaceBg,
      body: Column(children: [
        // Main Content
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : errorText != null
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(errorText!, style: TextStyle(color: PawmartColors.error)),
                      const SizedBox(height: 8),
                      OutlinedButton(onPressed: load, child: const Text('重试')),
                    ]))
                  : wide ? _wideLayout(wide) : _narrowLayout(wide),
        ),
      ]),
    );
  }

  // Wide: Sidebar + Grid
  Widget _wideLayout(bool wide) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 280, child: _buildSidebar()),
      Container(width: 1, color: PawmartColors.neutral200),
      Expanded(child: _buildContent(wide)),
    ]);
  }

  // Narrow: Filter bar + Grid
  Widget _narrowLayout(bool wide) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: PawmartColors.surfaceCard, border: Border(bottom: BorderSide(color: PawmartColors.neutral200))),
        child: Column(children: [
          SizedBox(
            height: 36,
            child: TextField(
              controller: _searchCtrl, onSubmitted: (_) => load(),
              decoration: InputDecoration(
                filled: true, fillColor: PawmartColors.neutral50, isDense: true,
                hintText: '搜索商品…', hintStyle: TextStyle(fontSize: 13, color: PawmartColors.textSecondary),
                prefixIcon: Icon(Icons.search_rounded, size: 18, color: PawmartColors.neutral400),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(pawmartRadiusFull), borderSide: BorderSide(color: PawmartColors.neutral200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(pawmartRadiusFull), borderSide: BorderSide(color: PawmartColors.primary500, width: 1.5)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Text('共 ${filteredProducts.length} 件', style: TextStyle(fontSize: 13, color: PawmartColors.textSecondary)),
            const Spacer(),
            _sortDropdown(isCompact: true),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _showFilterSheet, icon: const Icon(Icons.tune, size: 16), label: const Text('筛选'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), minimumSize: const Size(0, 32), side: BorderSide(color: PawmartColors.neutral200)),
            ),
          ]),
        ]),
      ),
      Expanded(child: _buildContent(wide)),
    ]);
  }

  // Sidebar Filter Panel
  Widget _buildSidebar() {
    return ListView(padding: const EdgeInsets.all(20), children: [
      _filterSectionTitle('宠物类型'),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: _petTypes.map((type) {
        final active = _petType == type;
        return _filterChip(type, active: active, onTap: () => setState(() { _petType = active ? '全部' : type; _applyFilters(); }));
      }).toList()),
      const SizedBox(height: 24),
      _filterSectionTitle('价格区间'),
      const SizedBox(height: 8),
      ..._priceRanges.map((r) => _checkboxRow(r, checked: _selectedPriceRanges.contains(r), onChanged: (v) => setState(() { if (v) _selectedPriceRanges.add(r); else _selectedPriceRanges.remove(r); _applyFilters(); }))),
      const SizedBox(height: 24),
      _filterSectionTitle('类别'),
      const SizedBox(height: 8),
      ..._categories.take(8).map((b) => _checkboxRow(b, checked: _selectedCategories.contains(b), onChanged: (v) => setState(() { if (v) _selectedCategories.add(b); else _selectedCategories.remove(b); _applyFilters(); }))),
      const SizedBox(height: 24),
      _filterSectionTitle('排序方式'),
      const SizedBox(height: 8),
      _sortDropdown(),
      const SizedBox(height: 20),
      GestureDetector(
        onTap: _resetFilters,
        child: Text('重置筛选', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: PawmartColors.primary500, decoration: TextDecoration.underline, decorationColor: PawmartColors.primary500)),
      ),
    ]);
  }

  Widget _filterSectionTitle(String t) => Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: PawmartColors.textSecondary));

  Widget _filterChip(String label, {required bool active, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(pawmartRadiusFull),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: active ? PawmartColors.accent400 : Colors.transparent,
          border: Border.all(color: active ? PawmartColors.accent400 : PawmartColors.neutral200),
          borderRadius: BorderRadius.circular(pawmartRadiusFull),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? PawmartColors.textOnAccent : PawmartColors.textPrimary)),
      ),
    );
  }

  Widget _checkboxRow(String label, {required bool checked, required ValueChanged<bool> onChanged}) {
    return InkWell(
      onTap: () => onChanged(!checked), borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          SizedBox(width: 20, height: 20, child: Checkbox(value: checked, onChanged: (v) => onChanged(v ?? false), activeColor: PawmartColors.primary500, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 14, color: PawmartColors.textPrimary)),
        ]),
      ),
    );
  }

  Widget _sortDropdown({bool isCompact = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(border: Border.all(color: PawmartColors.neutral200), borderRadius: BorderRadius.circular(pawmartRadiusSm)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sortOptions.contains(_sortBy) ? _sortBy : '综合排序', isDense: true,
          style: TextStyle(fontSize: 14, color: PawmartColors.textPrimary),
          items: _sortOptions.map((o) => DropdownMenuItem(value: o, child: Text(o, style: TextStyle(fontSize: 14)))).toList(),
          onChanged: (v) { if (v != null) setState(() { _sortBy = v; _applyFilters(); }); },
        ),
      ),
    );
  }

  // Bottom sheet filter for narrow screens
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(pawmartRadiusLg))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.7, maxChildSize: 0.9, minChildSize: 0.4, expand: false,
          builder: (_, scrollCtrl) => ListView(controller: scrollCtrl, padding: const EdgeInsets.fromLTRB(20, 8, 20, 32), children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: PawmartColors.neutral300, borderRadius: BorderRadius.circular(2)))),
            Row(children: [const Text('筛选条件', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: PawmartColors.textPrimary)), const Spacer(), TextButton(onPressed: () { setState(() => _resetFilters()); setModalState(() {}); Navigator.pop(ctx); }, child: const Text('重置', style: TextStyle(fontWeight: FontWeight.w600)))]),
            const SizedBox(height: 20),
            _filterSectionTitle('宠物类型'), const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: _petTypes.map((t) { final a = _petType == t; return _filterChip(t, active: a, onTap: () { setModalState(() {}); setState(() { _petType = a ? '全部' : t; _applyFilters(); }); }); }).toList()),
            const SizedBox(height: 24),
            _filterSectionTitle('价格区间'), const SizedBox(height: 8),
            ..._priceRanges.map((r) => _checkboxRow(r, checked: _selectedPriceRanges.contains(r), onChanged: (v) { setModalState(() {}); setState(() { if (v) _selectedPriceRanges.add(r); else _selectedPriceRanges.remove(r); _applyFilters(); }); })),
            const SizedBox(height: 24),
            _filterSectionTitle('类别'), const SizedBox(height: 8),
            ..._categories.take(8).map((b) => _checkboxRow(b, checked: _selectedCategories.contains(b), onChanged: (v) { setModalState(() {}); setState(() { if (v) _selectedCategories.add(b); else _selectedCategories.remove(b); _applyFilters(); }); })),
            const SizedBox(height: 24),
            _filterSectionTitle('排序方式'), const SizedBox(height: 8),
            _sortDropdown(),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 44, child: FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('确认', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)))),
          ]),
        ),
      ),
    );
  }

  // Content: result count + grid + pagination
  Widget _buildContent(bool wide) {
    if (filteredProducts.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.inventory_2_outlined, size: 56, color: PawmartColors.neutral300),
        const SizedBox(height: 16),
        Text('没有找到符合条件的商品', style: TextStyle(fontSize: 16, color: PawmartColors.textSecondary)),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: _resetFilters, child: const Text('重置筛选条件')),
      ]));
    }
    return ListView(padding: EdgeInsets.fromLTRB(wide ? 24 : 16, 16, wide ? 24 : 16, 16), children: [
      if (wide)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            Text('共 ${filteredProducts.length} 件商品', style: TextStyle(fontSize: 14, color: PawmartColors.textSecondary)),
            const Spacer(), _sortDropdown(),
          ]),
        ),
      GridView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: wide ? 3 : 2, childAspectRatio: 0.58, mainAxisSpacing: 16, crossAxisSpacing: 16),
        itemCount: _pagedProducts.length,
        itemBuilder: (_, i) => _productCard(_pagedProducts[i]),
      ),
      if (_totalPages > 1) ...[const SizedBox(height: 24), _buildPagination()],
    ]);
  }

  // Product Card (prototype style: image, name, desc, price, two buttons)
  Widget _productCard(Product product) {
    final colors = [PawmartColors.primary100, PawmartColors.accent50, PawmartColors.neutral100, PawmartColors.primary50];
    final isOos = product.stock <= 0;
    return Container(
      decoration: BoxDecoration(color: PawmartColors.surfaceCard, borderRadius: BorderRadius.circular(pawmartRadiusMd), border: Border.all(color: PawmartColors.neutral200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(product: product, apiClient: widget.apiClient))),
          child: Container(
            height: 200,
            decoration: BoxDecoration(color: colors[product.category.hashCode.abs() % colors.length], borderRadius: const BorderRadius.vertical(top: Radius.circular(pawmartRadiusMd))),
            child: Stack(fit: StackFit.expand, children: [
              if (product.coverUrl.isNotEmpty)
                ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(pawmartRadiusMd)), child: Image.network(product.coverUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _productIcon(product)))
              else
                _productIcon(product),
              if (isOos) Container(alignment: Alignment.center, color: Colors.black.withAlpha(100), child: const Text('已售罄', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: PawmartColors.textPrimary)),
            const SizedBox(height: 6),
            Text(product.description.isNotEmpty ? product.description : '暂无描述', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: PawmartColors.textSecondary, height: 1.4)),
            const SizedBox(height: 8),
            Text('¥${product.price.toStringAsFixed(0)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: PawmartColors.primary500)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: SizedBox(height: 34, child: FilledButton(
                onPressed: !isOos ? () => _addToCart(product) : null,
                style: FilledButton.styleFrom(backgroundColor: isOos ? PawmartColors.neutral200 : PawmartColors.accent400, foregroundColor: isOos ? PawmartColors.neutral400 : PawmartColors.textOnAccent, padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(pawmartRadiusSm)), textStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                child: Text(isOos ? '已售罄' : '加入购物车'),
              ))),
              const SizedBox(width: 8),
              Expanded(child: SizedBox(height: 34, child: OutlinedButton(
                onPressed: !isOos ? () => _addToCart(product, checkoutHint: true) : null,
                style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, side: BorderSide(color: isOos ? PawmartColors.neutral300 : PawmartColors.neutral200), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(pawmartRadiusSm)), textStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                child: const Text('立即购买'),
              ))),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _productIcon(Product product) => Center(child: Icon(product.isLivePet ? Icons.pets : Icons.shopping_bag_outlined, size: 48, color: PawmartColors.primary300));

  // Pagination
  Widget _buildPagination() {
    final pages = <Widget>[];
    pages.add(_pageBtn(child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.chevron_left, size: 16), Text('上一页', style: TextStyle(fontSize: 13))]), onTap: _currentPage > 1 ? () => setState(() => _currentPage--) : null, outlined: true));
    final maxShow = 5;
    var start = (_currentPage - maxShow ~/ 2).clamp(1, _totalPages - maxShow + 1);
    if (_totalPages <= maxShow) start = 1;
    final end = (start + maxShow - 1).clamp(0, _totalPages);
    if (start > 1) { pages.add(_pageNum(1)); if (start > 2) pages.add(const Text('…', style: TextStyle(color: PawmartColors.textSecondary))); }
    for (var i = start; i <= end; i++) { pages.add(_pageNum(i)); }
    if (end < _totalPages) { if (end < _totalPages - 1) pages.add(const Text('…', style: TextStyle(color: PawmartColors.textSecondary))); pages.add(_pageNum(_totalPages)); }
    pages.add(_pageBtn(child: const Row(mainAxisSize: MainAxisSize.min, children: [Text('下一页', style: TextStyle(fontSize: 13)), Icon(Icons.chevron_right, size: 16)]), onTap: _currentPage < _totalPages ? () => setState(() => _currentPage++) : null, outlined: true));
    return Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: pages);
  }

  Widget _pageNum(int page) {
    final active = page == _currentPage;
    return _pageBtn(child: Text('$page', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: active ? PawmartColors.textOnPrimary : PawmartColors.textPrimary)), onTap: active ? null : () => setState(() => _currentPage = page), filled: active);
  }

  Widget _pageBtn({required Widget child, VoidCallback? onTap, bool filled = false, bool outlined = false}) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(pawmartRadiusFull),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: filled ? PawmartColors.primary500 : Colors.transparent, border: (outlined || !filled) ? Border.all(color: PawmartColors.neutral200) : null, borderRadius: BorderRadius.circular(pawmartRadiusFull)), child: child),
    );
  }

  Future<void> _addToCart(Product product, {bool checkoutHint = false}) async {
    try {
      await widget.apiClient.addCartItem(productId: product.id, quantity: 1);
      if (mounted) showSuccess(context, checkoutHint ? '${product.name} 已加入购物车，请到购物车结算' : '${product.name} 已加入购物车');
    } catch (e) {
      if (mounted) showError(context, e.toString());
    }
  }
}
