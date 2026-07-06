import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/toast.dart';

class AnnouncementManagePage extends StatefulWidget {
  const AnnouncementManagePage({required this.apiClient, super.key});
  final ApiClient apiClient;
  @override
  State<AnnouncementManagePage> createState() => _AnnouncementManagePageState();
}

class _AnnouncementManagePageState extends State<AnnouncementManagePage> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> items = [];

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    setState(() { loading = true; error = null; });
    try { items = await widget.apiClient.listAllAnnouncements(); }
    catch (e) { error = e.toString(); }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: PawmartColors.surfaceBg,
    appBar: AppBar(title: const Text('公告管理'), actions: [
      IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: load),
      FilledButton.icon(onPressed: _showEdit, icon: const Icon(Icons.add, size: 18), label: const Text('新建'),
        style: FilledButton.styleFrom(minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 14))),
      const SizedBox(width: 8),
    ]),
    body: loading ? const Center(child: CircularProgressIndicator())
        : error != null ? Center(child: Text(error!, style: TextStyle(color: PawmartColors.error)))
        : items.isEmpty ? Center(child: Text('暂无公告', style: TextStyle(fontSize: 15, color: PawmartColors.textSecondary)))
        : RefreshIndicator(onRefresh: load, child: ListView.builder(
            padding: const EdgeInsets.all(16), itemCount: items.length,
            itemBuilder: (_, i) => _card(items[i]))),
  );

  Widget _card(Map<String, dynamic> a) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: PawmartColors.surfaceCard, borderRadius: BorderRadius.circular(12), boxShadow: pawmartShadow1),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: a['published'] == true ? const Color(0xFFDCF5DF) : const Color(0xFFFDF7D5), borderRadius: BorderRadius.circular(4)),
          child: Text(a['published'] == true ? '已发布' : '草稿', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: a['published'] == true ? const Color(0xFF3F9E53) : const Color(0xFFE8BF20)))),
        const Spacer(),
        if (a['published'] != true) InkWell(onTap: () => _publish(a), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.publish, size: 16, color: PawmartColors.primary500))),
        const SizedBox(width: 6),
        InkWell(onTap: () => _showEdit(item: a), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.edit_outlined, size: 16, color: PawmartColors.textSecondary))),
        const SizedBox(width: 6),
        InkWell(onTap: () => _delete(a), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.delete_outline, size: 16, color: PawmartColors.error))),
      ]),
      const SizedBox(height: 8),
      Text(a['title']?.toString() ?? '', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: PawmartColors.textPrimary)),
      const SizedBox(height: 4),
      Text(a['content']?.toString() ?? '', maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: PawmartColors.textSecondary)),
      const SizedBox(height: 6),
      Text(_time(a['createdAt']?.toString() ?? ''), style: TextStyle(fontSize: 11, color: PawmartColors.textSecondary)),
    ]),
  );

  Future<void> _showEdit({Map<String, dynamic>? item}) async {
    final t = TextEditingController(text: item?['title'] ?? '');
    final c = TextEditingController(text: item?['content'] ?? '');
    final r = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: Text(item == null ? '新建公告' : '编辑公告'),
      content: SizedBox(width: 500, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: t, decoration: const InputDecoration(labelText: '标题')),
        const SizedBox(height: 10),
        TextField(controller: c, maxLines: 6, decoration: const InputDecoration(labelText: '内容')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')), FilledButton(onPressed: () { if (t.text.trim().isEmpty) return; Navigator.pop(context, true); }, child: const Text('保存'))],
    ));
    if (r != true) { t.dispose(); c.dispose(); return; }
    final title = t.text.trim();
    final content = c.text.trim();
    t.dispose(); c.dispose();
    try {
      if (item == null) { await widget.apiClient.createAnnouncement({'title': title, 'content': content}); }
      else { await widget.apiClient.updateAnnouncement(item['id'].toString(), {'title': title, 'content': content}); }
      await load(); if (mounted) showSuccess(context, '已保存');
    } catch (e) { if (mounted) showError(context, e.toString()); }
  }

  Future<void> _publish(Map<String, dynamic> item) async {
    try { await widget.apiClient.updateAnnouncement(item['id'].toString(), {'published': true}); await load(); if (mounted) showSuccess(context, '已发布'); }
    catch (e) { if (mounted) showError(context, e.toString()); }
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('删除公告'), content: Text('确定删除「${item['title']}」？'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')), FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(backgroundColor: PawmartColors.error), child: const Text('删除'))]));
    if (ok != true) return;
    try { await widget.apiClient.deleteAnnouncement(item['id'].toString()); await load(); if (mounted) showSuccess(context, '已删除'); }
    catch (e) { if (mounted) showError(context, e.toString()); }
  }

  String _time(String t) { try { final d = DateTime.parse(t); return '${d.month}/${d.day} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}'; } catch (_) { return ''; } }
}
