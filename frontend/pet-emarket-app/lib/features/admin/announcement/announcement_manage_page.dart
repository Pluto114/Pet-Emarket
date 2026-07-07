import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/app_user.dart';
import '../../../shared/widgets/toast.dart';

class AnnouncementManagePage extends StatefulWidget {
  const AnnouncementManagePage({required this.apiClient, super.key});
  final ApiClient apiClient;
  @override
  State<AnnouncementManagePage> createState() => _State();
}

class _State extends State<AnnouncementManagePage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  final _searchCtrl = TextEditingController();
  String _statusFilter = '';
  String _keyword = '';

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      var list = await widget.apiClient.listAllAnnouncements();
      // filter
      if (_keyword.isNotEmpty) {
        final kw = _keyword.toLowerCase();
        list = list.where((a) => (a['title']?.toString() ?? '').toLowerCase().contains(kw) || (a['content']?.toString() ?? '').toLowerCase().contains(kw)).toList();
      }
      if (_statusFilter == 'published') {
        list = list.where((a) => a['published'] == true).toList();
      } else if (_statusFilter == 'draft') {
        list = list.where((a) => a['published'] != true).toList();
      }
      if (mounted) setState(() { _items = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  int get _publishedCount => _items.where((a) => a['published'] == true).length;
  int get _draftCount => _items.where((a) => a['published'] != true).length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Colors.red.shade400), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('重试')),
          ]),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== Page Header =====
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('公告管理', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('管理平台公告信息，支持发布、编辑、撤回操作', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
              ]),
            ),
            const SizedBox(width: 12),
            IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _load, tooltip: '刷新'),
            ElevatedButton.icon(onPressed: () => _showEdit(), icon: const Icon(Icons.add, size: 18), label: const Text('新建公告')),
          ]),
          const SizedBox(height: 20),

          // ===== Stats Cards =====
          Row(children: [
            _statCard('全部公告', _items.length, Icons.campaign, const Color(0xFF7A8B3C)),
            const SizedBox(width: 12),
            _statCard('已发布', _publishedCount, Icons.check_circle_outline, const Color(0xFF3F9E53)),
            const SizedBox(width: 12),
            _statCard('草稿', _draftCount, Icons.edit_note, const Color(0xFFE8BF20)),
          ]),
          const SizedBox(height: 20),

          // ===== Search + Filter =====
          Row(children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: '搜索公告标题或内容...', prefixIcon: const Icon(Icons.search, size: 20), isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (v) { _keyword = v.trim(); _load(); },
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 120,
              child: DropdownButtonFormField<String>(
                value: _statusFilter.isEmpty ? null : _statusFilter,
                decoration: InputDecoration(isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                hint: const Text('全部状态', style: TextStyle(fontSize: 13)),
                items: const [
                  DropdownMenuItem(value: 'published', child: Text('已发布', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 'draft', child: Text('草稿', style: TextStyle(fontSize: 13))),
                ],
                onChanged: (v) { _statusFilter = v ?? ''; _load(); },
              ),
            ),
            if (_keyword.isNotEmpty || _statusFilter.isNotEmpty) ...[
              const SizedBox(width: 4),
              TextButton(onPressed: () { _searchCtrl.clear(); _keyword = ''; _statusFilter = ''; _load(); }, child: const Text('重置', style: TextStyle(fontSize: 13))),
            ],
          ]),
          const SizedBox(height: 16),

          // ===== List =====
          if (_items.isEmpty)
            const Expanded(child: Center(child: Text('暂无公告', style: TextStyle(color: Colors.grey, fontSize: 15))))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (_, i) => _buildCard(_items[i], theme),
              ),
            ),
        ],
      ),
    );
  }

  // ---- Stat Card ----
  Widget _statCard(String label, int count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.grey.shade800)),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ]),
        ]),
      ),
    );
  }

  // ---- Announcement Card ----
  Widget _buildCard(Map<String, dynamic> a, ThemeData theme) {
    final published = a['published'] == true;
    final title = a['title']?.toString() ?? '';
    final content = a['content']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row: status + actions
        Row(children: [
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: published ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(published ? Icons.check_circle : Icons.edit_note, size: 14, color: published ? const Color(0xFF3F9E53) : const Color(0xFFF9A825)),
              const SizedBox(width: 4),
              Text(published ? '已发布' : '草稿', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: published ? const Color(0xFF2E7D32) : const Color(0xFFF57F17))),
            ]),
          ),
          const Spacer(),
          if (!published)
            _actionBtn(Icons.publish, '发布', PawmartColors.primary500, () => _publish(a)),
          _actionBtn(Icons.edit_outlined, '编辑', Colors.grey.shade600, () => _showEdit(item: a)),
          const SizedBox(width: 4),
          _actionBtn(Icons.delete_outline, '删除', Colors.red.shade400, () => _delete(a)),
        ]),
        const SizedBox(height: 10),
        // Title
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF36322E))),
        if (content.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(content, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, height: 1.5, color: Colors.grey.shade600)),
        ],
        const SizedBox(height: 8),
        // Bottom: target user + time
        Row(children: [
          if (a['targetUserId'] != null) ...[
            Icon(Icons.person, size: 12, color: Colors.blue.shade400),
            const SizedBox(width: 4),
            Text('指定用户(ID:${a['targetUserId']})', style: TextStyle(fontSize: 11, color: Colors.blue.shade400)),
            const SizedBox(width: 12),
          ],
          Icon(Icons.access_time, size: 12, color: Colors.grey.shade400),
          const SizedBox(width: 4),
          Text(_formatTime(a['createdAt']?.toString() ?? ''), style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
          if (a['updatedAt'] != null && a['updatedAt'] != a['createdAt']) ...[
            const SizedBox(width: 12),
            Text('更新于 ${_formatTime(a['updatedAt'].toString())}', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
          ],
        ]),
      ]),
    );
  }

  Widget _actionBtn(IconData icon, String tooltip, Color color, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(padding: const EdgeInsets.all(6), child: Icon(icon, size: 17, color: color)),
      ),
    );
  }

  // ---- Edit Dialog ----
  Future<void> _showEdit({Map<String, dynamic>? item}) async {
    final titleCtrl = TextEditingController(text: item?['title'] ?? '');
    final contentCtrl = TextEditingController(text: item?['content'] ?? '');
    bool publishNow = item == null || item['published'] != true;
    String? selectedUserId = item?['targetUserId']?.toString();

    // 加载用户列表用于选择器
    List<AppUser> userList = [];
    try { userList = await widget.apiClient.listUsers(); } catch (_) {}

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(item == null ? '新建公告' : '编辑公告'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: '公告标题', hintText: '请输入公告标题', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                // 发送对象选择
                DropdownButtonFormField<String?>(
                  value: selectedUserId,
                  decoration: const InputDecoration(labelText: '发送对象', border: OutlineInputBorder()),
                  hint: const Text('全员公告（不指定用户）'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('全员公告')),
                    for (final u in userList)
                      DropdownMenuItem<String?>(value: u.id, child: Text('${u.displayName} (@${u.username})')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedUserId = v),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentCtrl,
                  maxLines: 6,
                  decoration: const InputDecoration(labelText: '公告内容', hintText: '请输入公告内容...', border: OutlineInputBorder(), alignLabelWithHint: true),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Switch(value: publishNow, onChanged: (v) => setDialogState(() => publishNow = v)),
                  const SizedBox(width: 8),
                  Text(publishNow ? '保存并发布' : '仅保存为草稿', style: const TextStyle(fontSize: 14)),
                ]),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                Navigator.pop(context, {'publishNow': publishNow, 'targetUserId': selectedUserId});
              },
              child: Text(publishNow ? '发布' : '保存'),
            ),
          ],
        ),
      ),
    );

    final title = titleCtrl.text.trim();
    final content = contentCtrl.text.trim();
    titleCtrl.dispose();
    contentCtrl.dispose();

    if (result == null) return;
    final doPublish = result['publishNow'] == true;
    final targetUid = result['targetUserId'];

    try {
      if (item == null) {
        await widget.apiClient.createAnnouncement({'title': title, 'content': content, 'targetUserId': targetUid});
        if (doPublish) {
          final all = await widget.apiClient.listAllAnnouncements();
          final created = all.where((a) => a['title'] == title && a['content'] == content).toList();
          if (created.isNotEmpty) {
            await widget.apiClient.updateAnnouncement(created.first['id'].toString(), {'published': true});
          }
        }
      } else {
        await widget.apiClient.updateAnnouncement(item['id'].toString(), {'title': title, 'content': content, 'published': doPublish, 'targetUserId': targetUid});
      }
      await _load();
      if (mounted) showSuccess(context, '已保存');
    } catch (e) {
      if (mounted) showError(context, e.toString());
    }
  }

  Future<void> _publish(Map<String, dynamic> item) async {
    try {
      await widget.apiClient.updateAnnouncement(item['id'].toString(), {'published': true});
      await _load();
      if (mounted) showSuccess(context, '已发布');
    } catch (e) {
      if (mounted) showError(context, e.toString());
    }
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(children: [Icon(Icons.warning_amber, color: Colors.red, size: 22), SizedBox(width: 8), Text('确认删除')]),
        content: Text('确定要删除公告「${item['title']}」吗？此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.apiClient.deleteAnnouncement(item['id'].toString());
      await _load();
      if (mounted) showSuccess(context, '已删除');
    } catch (e) {
      if (mounted) showError(context, e.toString());
    }
  }

  String _formatTime(String t) {
    try {
      final d = DateTime.parse(t);
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
