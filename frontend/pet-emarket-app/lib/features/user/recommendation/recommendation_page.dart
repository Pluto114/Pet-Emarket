import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../models/product.dart';

class RecommendationPage extends StatefulWidget {
  const RecommendationPage({required this.apiClient, super.key});
  final ApiClient apiClient;

  @override
  State<RecommendationPage> createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> {
  bool loading = true;
  String? errorText;
  List<RecommendItem> items = [];

  @override
  void initState() {
    super.initState();
    loadRecommendations();
  }

  Future<void> loadRecommendations() async {
    setState(() { loading = true; errorText = null; });
    try {
      // TODO: Replace with /api/v1/recommend when AI service is ready
      final products = await widget.apiClient.listProducts(keyword: '');
      final reasons = [
        '根据你最近浏览的宠物用品推荐',
        '热门商品，大家都在买',
        '新用户专享推荐',
        '根据你的会员等级精选',
        '与你的购物车商品搭配',
        '近期销量最高的商品',
      ];
      items = products.where((p) => p.status == 'ON_SALE').take(8).toList().asMap().entries.map((e) {
        return RecommendItem(
          product: e.value,
          score: 0.85 + (e.key * 0.01),
          reason: reasons[e.key % reasons.length],
        );
      }).toList();
      items.sort((a, b) => b.score.compareTo(a.score));
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
                                              label: Text('匹配度 ' + (item.score * 100).toInt().toString() + '%', style: const TextStyle(fontSize: 11)),
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
                                              child: Text(item.reason, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic)),
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
                        },
                      ),
      ),
    );
  }
}

class RecommendItem {
  final Product product;
  final double score;
  final String reason;
  const RecommendItem({required this.product, required this.score, required this.reason});
}

