import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
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
    } catch (e) {
      errorText = e.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Media Management',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: () => _showDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Media'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: keywordCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Search media',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onSubmitted: (_) => load(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(onPressed: load, icon: const Icon(Icons.search)),
            ],
          ),
          const SizedBox(height: 12),
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: CircularProgressIndicator(),
              ),
            ),
          if (errorText != null)
            Text(errorText!, style: TextStyle(color: theme.colorScheme.error)),
          if (!loading && errorText == null && assets.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No media assets yet'),
              ),
            ),
          if (!loading && errorText == null)
            ...assets.map(
              (asset) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      asset.mediaType == 'VIDEO'
                          ? Icons.play_arrow
                          : Icons.image,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: Text(asset.title),
                  subtitle: Text(
                    '${asset.mediaType} · ${asset.status}\n${asset.url}',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (asset.status == 'PENDING')
                        IconButton(
                          tooltip: 'Approve',
                          icon: const Icon(Icons.verified, color: Colors.green),
                          onPressed: () => _audit(asset, true),
                        ),
                      if (asset.status == 'PENDING')
                        IconButton(
                          tooltip: 'Reject',
                          icon: const Icon(Icons.block, color: Colors.orange),
                          onPressed: () => _audit(asset, false),
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showDialog(asset: asset),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _delete(asset),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showDialog({MediaAsset? asset}) async {
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _MediaDialog(asset: asset),
    );
    if (payload == null) return;
    try {
      if (asset == null) {
        await widget.apiClient.createMedia(payload);
        if (mounted) showSuccess(context, 'Media created');
      } else {
        await widget.apiClient.updateMedia(asset.id, payload);
        if (mounted) showSuccess(context, 'Media updated');
      }
      await load();
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
                ? 'Approved from admin panel'
                : 'Rejected from admin panel',
      );
      await load();
      if (mounted) {
        showSuccess(context, approved ? 'Media approved' : 'Media rejected');
      }
    } catch (e) {
      if (mounted) showError(context, e.toString());
    }
  }

  Future<void> _delete(MediaAsset asset) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Media',
      message: 'Are you sure you want to delete "${asset.title}"?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await widget.apiClient.deleteMedia(asset.id);
      await load();
      if (mounted) showSuccess(context, 'Media deleted');
    } catch (e) {
      if (mounted) showError(context, e.toString());
    }
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
      title: Text(widget.asset == null ? 'Add Media' : 'Edit Media'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: mediaType,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: const [
                        DropdownMenuItem(value: 'IMAGE', child: Text('Image')),
                        DropdownMenuItem(value: 'VIDEO', child: Text('Video')),
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
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(
                          value: 'PENDING',
                          child: Text('Pending'),
                        ),
                        DropdownMenuItem(
                          value: 'APPROVED',
                          child: Text('Approved'),
                        ),
                        DropdownMenuItem(
                          value: 'REJECTED',
                          child: Text('Rejected'),
                        ),
                        DropdownMenuItem(
                          value: 'ARCHIVED',
                          child: Text('Archived'),
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
                decoration: const InputDecoration(labelText: 'Media URL'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: coverCtrl,
                decoration: const InputDecoration(labelText: 'Cover URL'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: productIdCtrl,
                decoration: const InputDecoration(labelText: 'Product ID'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
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
          child: const Text('Save'),
        ),
      ],
    );
  }
}
