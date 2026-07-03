import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/session/session_store.dart';
import '../../../models/store.dart';
import '../../../shared/widgets/toast.dart';
import '../../../shared/widgets/map_picker_page.dart';
import '../../../shared/widgets/city_data.dart';

class MerchantStorePage extends StatefulWidget {
  const MerchantStorePage({
    required this.apiClient,
    required this.sessionStore,
    super.key,
  });
  final ApiClient apiClient;
  final SessionStore sessionStore;

  @override
  State<MerchantStorePage> createState() => _MerchantStorePageState();
}

class _MerchantStorePageState extends State<MerchantStorePage> {
  bool loading = true;
  String? errorText;
  List<PetStore> stores = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      errorText = null;
    });
    try {
      stores = await widget.apiClient.listStores(authenticated: true);
    } catch (e) {
      errorText = e.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Page title
          Row(
            children: [
              Expanded(
                child: Text(
                  '店铺设置',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (stores.isNotEmpty)
                Text(
                  '共 ${stores.length} 家',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          // Error card
          if (errorText != null) ...[
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: theme.colorScheme.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        errorText!,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    TextButton(onPressed: load, child: const Text('重试')),
                  ],
                ),
              ),
            ),
          ],
          // Empty state
          if (stores.isEmpty && errorText == null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.store,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant.withAlpha(80),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '暂未关联店铺',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '请联系管理员为您的账号关联店铺',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('刷新'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          // Store cards
          for (var i = 0; i < stores.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            _buildStoreCard(theme, stores[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildStoreCard(ThemeData theme, PetStore store) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.store,
                    size: 22,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          _buildStatusBadge(store.status),
                          const SizedBox(width: 8),
                          Icon(Icons.star, size: 14, color: Colors.amber[700]),
                          const SizedBox(width: 2),
                          Text(
                            store.rating.toStringAsFixed(1),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '编辑店铺',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _showEditDialog(store),
                ),
              ],
            ),
          ),
          const Divider(),
          // Basic info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  icon: Icons.phone,
                  label: '联系电话',
                  value: store.phone.isNotEmpty ? store.phone : '未设置',
                ),
                _InfoRow(
                  icon: Icons.access_time,
                  label: '营业时间',
                  value: store.businessHours.isNotEmpty
                      ? store.businessHours
                      : '未设置',
                ),
                _InfoRow(
                  icon: Icons.tag,
                  label: '特色标签',
                  value: store.featureTags.isNotEmpty
                      ? store.featureTags
                      : '未设置',
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.location_on,
                  label: '地址',
                  value: '${store.city} ${store.district} ${store.address}',
                ),
                _InfoRow(
                  icon: Icons.pin_drop,
                  label: '经纬度',
                  value:
                      '${store.longitude.toStringAsFixed(4)}, ${store.latitude.toStringAsFixed(4)}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isOpen = status == 'OPEN';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen ? Colors.green.withAlpha(20) : Colors.red.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isOpen ? '营业中' : '已关闭',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isOpen ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  Future<void> _showEditDialog(PetStore store) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _StoreEditDialog(store: store, apiClient: widget.apiClient),
    );
    if (result == null) return;
    try {
      await widget.apiClient.updateStore(store.id, result);
      if (mounted) showSuccess(context, '店铺信息更新成功');
      await load();
    } catch (e) {
      if (mounted) showError(context, e.toString());
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreEditDialog extends StatefulWidget {
  final PetStore store;
  const _StoreEditDialog({required this.store, required this.apiClient});
  final ApiClient apiClient;

  @override
  State<_StoreEditDialog> createState() => _StoreEditDialogState();
}

class _StoreEditDialogState extends State<_StoreEditDialog> {
  late final nameCtrl = TextEditingController(text: widget.store.name);
  late final addressCtrl = TextEditingController(text: widget.store.address);
  late String _province;
  late String _city;
  late String _district;
  late List<String> _cities;
  late List<String> _districts;
  late final longitudeCtrl = TextEditingController(
    text: widget.store.longitude.toString(),
  );
  late final latitudeCtrl = TextEditingController(
    text: widget.store.latitude.toString(),
  );
  late final phoneCtrl = TextEditingController(text: widget.store.phone);
  late final hoursCtrl = TextEditingController(
    text: widget.store.businessHours,
  );
  late final tagsCtrl = TextEditingController(text: widget.store.featureTags);
  String status = 'OPEN';

  @override
  void initState() {
    super.initState();
    status = widget.store.status;
    _province = '浙江省';
    _city = widget.store.city.isNotEmpty ? widget.store.city : '杭州市';
    _cities = CityData.citiesOf(_province);
    _districts = CityData.districtsOf(_province, _city);
    _district = widget.store.district.isNotEmpty ? widget.store.district : _districts.first;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    addressCtrl.dispose();
    longitudeCtrl.dispose();
    latitudeCtrl.dispose();
    phoneCtrl.dispose();
    hoursCtrl.dispose();
    tagsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑店铺信息'),
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
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(flex: 3, child: DropdownButtonFormField<String>(
                  value: _province,
                  decoration: const InputDecoration(labelText: '省', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 14)),
                  items: CityData.provinces.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) { setState(() { _province = v!; _cities = CityData.citiesOf(_province); _city = _cities.first; _districts = CityData.districtsOf(_province, _city); _district = _districts.first; }); },
                )),
                const SizedBox(width: 8),
                Expanded(flex: 3, child: DropdownButtonFormField<String>(
                  value: _city,
                  decoration: const InputDecoration(labelText: '市', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 14)),
                  items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) { setState(() { _city = v!; _districts = CityData.districtsOf(_province, _city); _district = _districts.first; }); },
                )),
                const SizedBox(width: 8),
                Expanded(flex: 3, child: DropdownButtonFormField<String>(
                  value: _district,
                  decoration: const InputDecoration(labelText: '区', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 14)),
                  items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) => setState(() => _district = v!),
                )),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: TextField(controller: longitudeCtrl, decoration: const InputDecoration(labelText: '经度'), keyboardType: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: latitudeCtrl, decoration: const InputDecoration(labelText: '纬度'), keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 6),
              OutlinedButton.icon(onPressed: _openMapPicker, icon: const Icon(Icons.map, size: 18), label: const Text('在地图上选点')),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: '联系电话')),
              const SizedBox(height: 10),
              TextField(
                controller: hoursCtrl,
                decoration: const InputDecoration(labelText: '营业时间'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: tagsCtrl,
                decoration: const InputDecoration(labelText: '特色标签（用逗号分隔）'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(labelText: '营业状态'),
                items: const [
                  DropdownMenuItem(value: 'OPEN', child: Text('营业中')),
                  DropdownMenuItem(value: 'CLOSED', child: Text('已关闭')),
                ],
                onChanged: (value) => setState(() => status = value ?? status),
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
              'province': _province,
              'city': _city,
              'district': _district,
              'longitude':
                  double.tryParse(longitudeCtrl.text) ?? widget.store.longitude,
              'latitude':
                  double.tryParse(latitudeCtrl.text) ?? widget.store.latitude,
              'phone': phoneCtrl.text.trim(),
              'businessHours': hoursCtrl.text.trim(),
              'featureTags': tagsCtrl.text.trim(),
              'status': status,
            };
            Navigator.pop(context, payload);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }

  Future<void> _openMapPicker() async {
    double lng = CityData.cityCoord(_province, _city)[0];
    double lat = CityData.cityCoord(_province, _city)[1];
    try {
      final geo = await widget.apiClient.geocode(CityData.addressForGeocode(_province, _city, _district));
      lng = geo.longitude;
      lat = geo.latitude;
    } catch (_) {}
    final result = await Navigator.push<MapPickerResult>(context, MaterialPageRoute(
      builder: (_) => MapPickerPage(apiClient: widget.apiClient, lng: lng, lat: lat),
    ));
    if (result == null) return;
    longitudeCtrl.text = result.longitude.toString();
    latitudeCtrl.text = result.latitude.toString();
  }
}
