import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/skeleton_loader.dart';

class AnnouncementPage extends StatefulWidget {
  const AnnouncementPage({required this.apiClient, super.key});
  final ApiClient apiClient;
  @override
  State<AnnouncementPage> createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<AnnouncementPage> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() { loading = true; error = null; });
    try {
      items = await widget.apiClient.listAnnouncements();
    } catch (e) {
      error = e.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final wide = w > 800;

    return Scaffold(
      backgroundColor: PawmartColors.surfaceBg,
      appBar: AppBar(
        title: const Text('公告'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: '刷新',
            onPressed: load,
          ),
        ],
      ),
      body: _buildBody(wide),
    );
  }

  Widget _buildBody(bool wide) {
    // Loading state
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: SkeletonLoader(count: 5, height: 100.0),
      );
    }

    // Error state
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: PawmartColors.accent50,
                  borderRadius: BorderRadius.circular(pawmartRadiusFull),
                ),
                child: Icon(Icons.wifi_off_rounded, size: 36, color: PawmartColors.accent500),
              ),
              const SizedBox(height: 16),
              Text(
                '加载失败',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: PawmartColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error!,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: PawmartColors.textSecondary),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: load,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('重试'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(140, 40),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: PawmartColors.neutral100,
                  borderRadius: BorderRadius.circular(pawmartRadiusFull),
                ),
                child: Icon(
                  Icons.campaign_outlined,
                  size: 48,
                  color: PawmartColors.neutral400,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '暂无公告',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: PawmartColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '管理员还没有发布任何公告\n有新公告时会第一时间在这里展示',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: PawmartColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Data state
    return RefreshIndicator(
      color: PawmartColors.primary500,
      onRefresh: load,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: wide ? 200 : 16,
          vertical: 16,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) => _buildCard(items[i], i, items.length),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> a, int index, int total) {
    return Container(
      margin: EdgeInsets.only(bottom: index < total - 1 ? 12 : 0),
      decoration: BoxDecoration(
        color: PawmartColors.surfaceCard,
        borderRadius: BorderRadius.circular(pawmartRadiusLg),
        boxShadow: pawmartShadow1,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDetail(a),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: PawmartColors.primary50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.campaign,
                        size: 20,
                        color: PawmartColors.primary500,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a['title']?.toString() ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: PawmartColors.textPrimary,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(a['createdAt']?.toString() ?? ''),
                            style: TextStyle(
                              fontSize: 12,
                              color: PawmartColors.neutral400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: PawmartColors.neutral300,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Content preview
                Text(
                  a['content']?.toString() ?? '',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: PawmartColors.textSecondary,
                    height: 1.65,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetail(Map<String, dynamic> a) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(pawmartRadiusLg),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: PawmartColors.primary50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.campaign,
                size: 18,
                color: PawmartColors.primary500,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                a['title']?.toString() ?? '',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  a['content']?.toString() ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    color: PawmartColors.textSecondary,
                    height: 1.75,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: PawmartColors.neutral50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: PawmartColors.neutral400),
                      const SizedBox(width: 8),
                      Text(
                        '发布于 ${_formatTime(a['createdAt']?.toString() ?? '')}',
                        style: TextStyle(
                          fontSize: 13,
                          color: PawmartColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  String _formatTime(String t) {
    try {
      final d = DateTime.parse(t);
      final now = DateTime.now();
      final diff = now.difference(d);

      if (diff.inMinutes < 1) return '刚刚';
      if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
      if (diff.inHours < 24) return '${diff.inHours} 小时前';
      if (diff.inDays < 7) return '${diff.inDays} 天前';

      return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')} '
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
