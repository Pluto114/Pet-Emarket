import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class StoreManagePage extends StatelessWidget {
  const StoreManagePage({required this.apiClient, super.key});
  final ApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      Text('商店管理', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 20),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.store, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            const Text('商店管理功能将在 LBS 服务接入后开放', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('届时支持附近商店搜索、商店信息管理、经纬度配置等功能', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ]),
        ),
      ),
    ]);
  }
}

