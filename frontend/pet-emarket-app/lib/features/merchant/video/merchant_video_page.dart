import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/media_asset.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/toast.dart';
import '../../../shared/widgets/video_factory_stub.dart' if (dart.library.html) '../../../shared/widgets/video_factory_web.dart';
import '../../../shared/widgets/web_helpers_stub.dart' if (dart.library.html) '../../../shared/widgets/web_helpers_web.dart';

class MerchantVideoPage extends StatefulWidget {
  const MerchantVideoPage({required this.apiClient, super.key});
  final ApiClient apiClient;
  @override
  State<MerchantVideoPage> createState() => _State();
}

class _State extends State<MerchantVideoPage> {
  bool _loading = true;
  String? _error;
  List<MediaAsset> _videos = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final all = await widget.apiClient.listMedia(authenticated: true);
      _videos = all.where((m) => m.mediaType == 'VIDEO').toList();
    } catch (e) { _error = e.toString(); }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.red), const SizedBox(height: 12),
        Text(_error!, style: const TextStyle(color: Colors.red)), const SizedBox(height: 16),
        ElevatedButton(onPressed: _load, child: const Text('重试')),
      ]));
    }
    return ListView(padding: const EdgeInsets.all(24), children: [
      Row(children: [
        Expanded(child: Text('视频管理', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700))),
        ElevatedButton(onPressed: _showUpload, child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.cloud_upload, size: 18), SizedBox(width: 4), Text('上传视频')])),
      ]),
      const SizedBox(height: 6),
      Text('共 ${_videos.length} 个视频', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
      const SizedBox(height: 12),
      if (_videos.isEmpty)
        const Center(child: Padding(padding: EdgeInsets.all(60), child: Text('暂无视频', style: TextStyle(color: Colors.grey, fontSize: 15))))
      else
        for (final v in _videos)
          Card(margin: const EdgeInsets.only(bottom: 8), child: Padding(padding: const EdgeInsets.all(12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Video preview / thumbnail
            GestureDetector(
              onTap: () => _playVideo(v),
              child: Container(
                width: 120, height: 80,
                decoration: BoxDecoration(color: const Color(0xFF1E1B18), borderRadius: BorderRadius.circular(8)),
                child: Stack(alignment: Alignment.center, children: [
                  if (v.coverUrl.isNotEmpty)
                    ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(v.coverUrl, width: 120, height: 80, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox())),
                  Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white.withAlpha(200), shape: BoxShape.circle),
                    child: const Icon(Icons.play_arrow, size: 22, color: Colors.black87)),
                ]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(v.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                  _badge(v.status == 'APPROVED' ? '已通过' : v.status == 'PENDING' ? '待审核' : v.status,
                      v.status == 'APPROVED' ? Colors.green : v.status == 'PENDING' ? Colors.orange : Colors.red),
                ]),
                if (v.productId.isNotEmpty) Text('商品ID: ${v.productId}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                if (v.description.isNotEmpty) Text(v.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton.icon(onPressed: () => _showEdit(v), icon: const Icon(Icons.edit, size: 14), label: const Text('编辑', style: TextStyle(fontSize: 11))),
                  TextButton.icon(onPressed: () => _deleteVideo(v), icon: const Icon(Icons.delete, size: 14, color: Colors.red), label: const Text('删除', style: TextStyle(color: Colors.red, fontSize: 11))),
                ]),
              ]),
            ),
          ]))),
    ]);
  }

  void _playVideo(MediaAsset v) {
    ensureVideoFactory();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: Colors.black87,
            child: Row(children: [
              Expanded(child: Text(v.title, style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
              IconButton(icon: const Icon(Icons.open_in_new, color: Colors.white70, size: 20), tooltip: '新标签页打开', onPressed: () => openUrlInNewTab(_resolveUrl(v.url)), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36, minHeight: 36)),
              IconButton(icon: const Icon(Icons.close, color: Colors.white70, size: 22), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36, minHeight: 36)),
            ]),
          ),
          const SizedBox(width: 800, height: 450, child: HtmlElementView(viewType: 'pawmart-video-player')),
        ]),
      ),
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      final el = getFirstVideoElement();
      if (el != null) {
        final resolvedUrl = _resolveUrl(v.url);
        el.src = resolvedUrl;
        el.load();
        el.play();
      }
    });
  }

  String _resolveUrl(String url) {
    // 本地存储的相对路径，补全后端地址
    if (url.startsWith('/uploads/') || url.startsWith('/media/')) {
      return 'http://localhost:8080$url';
    }
    // OSS 完整 URL 或其他绝对 URL，直接返回
    return url;
  }

  Widget _badge(String label, Color color) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)));
  }

  Future<void> _showUpload() async {
    final r = await showDialog<_UploadResult>(context: context, builder: (_) => const _UploadDialog());
    if (r == null) return;
    try {
      await widget.apiClient.uploadMedia(title: r.title, mediaType: 'VIDEO', fileName: r.fileName, fileBytes: r.fileBytes, productId: r.productId, description: r.description, fileContentType: r.contentType);
      await _load();
      if (mounted) showSuccess(context, '视频已上传');
    } catch (e) { if (mounted) showError(context, e.toString()); }
  }

  Future<void> _showEdit(MediaAsset v) async {
    final t = TextEditingController(text: v.title), d = TextEditingController(text: v.description), p = TextEditingController(text: v.productId);
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('编辑视频信息'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: t, decoration: const InputDecoration(labelText: '标题', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: d, maxLines: 2, decoration: const InputDecoration(labelText: '描述', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: p, decoration: const InputDecoration(labelText: '关联商品ID（可选）', border: OutlineInputBorder())),
      ])),
      actions: [TextButton(onPressed: () { t.dispose(); d.dispose(); p.dispose(); Navigator.pop(context, false); }, child: const Text('取消')), ElevatedButton(onPressed: () { t.dispose(); d.dispose(); p.dispose(); Navigator.pop(context, true); }, child: const Text('保存'))],
    ));
    if (ok != true) return;
    try {
      await widget.apiClient.updateMedia(v.id, {'title': t.text.trim(), 'description': d.text.trim(), 'productId': p.text.trim()});
      await _load(); if (mounted) showSuccess(context, '已更新');
    } catch (e) { if (mounted) showError(context, e.toString()); }
  }

  Future<void> _deleteVideo(MediaAsset v) async {
    final ok = await showConfirmDialog(context, title: '删除视频', message: '确定删除"${v.title}"？', confirmLabel: '删除', destructive: true);
    if (!ok) return;
    try { await widget.apiClient.deleteMedia(v.id); await _load(); if (mounted) showSuccess(context, '已删除'); }
    catch (e) { if (mounted) showError(context, e.toString()); }
  }
}

