import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../models/store.dart';

class NearbyStorePage extends StatefulWidget {
  const NearbyStorePage({required this.apiClient, super.key});
  final ApiClient apiClient;

  @override
  State<NearbyStorePage> createState() => _NearbyStorePageState();
}

class _NearbyStorePageState extends State<NearbyStorePage> {
  bool loading = true;
  String? errorText;
  List<PetStore> stores = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() { loading = true; errorText = null; });
    try {
      stores = await widget.apiClient.nearbyStores();
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
                : stores.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.store_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(height: 12),
                            const Text('附近暂无商店'),
                            const SizedBox(height: 8),
                            Text('可稍后扩大搜索半径或检查定位信息', style: theme.textTheme.bodySmall),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: stores.length,
                        itemBuilder: (ctx, i) {
                          final store = stores[i];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: theme.colorScheme.primaryContainer,
                                child: Icon(Icons.store, color: theme.colorScheme.primary),
                              ),
                              title: Text(store.name),
                              subtitle: Text(store.district + '  |  评分 ' + store.rating.toStringAsFixed(1) + (store.distanceKm == null ? '' : '  |  ' + store.distanceKm!.toStringAsFixed(2) + 'km')),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => Scaffold(
                                    appBar: AppBar(title: Text(store.name)),
                                    body: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(store.address),
                                          const SizedBox(height: 12),
                                          Text('城市: ' + store.city + '  |  区域: ' + store.district),
                                          const SizedBox(height: 8),
                                          Text('营业: ' + (store.businessHours.isEmpty ? '-' : store.businessHours)),
                                          const SizedBox(height: 8),
                                          Text('电话: ' + (store.phone.isEmpty ? '-' : store.phone)),
                                          const SizedBox(height: 8),
                                          Text('特色: ' + (store.featureTags.isEmpty ? '-' : store.featureTags)),
                                          const SizedBox(height: 8),
                                          Text('坐标: ' + store.longitude.toStringAsFixed(4) + ', ' + store.latitude.toStringAsFixed(4)),
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

