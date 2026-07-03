import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
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
  final keywordCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  String statusFilter = '';

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
      stores = await widget.apiClient.listStores(authenticated: true);
      if (keywordCtrl.text.isNotEmpty) {
        final kw = keywordCtrl.text.toLowerCase();
        stores = stores.where((s) => s.name.toLowerCase().contains(kw) || s.address.toLowerCase().contains(kw)).toList();
      }
      if (cityCtrl.text.isNotEmpty) {
        final ct = cityCtrl.text.toLowerCase();
        stores = stores.where((s) => s.city.toLowerCase().contains(ct)).toList();
      }
      if (statusFilter.isNotEmpty) {
        stores = stores.where((s) => s.status == statusFilter).toList();
      }
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
                  '店铺管理',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              FilledButton.icon(
                onPressed: () => _showDialog(),
                icon: const Icon(Icons.add),
                label: const Text('添加店铺'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 搜索栏
          Row(children: [
            Expanded(
              child: TextField(
                controller: keywordCtrl,
                decoration: const InputDecoration(labelText: '搜索店铺', prefixIcon: Icon(Icons.search), isDense: true),
                onSubmitted: (_) => load(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: cityCtrl,
                decoration: const InputDecoration(labelText: '城市', prefixIcon: Icon(Icons.location_city), isDense: true),
                onSubmitted: (_) => load(),
              ),
            ),
            const SizedBox(width: 8),
            // 状态筛选
            DropdownButtonFormField<String>(
              value: statusFilter.isEmpty ? null : statusFilter,
              decoration: const InputDecoration(labelText: '状态', isDense: true),
              items: const [
                DropdownMenuItem(value: '', child: Text('全部')),
                DropdownMenuItem(value: 'OPEN', child: Text('营业中')),
                DropdownMenuItem(value: 'CLOSED', child: Text('已关闭')),
              ],
              onChanged: (v) { statusFilter = v ?? ''; load(); },
            ),
          ]),
          const SizedBox(height: 12),
          if (loading)
            const Center(child: Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator())),
          if (errorText != null)
            Text(errorText!, style: TextStyle(color: theme.colorScheme.error)),
          if (!loading && errorText == null && stores.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('暂无店铺'))),
          if (!loading && errorText == null)
            ...stores.map(
              (store) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      CircleAvatar(
                        backgroundColor: store.status == 'OPEN' ? Colors.green.withAlpha(30) : Colors.red.withAlpha(30),
                        child: Icon(Icons.store, color: store.status == 'OPEN' ? Colors.green : Colors.red, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(store.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
                      _statusChip(store.status),
                    ]),
                    const SizedBox(height: 10),
                    Text('${store.city} ${store.district}  ·  ${store.address}', style: theme.textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text('${store.rating.toStringAsFixed(1)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      if (store.phone.isNotEmpty) ...[const SizedBox(width: 12), Icon(Icons.phone, size: 12, color: theme.colorScheme.onSurfaceVariant), const SizedBox(width: 2), Text(store.phone, style: theme.textTheme.bodySmall)],
                      if (store.featureTags.isNotEmpty) ...[const SizedBox(width: 12), Flexible(child: Text(store.featureTags, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis))],
                    ]),
                    if (store.ownerUserId != null) ...[const SizedBox(height: 4), Text('店主ID: ${store.ownerUserId}', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant))],
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      OutlinedButton.icon(onPressed: () => _showDialog(store: store), icon: const Icon(Icons.edit, size: 16), label: const Text('编辑')),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(onPressed: () => _delete(store), icon: const Icon(Icons.delete, size: 16, color: Colors.red), label: Text('删除', style: TextStyle(color: Colors.red))),
                    ]),
                  ]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final isOpen = status == 'OPEN';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: isOpen ? Colors.green.withAlpha(20) : Colors.red.withAlpha(20), borderRadius: BorderRadius.circular(10)),
      child: Text(isOpen ? '营业中' : '已关闭', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isOpen ? Colors.green : Colors.red)),
    );
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
        FilledButton(
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