class _UploadResult {
  final String title, fileName, contentType, productId, description;
  final List<int> fileBytes;
  const _UploadResult({required this.title, required this.fileName, required this.contentType, required this.productId, required this.description, required this.fileBytes});
}

class _UploadDialog extends StatefulWidget {
  const _UploadDialog();
  @override State<_UploadDialog> createState() => _UploadDialogState();
}

class _UploadDialogState extends State<_UploadDialog> {
  final _t = TextEditingController(), _d = TextEditingController(), _p = TextEditingController();
  String? _fn; Uint8List? _fb; String _ct = 'video/mp4';
  @override void dispose() { _t.dispose(); _d.dispose(); _p.dispose(); super.dispose(); }

  Future<void> _pick() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.video, allowMultiple: false, withData: true);
    if (r == null || r.files.isEmpty) return;
    final f = r.files.first;
    if (f.bytes == null) { if (mounted) showError(context, '无法读取文件'); return; }
    setState(() {
      _fn = f.name; _fb = f.bytes!;
      _ct = switch (f.name.split('.').last.toLowerCase()) { 'mov' => 'video/quicktime', 'avi' => 'video/x-msvideo', 'webm' => 'video/webm', _ => 'video/mp4' };
      if (_t.text.isEmpty) _t.text = f.name.replaceFirst(RegExp(r'\.[^.]+$'), '');
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('上传视频'),
      content: SizedBox(width: 440, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ElevatedButton(
          onPressed: _pick,
          child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.videocam, size: 18), const SizedBox(width: 6), Text(_fn ?? '选择视频文件')]),
        ),
        if (_fn != null) ...[const SizedBox(height: 4), Text(_fn!, style: TextStyle(fontSize: 12, color: Colors.grey.shade500))],
        const SizedBox(height: 14),
        TextField(controller: _t, decoration: const InputDecoration(labelText: '视频标题 *', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _d, maxLines: 2, decoration: const InputDecoration(labelText: '描述（可选）', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _p, decoration: const InputDecoration(labelText: '关联商品ID（可选）', hintText: '不填则不关联', border: OutlineInputBorder())),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        ElevatedButton(onPressed: (_t.text.trim().isEmpty || _fb == null) ? null : () {
          Navigator.pop(context, _UploadResult(title: _t.text.trim(), fileName: _fn!, contentType: _ct, productId: _p.text.trim(), description: _d.text.trim(), fileBytes: _fb!));
        }, child: const Text('上传')),
      ],
    );
  }
}
