import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/media_asset.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/toast.dart';

class MediaManagePage extends StatefulWidget {
  const MediaManagePage({required this.apiClient, super.key});
  final ApiClient apiClient;

  @override
  State<MediaManagePage> createState() => _MediaManagePageState();
}

class _MediaManagePageState extends State<MediaManagePage> {
  bool loading = true;
  String? errorText;
  List<MediaAsset> assets = [];
  final keywordCtrl = TextEditingController();
  String _filterType = '全部', _filterStatus = '全部';
  static const _types = ['全部', 'IMAGE', 'VIDEO'];
  static const _statuses = ['全部', 'PENDING', 'APPROVED', 'REJECTED'];

  List<MediaAsset> get _filtered {
    var list = assets;
    if (_filterType != '全部') list = list.where((a) => a.mediaType == _filterType).toList();
    if (_filterStatus != '全部') list = list.where((a) => a.status == _filterStatus).toList();
    return list;
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    keywordCtrl.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      errorText = null;
    });
    try {
      assets = await widget.apiClient.listMedia(
        authenticated: true,
        keyword: keywordCtrl.text,
      );
      debugPrint('[MediaPage] loaded ${assets.length} assets');
    } catch (e) {
      errorText = '[MediaPage] $e';
      debugPrint('[MediaPage] error: $e');
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0), child: Row(children: [
        Text('媒体管理', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: PawmartColors.textPrimary)),
        const Spacer(),
        FilledButton.icon(onPressed: _showUploadDialog, icon: const Icon(Icons.cloud_upload, size: 18), label: const Text('上传'),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 14)),),
      ])),
      Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 0), child: Row(children: [
        Expanded(child: SizedBox(height: 38, child: TextField(controller: keywordCtrl,
          decoration: InputDecoration(hintText: '搜索...', prefixIcon: const Icon(Icons.search, size: 18), isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 9)),
          onSubmitted: (_) => load()))),
        const SizedBox(width: 8),
        _filterDropdown(_types, _filterType, (v) => setState(() => _filterType = v ?? '全部')),
        const SizedBox(width: 6),
        _filterDropdown(_statuses, _filterStatus, (v) => setState(() => _filterStatus = v ?? '全部')),
      ])),
      const SizedBox(height: 12),
      Expanded(child: loading
          ? const Center(child: CircularProgressIndicator())
          : errorText != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(errorText!, style: TextStyle(color: PawmartColors.error)), const SizedBox(height: 8),
                  OutlinedButton(onPressed: load, child: const Text('重试'))]))
              : filtered.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.perm_media_outlined, size: 56, color: PawmartColors.neutral300),
                      const SizedBox(height: 12),
                      Text(assets.isEmpty ? '暂无媒体，点击上方「上传」添加' : '没有匹配结果', style: TextStyle(fontSize: 14, color: PawmartColors.textSecondary)),
                      if (assets.isEmpty) ...[const SizedBox(height: 12), OutlinedButton.icon(onPressed: _showUploadDialog, icon: const Icon(Icons.add), label: const Text('上传媒体'),
    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 36))),],
                    ]))
                  : RefreshIndicator(onRefresh: load, child: GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 280, childAspectRatio: 0.82, mainAxisSpacing: 12, crossAxisSpacing: 12),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _mediaCard(filtered[i])))),
    ]);
  }

  Widget _filterDropdown(List<String> opts, String val, ValueChanged<String?> cb) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(border: Border.all(color: PawmartColors.neutral200), borderRadius: BorderRadius.circular(8)),
    child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: val, isDense: true, style: TextStyle(fontSize: 13, color: PawmartColors.textPrimary),
      items: opts.map((o) => DropdownMenuItem(value: o, child: Text(o == '全部' ? (opts == _types ? '类型' : '状态') : o == 'IMAGE' ? '图片' : o == 'VIDEO' ? '视频' : o == 'PENDING' ? '待审核' : o == 'APPROVED' ? '已通过' : o == 'REJECTED' ? '已驳回' : o, style: TextStyle(fontSize: 13)))).toList(), onChanged: cb)),
  );

  Widget _mediaCard(MediaAsset a) {
    final isVideo = a.mediaType == 'VIDEO';
    return Container(
      decoration: BoxDecoration(color: PawmartColors.surfaceCard, borderRadius: BorderRadius.circular(12), boxShadow: pawmartShadow1, border: Border.all(color: PawmartColors.neutral100)),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Preview area
        Expanded(
          child: Container(
            color: isVideo ? const Color(0xFF1E1B18) : PawmartColors.neutral100,
            child: Stack(children: [
              if (a.url.isNotEmpty && !isVideo)
                Positioned.fill(child: Image.network(a.url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _ph(false))),
              if (isVideo || a.url.isEmpty)
                Center(child: _ph(isVideo)),
              // Status badge
              Align(alignment: Alignment.topRight, child: Padding(padding: const EdgeInsets.all(8), child: _statusBadge(a.status))),
            ]),
          ),
        ),
        // Info
        Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(a.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: PawmartColors.textPrimary)),
          const SizedBox(height: 2),
          Text('${a.mediaType}${a.productId.isNotEmpty ? " | 商品#${a.productId}" : ""}', style: TextStyle(fontSize: 11, color: PawmartColors.textSecondary)),
          const SizedBox(height: 8),
          Row(children: [
            if (a.status == 'PENDING') ...[
              _actBtn(Icons.check, Colors.green, '通过', () => _audit(a, true)),
              const SizedBox(width: 6),
              _actBtn(Icons.close, Colors.orange, '驳回', () => _audit(a, false)),
            ],
            const Spacer(),
            InkWell(onTap: () => _showDialog(asset: a), borderRadius: BorderRadius.circular(4), child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.edit_outlined, size: 16, color: PawmartColors.textSecondary))),
            const SizedBox(width: 4),
            InkWell(onTap: () => _delete(a), borderRadius: BorderRadius.circular(4), child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.delete_outline, size: 16, color: PawmartColors.error))),
          ]),
        ])),
      ]),
    );
  }

  Widget _ph(bool v) => Center(child: Icon(v ? Icons.videocam_outlined : Icons.image_outlined, size: 32, color: PawmartColors.neutral300));
  Widget _statusBadge(String s) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: s == 'APPROVED' ? const Color(0xFFDCF5DF) : s == 'PENDING' ? const Color(0xFFFDF7D5) : const Color(0xFFFDE0E0), borderRadius: BorderRadius.circular(4)),
    child: Text(s == 'APPROVED' ? '已通过' : s == 'PENDING' ? '待审核' : s, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: s == 'APPROVED' ? const Color(0xFF3F9E53) : s == 'PENDING' ? const Color(0xFFE8BF20) : PawmartColors.error)));
  Widget _actBtn(IconData icon, Color c, String tip, VoidCallback fn) => InkWell(onTap: fn, borderRadius: BorderRadius.circular(4), child: Tooltip(message: tip, child: Padding(padding: const EdgeInsets.all(3), child: Icon(icon, size: 16, color: c))));

  // -- Dialogs (unchanged) --
  Future<void> _showDialog({MediaAsset? asset}) async {
    final p = await showDialog<Map<String, dynamic>>(context: context, builder: (ctx) => _MediaDialog(asset: asset));
    if (p == null) return;
    try {
      if (asset == null) { await widget.apiClient.createMedia(p); if (mounted) showSuccess(context, '已创建'); }
      else { await widget.apiClient.updateMedia(asset.id, p); if (mounted) showSuccess(context, '已更新'); }
      await load();
    } catch (e) { if (mounted) showError(context, e.toString()); }
  }

  Future<void> _showUploadDialog() async {
    final payload = await showDialog<_MediaUploadPayload>(
      context: context,
      builder: (ctx) => const _MediaUploadDialog(),
    );
    if (payload == null) return;
    try {
      await widget.apiClient.uploadMedia(
        title: payload.title,
        mediaType: payload.mediaType,
        productId: payload.productId,
        description: payload.description,
        fileName: payload.file.name,
        fileBytes: payload.file.bytes ?? const [],
        coverFileName: payload.coverFile?.name ?? '',
        coverFileBytes: payload.coverFile?.bytes,
      );
      await load();
      if (mounted) showSuccess(context, '已上传至OSS');
    } catch (e) {
      if (mounted) showError(context, e.toString());
    }
  }

  Future<void> _audit(MediaAsset asset, bool approved) async {
    try {
      await widget.apiClient.auditMedia(
        asset.id,
        approved: approved,
        remark:
            approved
                ? '管理员审核通过'
                : '管理员驳回',
      );
      await load();
      if (mounted) {
        showSuccess(context, approved ? '审核通过' : '已驳回');
      }
    } catch (e) {
      if (mounted) showError(context, e.toString());
    }
  }

  Future<void> _delete(MediaAsset asset) async {
    final confirmed = await showConfirmDialog(
      context,
      title: '删除媒体',
      message: '确定要删除 "${asset.title}"？',
      confirmLabel: '删除',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await widget.apiClient.deleteMedia(asset.id);
      await load();
      if (mounted) showSuccess(context, '媒体已删除');
    } catch (e) {
      if (mounted) showError(context, e.toString());
    }
  }
}

