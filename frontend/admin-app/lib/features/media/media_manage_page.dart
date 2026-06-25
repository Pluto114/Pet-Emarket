import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class MediaManagePage extends StatelessWidget {
  const MediaManagePage({required this.apiClient, super.key});
  final ApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      Text('媒体管理', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 20),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.videocam, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            const Text('媒体管理功能将在云存储接入后开放', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('届时支持商品图片/视频上传、审核、管理等功能', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ]),
        ),
      ),
    ]);
  }
}

