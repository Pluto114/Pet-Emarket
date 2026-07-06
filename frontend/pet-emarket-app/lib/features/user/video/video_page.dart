import 'package:flutter/material.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/media_asset.dart';
import '../../../../shared/widgets/web_helpers_stub.dart'
    if (dart.library.html) '../../../../shared/widgets/web_helpers_web.dart';
import '../../../../shared/widgets/video_factory_stub.dart'
    if (dart.library.html) '../../../../shared/widgets/video_factory_web.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({required this.apiClient, super.key});
  final ApiClient apiClient;

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  bool loading = true;
  String? errorText;
  List<MediaAsset> videos = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() { loading = true; errorText = null; });
    try {
      final all = await widget.apiClient.listMedia(authenticated: true);
      videos = all.where((m) => m.mediaType == 'VIDEO' && m.status == 'APPROVED').toList();
    } catch (e) {
      errorText = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final wide = w > 800;
    final crossAxisCount = wide ? 3 : 2;

    return Scaffold(
      backgroundColor: PawmartColors.surfaceBg,
      appBar: AppBar(title: const Text('宠物视频')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorText != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.error_outline, size: 48, color: PawmartColors.error),
                  const SizedBox(height: 12),
                  Text(errorText!, style: TextStyle(color: PawmartColors.error)),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: load, child: const Text('重试')),
                ]))
              : videos.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.videocam_off_outlined, size: 64, color: PawmartColors.neutral300),
                      const SizedBox(height: 16),
                      Text('暂无视频', style: TextStyle(fontSize: 16, color: PawmartColors.textSecondary)),
                    ]))
                  : GridView.builder(
                      padding: EdgeInsets.all(wide ? 24 : 14),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 1.6,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                      ),
                      itemCount: videos.length,
                      itemBuilder: (_, i) => _videoCard(videos[i]),
                    ),
    );
  }

  Widget _videoCard(MediaAsset video) {
    return GestureDetector(
      onTap: () => _playVideo(video),
      child: Container(
        decoration: BoxDecoration(
          color: PawmartColors.neutral900,
          borderRadius: BorderRadius.circular(pawmartRadiusMd),
          boxShadow: pawmartShadow1,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (video.coverUrl.isNotEmpty)
              Image.network(video.coverUrl, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            else
              _placeholder(),
            // gradient
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withAlpha(200), Colors.transparent],
                  ),
                ),
              ),
            ),
            // play button
            Center(
              child: Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(200),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded, size: 30, color: PawmartColors.primary500),
              ),
            ),
            // title
            Positioned(
              bottom: 10, left: 12, right: 12,
              child: Text(video.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: PawmartColors.neutral800,
      child: Center(child: Icon(Icons.videocam_rounded, size: 44, color: Colors.white.withAlpha(80))),
    );
  }

  void _playVideo(MediaAsset video) {
    ensureVideoFactory();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: Colors.black87,
              child: Row(children: [
                Expanded(child: Text(video.title, style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                IconButton(icon: const Icon(Icons.open_in_new, color: Colors.white70, size: 20), tooltip: '新标签页打开', onPressed: () => openUrlInNewTab(video.url), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36, minHeight: 36)),
                IconButton(icon: const Icon(Icons.close, color: Colors.white70, size: 22), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36, minHeight: 36)),
              ]),
            ),
            const SizedBox(width: 800, height: 450, child: HtmlElementView(viewType: 'pawmart-video-player')),
          ],
        ),
      ),
    );
    Future.delayed(const Duration(milliseconds: 100), () {
      final el = getFirstVideoElement();
      if (el != null) {
        el.src = _resolveUrl(video.url);
        el.load();
      }
    });
  }

  String _resolveUrl(String url) {
    if (url.startsWith('/uploads/')) {
      return 'http://localhost:8080$url';
    }
    return url;
  }
}