class _MediaUploadPayload {
  const _MediaUploadPayload({
    required this.title,
    required this.mediaType,
    required this.file,
    this.coverFile,
    this.productId = '',
    this.description = '',
  });

  final String title;
  final String mediaType;
  final PlatformFile file;
  final PlatformFile? coverFile;
  final String productId;
  final String description;
}

class _MediaUploadDialog extends StatefulWidget {
  const _MediaUploadDialog();

  @override
  State<_MediaUploadDialog> createState() => _MediaUploadDialogState();
}

class _MediaUploadDialogState extends State<_MediaUploadDialog> {
  final titleCtrl = TextEditingController();
  final productIdCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  String mediaType = 'IMAGE';
  PlatformFile? file;
  PlatformFile? coverFile;

  @override
  void dispose() {
    titleCtrl.dispose();
    productIdCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  List<String> get _allowedMainExtensions {
    return mediaType == 'VIDEO'
        ? const ['mp4', 'mov', 'avi', 'm4v', 'webm']
        : const ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('上传媒体'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: mediaType,
                decoration: const InputDecoration(labelText: '类型'),
                items: const [
                  DropdownMenuItem(value: 'IMAGE', child: Text('图片')),
                  DropdownMenuItem(value: 'VIDEO', child: Text('视频')),
                ],
                onChanged: (value) {
                  setState(() {
                    mediaType = value ?? mediaType;
                    file = null;
                  });
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: '标题'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: productIdCtrl,
                decoration: const InputDecoration(labelText: '商品ID'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: '描述'),
                maxLines: 3,
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => _pickMainFile(context),
                icon: const Icon(Icons.attach_file),
                label: Text(file == null ? '选择文件' : file!.name),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _pickCoverFile(context),
                icon: const Icon(Icons.image),
                label: Text(
                  coverFile == null ? '选择封面图' : coverFile!.name,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed:
              file == null || titleCtrl.text.trim().isEmpty
                  ? null
                  : () {
                    Navigator.pop(
                      context,
                      _MediaUploadPayload(
                        title: titleCtrl.text.trim(),
                        mediaType: mediaType,
                        file: file!,
                        coverFile: coverFile,
                        productId: productIdCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                      ),
                    );
                  },
          child: const Text('上传'),
        ),
      ],
    );
  }

  Future<void> _pickMainFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedMainExtensions,
      withData: true,
    );
    final selected = result?.files.single;
    if (selected == null) return;
    if (selected.bytes == null || selected.bytes!.isEmpty) {
      if (context.mounted) showError(context, '无法读取文件');
      return;
    }
    setState(() {
      file = selected;
      if (titleCtrl.text.trim().isEmpty) {
        titleCtrl.text = selected.name.replaceFirst(RegExp(r'\.[^.]+$'), '');
      }
    });
  }

  Future<void> _pickCoverFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'gif', 'webp'],
      withData: true,
    );
    final selected = result?.files.single;
    if (selected == null) return;
    if (selected.bytes == null || selected.bytes!.isEmpty) {
      if (context.mounted) showError(context, '无法读取文件');
      return;
    }
    setState(() => coverFile = selected);
  }
}

