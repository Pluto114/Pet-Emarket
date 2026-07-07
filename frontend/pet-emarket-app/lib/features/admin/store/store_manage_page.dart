import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../models/app_user.dart';
import '../../../models/store.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/toast.dart';

class StoreManagePage extends StatefulWidget {
  const StoreManagePage({required this.apiClient, super.key});
  final ApiClient apiClient;

  @override
  State<StoreManagePage> createState() => _StoreManagePageState();
}

class _StoreManagePageState extends State<StoreManagePage> {
  bool loading = true;
  String? errorText;
  List<PetStore> stores = [];
  List<AppUser> users = [];
  final keywordCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  String statusFilter = '';

  // 用户 -> 店铺分组
  Map<String, List<PetStore>> get _grouped {
    final map = <String, List<PetStore>>{};
    for (final s in stores) {
      final uid = s.ownerUserId.isNotEmpty ? s.ownerUserId : 'no_owner';
      map.putIfAbsent(uid, () => []).add(s);
    }
    return map;
  }

  String _userName(String userId) {
    if (userId == 'no_owner') return '未分配';
    final u = users.where((u) => u.id == userId).firstOrNull;
    return u?.displayName ?? '用户#$userId';
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    keywordCtrl.dispose();
    cityCtrl.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      errorText = null;
    });
    try {
      final allStores = await widget.apiClient.listStores(authenticated: true);
      final allUsers = await widget.apiClient.listUsers();
      var filtered = allStores;
      if (keywordCtrl.text.isNotEmpty) {
        final kw = keywordCtrl.text.toLowerCase();
        filtered = filtered.where((s) => s.name.toLowerCase().contains(kw) || s.address.toLowerCase().contains(kw)).toList();
      }
      if (cityCtrl.text.isNotEmpty) {
        final ct = cityCtrl.text.toLowerCase();
        filtered = filtered.where((s) => s.city.toLowerCase().contains(ct)).toList();
      }
      if (statusFilter.isNotEmpty) {
        filtered = filtered.where((s) => s.status == statusFilter).toList();
      }
      if (mounted) setState(() { stores = filtered; users = allUsers; loading = false; });
    } catch (e) {
      if (mounted) setState(() { errorText = e.toString(); loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (errorText != null) return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, size: 48, color: Colors.red), const SizedBox(height: 12),
      Text(errorText!, style: const TextStyle(color: Colors.red)), const SizedBox(height: 16),
      ElevatedButton(onPressed: load, child: const Text('重试')),
    ])));
    final grouped = _grouped;
    return ListView(padding: const EdgeInsets.all(24), children: [
      Text('店铺管理', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      Text('共 ${stores.length} 家店铺  ·  ${grouped.length} 位店主', style: const TextStyle(color: Colors.grey)),
      const SizedBox(height: 12),
      if (grouped.isEmpty)
        const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('暂无店铺', style: TextStyle(color: Colors.grey, fontSize: 15))))
      else
        for (final entry in grouped.entries)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF7A8B3C).withAlpha(30),
                child: Text(_userName(entry.key).isNotEmpty ? _userName(entry.key)[0].toUpperCase() : '?',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF7A8B3C))),
              ),
              title: Text(_userName(entry.key), style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${entry.value.length} 家店铺', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              initiallyExpanded: grouped.length <= 3,
              children: entry.value.map((s) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Card(
                  color: Colors.grey.shade50,
                  margin: const EdgeInsets.only(bottom: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(Icons.store, size: 16, color: s.status == 'OPEN' ? Colors.green : Colors.red),
                        const SizedBox(width: 8),
                        Expanded(child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                        _chip(s.status == 'OPEN' ? '营业中' : '已关闭', s.status == 'OPEN' ? Colors.green : Colors.red),
                      ]),
                      const SizedBox(height: 6),
                      Text('${s.city} ${s.district}  ·  ${s.address}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      const SizedBox(height: 6),
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        TextButton.icon(onPressed: () => _showDialog(store: s), icon: const Icon(Icons.edit, size: 14), label: const Text('编辑', style: TextStyle(fontSize: 11))),
                        const SizedBox(width: 2),
                        if (s.status == 'OPEN')
                          TextButton.icon(onPressed: () => _suspendStore(s), icon: const Icon(Icons.pause_circle_outline, size: 14, color: Colors.orange), label: const Text('停用', style: TextStyle(color: Colors.orange, fontSize: 11)))
                        else
                          TextButton.icon(onPressed: () => _resumeStore(s), icon: const Icon(Icons.play_circle_outline, size: 14, color: Colors.green), label: const Text('恢复', style: TextStyle(color: Colors.green, fontSize: 11))),
                        const SizedBox(width: 2),
                        TextButton.icon(onPressed: () => _delete(s), icon: const Icon(Icons.delete, size: 14, color: Colors.red), label: const Text('删除', style: TextStyle(color: Colors.red, fontSize: 11))),
                      ]),
                    ]),
                  ),
                ),
              )).toList(),
            ),
          ),
    ]);
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Future<void> _suspendStore(PetStore s) async {
    final reasonCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('停用店铺 — ${s.name}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('请填写停用原因，将自动通知店长。', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 12),
          TextField(controller: reasonCtrl, maxLines: 3, decoration: const InputDecoration(hintText: '停用原因', border: OutlineInputBorder())),
        ]),
        actions: [
          TextButton(onPressed: () { reasonCtrl.dispose(); Navigator.pop(context, false); }, child: const Text('取消')),
          ElevatedButton(
            onPressed: () { reasonCtrl.dispose(); Navigator.pop(context, true); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            child: const Text('确认停用'),
          ),
        ],
      ),
    );
    if (result != true) return;
    try {
      final reason = reasonCtrl.text.trim().isEmpty ? '管理员暂停营业' : reasonCtrl.text.trim();
      await widget.apiClient.updateStore(s.id, {'status': 'CLOSED'});
      // 发送通知给店长
      if (s.ownerUserId.isNotEmpty) {
        final uid = int.tryParse(s.ownerUserId);
        if (uid != null) {
          await widget.apiClient.createAnnouncement({
            'title': '店铺停用通知 — ${s.name}',
            'content': '您的店铺「${s.name}」已被管理员暂停营业。原因：$reason。如有疑问请联系平台客服。',
            'targetUserId': uid,
          });
        }
      }
      await load();
      if (mounted) showSuccess(context, '已停用并通知店长');
    } catch (e) { if (mounted) showError(context, e.toString()); }
  }

  Future<void> _resumeStore(PetStore s) async {
    try {
      await widget.apiClient.updateStore(s.id, {'status': 'OPEN'});
      if (s.ownerUserId.isNotEmpty) {
        final uid = int.tryParse(s.ownerUserId);
        if (uid != null) {
          await widget.apiClient.createAnnouncement({
            'title': '店铺恢复通知 — ${s.name}',
            'content': '您的店铺「${s.name}」已恢复营业。',
            'targetUserId': uid,
          });
        }
      }
      await load();
      if (mounted) showSuccess(context, '已恢复营业');
    } catch (e) { if (mounted) showError(context, e.toString()); }
  }

  Future<void> _showDialog({PetStore? store}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _StoreDialog(store: store),
    );
    if (result == null) return;
    try {
      if (store == null) {
        await widget.apiClient.createStore(result);
        if (mounted) showSuccess(context, '店铺创建成功');
      } else {
        await widget.apiClient.updateStore(store.id, result);
        if (mounted) showSuccess(context, '店铺更新成功');
      }
      await load();
    } catch (e) {
      if (mounted) showError(context, e.toString());
    }
  }

  Future<void> _delete(PetStore store) async {
    final confirmed = await showConfirmDialog(
      context,
      title: '删除店铺',
      message: '确定要删除店铺 "${store.name}" 吗？',
      confirmLabel: '删除',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await widget.apiClient.deleteStore(store.id);
      await load();
      if (mounted) showSuccess(context, '店铺已删除');
    } catch (e) {
      if (mounted) showError(context, e.toString());
    }
  }
}

