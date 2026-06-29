import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../models/recommendation.dart';

class RecommendationPage extends StatefulWidget {
  const RecommendationPage({required this.apiClient, super.key});
  final ApiClient apiClient;

  @override
  State<RecommendationPage> createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> {
  bool loading = true;
  String? errorText;
  List<RecommendationItem> items = [];

  @override
  void initState() {
    super.initState();
    loadRecommendations();
  }

  Future<void> loadRecommendations() async {
    setState(() { loading = true; errorText = null; });
    try {
      items = await widget.apiClient.recommendations(scene: 'HOME', limit: 8);
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
      appBar: AppBar(title: const Text('为你推荐')),
      body: RefreshIndicator(
        onRefresh: loadRecommendations,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : errorText != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                        const SizedBox(height: 12),
                        Text(errorText!),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: loadRecommendations, child: const Text('重试')),
                      ],
                    ),
                  )
                : items.isEmpty
                    ? const Center(child: Text('暂无推荐商品'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        itemBuilder: (ctx, i) {
                          final item = items[i];
                          final p = item.product;
                          final reason = item.reasons.isEmpty ? item.strategy : item.reasons.first;
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Icon(p.isLivePet ? Icons.pets : Icons.shopping_bag_outlined, size: 36, color: theme.colorScheme.primary),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                        const SizedBox(height: 4),
                                        Text(p.description.isNotEmpty ? p.description : p.category, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Text('¥' + p.price.toStringAsFixed(2), style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w700, fontSize: 16)),
                                            const SizedBox(width: 12),
                                            Chip(
                                              label: Text('推荐分 ' + item.score.toStringAsFixed(1), style: const TextStyle(fontSize: 11)),
                                              backgroundColor: theme.colorScheme.primaryContainer,
                                              padding: EdgeInsets.zero,
                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.lightbulb_outline, size: 14, color: theme.colorScheme.onSurfaceVariant),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(reason, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic)),
                                            ),
                                          ],
                                        ),
                                        if (item.reasons.length > 1) ...[
                                          const SizedBox(height: 4),
                                          Text(item.reasons.skip(1).join(' · '), maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
