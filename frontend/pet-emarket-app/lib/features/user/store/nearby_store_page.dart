import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../models/product.dart';

class NearbyStorePage extends StatefulWidget {
  const NearbyStorePage({required this.apiClient, super.key});
  final ApiClient apiClient;

  @override
  State<NearbyStorePage> createState() => _NearbyStorePageState();
}

class _NearbyStorePageState extends State<NearbyStorePage> {
  bool loading = true;
  String? errorText;
  List<Product> products = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() { loading = true; errorText = null; });
    try {
      // TODO: Replace with /api/v1/stores/nearby when LBS service is ready
      final all = await widget.apiClient.listProducts(keyword: '');
      products = all.where((p) => p.status == 'ON_SALE').toList();
    } catch (e) {
      errorText = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('附近宠物商店')),
      body: RefreshIndicator(
        onRefresh: loadData,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : errorText != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                        const SizedBox(height: 12),
                        Text(errorText!, style: TextStyle(color: theme.colorScheme.error)),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: loadData, child: const Text('重试')),
                      ],
                    ),
                  )
                : products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.store_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(height: 12),
                            const Text('附近暂无商店或商品'),
                            const SizedBox(height: 8),
                            Text('LBS 服务接入后将展示附近宠物商店', style: theme.textTheme.bodySmall),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: products.length,
                        itemBuilder: (ctx, i) {
                          final p = products[i];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: theme.colorScheme.primaryContainer,
                                child: Icon(p.isLivePet ? Icons.pets : Icons.store, color: theme.colorScheme.primary),
                              ),
                              title: Text(p.name),
                              subtitle: Text(p.category + '  |  ¥' + p.price.toStringAsFixed(2) + '  |  库存 ' + p.stock.toString()),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => Scaffold(
                                    appBar: AppBar(title: Text(p.name)),
                                    body: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(p.description.isNotEmpty ? p.description : '暂无描述'),
                                          const SizedBox(height: 12),
                                          Text('分类: ' + p.category + '  |  价格: ¥' + p.price.toStringAsFixed(2) + '  |  库存: ' + p.stock.toString()),
                                          if (p.livePet != null) ...[
                                            const Divider(height: 24),
                                            const Text('活体档案', style: TextStyle(fontWeight: FontWeight.w700)),
                                            Text('编号: ' + (p.livePet!['petCode']?.toString() ?? '-')),
                                            Text('健康: ' + (p.livePet!['healthStatus']?.toString() ?? '-')),
                                            Text('疫苗: ' + (p.livePet!['vaccineCertNo']?.toString() ?? '-')),
                                            Text('检疫: ' + (p.livePet!['quarantineCertNo']?.toString() ?? '-')),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ));
                              },
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