class _StoreDialog extends StatefulWidget {
  const _StoreDialog({this.store});
  final PetStore? store;

  @override
  State<_StoreDialog> createState() => _StoreDialogState();
}

class _StoreDialogState extends State<_StoreDialog> {
  late final nameCtrl = TextEditingController(text: widget.store?.name ?? '');
  late final addressCtrl = TextEditingController(
    text: widget.store?.address ?? '',
  );
  late final cityCtrl = TextEditingController(text: widget.store?.city ?? '杭州');
  late final districtCtrl = TextEditingController(
    text: widget.store?.district ?? '西湖区',
  );
  late final longitudeCtrl = TextEditingController(
    text: widget.store?.longitude.toString() ?? '120.1551',
  );
  late final latitudeCtrl = TextEditingController(
    text: widget.store?.latitude.toString() ?? '30.2741',
  );
  late final phoneCtrl = TextEditingController(text: widget.store?.phone ?? '');
  late final hoursCtrl = TextEditingController(
    text: widget.store?.businessHours ?? '09:00-21:00',
  );
  late final ratingCtrl = TextEditingController(
    text: widget.store?.rating.toString() ?? '4.8',
  );
  late final tagsCtrl = TextEditingController(
    text: widget.store?.featureTags ?? '',
  );
  String status = 'OPEN';

  @override
  void initState() {
    super.initState();
    status = widget.store?.status ?? 'OPEN';
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    addressCtrl.dispose();
    cityCtrl.dispose();
    districtCtrl.dispose();
    longitudeCtrl.dispose();
    latitudeCtrl.dispose();
    phoneCtrl.dispose();
    hoursCtrl.dispose();
    ratingCtrl.dispose();
    tagsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.store == null ? '添加店铺' : '编辑店铺'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: '店铺名称'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: '详细地址'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: cityCtrl,
                      decoration: const InputDecoration(labelText: '城市'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: districtCtrl,
                      decoration: const InputDecoration(labelText: '区域'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: longitudeCtrl,
                      decoration: const InputDecoration(labelText: '经度'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: latitudeCtrl,
                      decoration: const InputDecoration(labelText: '纬度'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ratingCtrl,
                      decoration: const InputDecoration(labelText: '评分'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(labelText: '状态'),
                      items: const [
                        DropdownMenuItem(value: 'OPEN', child: Text('营业中')),
                        DropdownMenuItem(value: 'CLOSED', child: Text('已关闭')),
                      ],
                      onChanged:
                          (value) => setState(() => status = value ?? status),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: '联系电话'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: hoursCtrl,
                decoration: const InputDecoration(labelText: '营业时间'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: tagsCtrl,
                decoration: const InputDecoration(labelText: '特色标签'),
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
        ElevatedButton(
          onPressed: () {
            final payload = {
              'name': nameCtrl.text.trim(),
              'address': addressCtrl.text.trim(),
              'city': cityCtrl.text.trim(),
              'district': districtCtrl.text.trim(),
              'longitude': double.tryParse(longitudeCtrl.text) ?? 120.1551,
              'latitude': double.tryParse(latitudeCtrl.text) ?? 30.2741,
              'phone': phoneCtrl.text.trim(),
              'businessHours': hoursCtrl.text.trim(),
              'rating': double.tryParse(ratingCtrl.text) ?? 4.8,
              'status': status,
              'featureTags': tagsCtrl.text.trim(),
            };
            Navigator.pop(context, payload);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