class _MediaDialog extends StatefulWidget {
  const _MediaDialog({this.asset});
  final MediaAsset? asset;

  @override
  State<_MediaDialog> createState() => _MediaDialogState();
}

class _MediaDialogState extends State<_MediaDialog> {
  late final titleCtrl = TextEditingController(text: widget.asset?.title ?? '');
  late final urlCtrl = TextEditingController(text: widget.asset?.url ?? '');
  late final coverCtrl = TextEditingController(
    text: widget.asset?.coverUrl ?? '',
  );
  late final productIdCtrl = TextEditingController(
    text: widget.asset?.productId ?? '',
  );
  late final descCtrl = TextEditingController(
    text: widget.asset?.description ?? '',
  );
  String mediaType = 'IMAGE';
  String status = 'PENDING';

  @override
  void initState() {
    super.initState();
    mediaType = widget.asset?.mediaType ?? 'IMAGE';
    status = widget.asset?.status ?? 'PENDING';
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    urlCtrl.dispose();
    coverCtrl.dispose();
    productIdCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.asset == null ? '添加媒体' : '编辑媒体'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: '标题'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: mediaType,
                      decoration: const InputDecoration(labelText: '类型'),
                      items: const [
                        DropdownMenuItem(value: 'IMAGE', child: Text('图片')),
                        DropdownMenuItem(value: 'VIDEO', child: Text('视频')),
                      ],
                      onChanged:
                          (value) =>
                              setState(() => mediaType = value ?? mediaType),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(labelText: '状态'),
                      items: const [
                        DropdownMenuItem(
                          value: 'PENDING',
                          child: Text('待审核'),
                        ),
                        DropdownMenuItem(
                          value: 'APPROVED',
                          child: Text('审核通过'),
                        ),
                        DropdownMenuItem(
                          value: 'REJECTED',
                          child: Text('已驳回'),
                        ),
                        DropdownMenuItem(
                          value: 'ARCHIVED',
                          child: Text('已归档'),
                        ),
                      ],
                      onChanged:
                          (value) => setState(() => status = value ?? status),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: urlCtrl,
                decoration: const InputDecoration(labelText: '媒体链接'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: coverCtrl,
                decoration: const InputDecoration(labelText: '封面地址'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: productIdCtrl,
                decoration: const InputDecoration(labelText: '商品ID'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: '描述'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final payload = {
              'title': titleCtrl.text.trim(),
              'mediaType': mediaType,
              'url': urlCtrl.text.trim(),
              'coverUrl': coverCtrl.text.trim(),
              if (productIdCtrl.text.trim().isNotEmpty)
                'productId': int.tryParse(productIdCtrl.text.trim()),
              'description': descCtrl.text.trim(),
              'status': status,
            };
            Navigator.pop(context, payload);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
