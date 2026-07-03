import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/product.dart';
import '../../../models/store.dart';
import '../product/product_detail_page.dart';

class StoreDetailPage extends StatefulWidget {
  const StoreDetailPage({required this.apiClient, required this.store, super.key});
  final ApiClient apiClient;
  final PetStore store;

  @override
  State<StoreDetailPage> createState() => _StoreDetailPageState();
}

class _StoreDetailPageState extends State<StoreDetailPage> {
  bool loading = true;
  String? errorText;
  List<Product> products = [];

  @override
  void initState() { super.initState(); loadProducts(); }

  Future<void> loadProducts() async {
    setState(() { loading = true; errorText = null; });
    try {
      products = await widget.apiClient.listProducts();
      products = products.where((p) => p.storeId == widget.store.id).toList();
    } catch (e) { errorText = e.toString(); }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = widget.store;
    return Scaffold(
      backgroundColor: PawmartColors.surfaceBg,
      appBar: AppBar(title: Text(store.name)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // 店铺头图卡片
        Card(
          child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
            CircleAvatar(radius: 40, backgroundColor: PawmartColors.primary50,
              child: Icon(Icons.store, size: 40, color: PawmartColors.primary500)),
            const SizedBox(height: 12),
            Text(store.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _tag(store.status == 'OPEN' ? '营业中' : '已关闭', store.status == 'OPEN' ? Colors.green : Colors.red),
              const SizedBox(width: 8),
              const Icon(Icons.star, size: 16, color: Colors.amber),
              const SizedBox(width: 2),
              Text('${store.rating.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.w600)),
            ]),
          ])),
        ),
        const SizedBox(height: 16),
        // 基本信息
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('基本信息', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const Divider(height: 20),
          _infoRow(Icons.location_on, '地址', store.address),
          _infoRow(Icons.map, '区域', '${store.city} ${store.district}'),
          if (store.phone.isNotEmpty) _infoRow(Icons.phone, '电话', store.phone),
          if (store.businessHours.isNotEmpty) _infoRow(Icons.access_time, '营业时间', store.businessHours),
          if (store.featureTags.isNotEmpty) _infoRow(Icons.tag, '特色', store.featureTags),
          _infoRow(Icons.pin_drop, '坐标', '${store.longitude.toStringAsFixed(4)}, ${store.latitude.toStringAsFixed(4)}'),
        ]))),
        const SizedBox(height: 16),
        // 在售商品
        Row(children: [
          Icon(Icons.inventory_2, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text('在售商品', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const Spacer(),
          Text('${products.length} 件', style: theme.textTheme.bodySmall),
        ]),
        const SizedBox(height: 10),
        if (loading)
          const Center(child: Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator()))
        else if (errorText != null)
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(errorText!)))
        else if (products.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('暂无在售商品')))
        else
          ...products.map((p) => Card(
            child: ListTile(
              leading: Icon(p.isLivePet ? Icons.pets : Icons.shopping_bag, color: theme.colorScheme.primary),
              title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${p.category}  ·  ¥${p.price.toStringAsFixed(2)}  ·  库存 ${p.stock}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => ProductDetailPage(apiClient: widget.apiClient, product: p),
              )),
            ),
          )),
      ]),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)));
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(
      children: [
        Icon(icon, size: 18, color: PawmartColors.textSecondary),
        const SizedBox(width: 10),
        SizedBox(width: 60, child: Text(label, style: TextStyle(fontSize: 13, color: PawmartColors.textSecondary))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
      ],
    ));
  }
}
