import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/session/session_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/map_picker_page.dart';
import '../../../shared/widgets/city_data.dart';

class MerchantRegisterPage extends StatefulWidget {
  const MerchantRegisterPage({
    required this.apiClient,
    required this.sessionStore,
    super.key,
  });
  final ApiClient apiClient;
  final SessionStore sessionStore;

  @override
  State<MerchantRegisterPage> createState() => _MerchantRegisterPageState();
}

class _MerchantRegisterPageState extends State<MerchantRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _province = '浙江省';
  String _city = '杭州市';
  String _district = '西湖区';
  List<String> _cities = CityData.citiesOf('浙江省');
  List<String> _districts = CityData.districtsOf('浙江省', '杭州市');
  final _addressCtrl = TextEditingController();
  final _longitudeCtrl = TextEditingController(text: '120.1551');
  final _latitudeCtrl = TextEditingController(text: '30.2741');
  final _hoursCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  bool _submitting = false;
  bool _locationPickedManually = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _longitudeCtrl.dispose();
    _latitudeCtrl.dispose();
    _hoursCtrl.dispose();
    _licenseCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _openMapPicker() async {
    double lng = double.tryParse(_longitudeCtrl.text.trim()) ?? CityData.cityCoord(_province, _city)[0];
    double lat = double.tryParse(_latitudeCtrl.text.trim()) ?? CityData.cityCoord(_province, _city)[1];
    // 尝试通过高德正地理编码获取更精确坐标
    try {
      final addr = _fullAddress();
      final geo = await widget.apiClient.geocode(addr, city: _city);
      lng = geo.longitude;
      lat = geo.latitude;
    } catch (_) {}
    final result = await Navigator.push<MapPickerResult>(context, MaterialPageRoute(
      builder: (_) => MapPickerPage(apiClient: widget.apiClient, lng: lng, lat: lat),
    ));
    if (result == null) return;
    _longitudeCtrl.text = result.longitude.toString();
    _latitudeCtrl.text = result.latitude.toString();
    _locationPickedManually = true;
  }

  String _fullAddress() {
    final detail = _addressCtrl.text.trim();
    if (detail.isEmpty) return CityData.addressForGeocode(_province, _city, _district);
    return '$_province$_city$_district$detail';
  }

  Future<void> _syncCoordinatesFromAddress() async {
    if (_locationPickedManually) return;
    try {
      final geo = await widget.apiClient.geocode(_fullAddress(), city: _city);
      if (geo.longitude != 0 && geo.latitude != 0) {
        _longitudeCtrl.text = geo.longitude.toString();
        _latitudeCtrl.text = geo.latitude.toString();
      }
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      await _syncCoordinatesFromAddress();
      final user = widget.sessionStore.user;
      await widget.apiClient.submitMerchantApplication({
        'storeName': _nameCtrl.text.trim(),
        'province': _province,
        'city': _city,
        'district': _district,
        'address': _addressCtrl.text.trim(),
        'longitude': double.tryParse(_longitudeCtrl.text.trim()) ?? 120.1551,
        'latitude': double.tryParse(_latitudeCtrl.text.trim()) ?? 30.2741,
        'contactName': user?.displayName ?? '',
        'contactPhone': _phoneCtrl.text.trim(),
        'businessLicenseNo': _licenseCtrl.text.trim(),
        'reason':
            _reasonCtrl.text.trim().isEmpty
                ? _hoursCtrl.text.trim()
                : _reasonCtrl.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('入驻申请已提交，请等待管理员审核')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('提交失败：$e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: PawmartColors.surfaceBg,
      appBar: AppBar(title: const Text('商家入驻')),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(wide ? 40 : 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          PawmartColors.primary400,
                          PawmartColors.primary600,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.storefront_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                        SizedBox(height: 12),
                        Text(
                          '成为 PawMart 商家',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '填写店铺基本信息，开启你的宠物事业',
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Form fields
                  Text('店铺信息', style: _sectionLabel()),
                  const SizedBox(height: 14),

                  _buildField(
                    '店铺名称 *',
                    _nameCtrl,
                    Icons.store,
                    (v) => (v ?? '').trim().isEmpty ? '请输入店铺名称' : null,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    '联系电话 *',
                    _phoneCtrl,
                    Icons.phone,
                    (v) {
                      if ((v ?? '').trim().isEmpty) return '请输入联系电话';
                      if ((v ?? '').trim().length < 7) return '请输入有效电话号码';
                      return null;
                    },
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(flex: 3, child: DropdownButtonFormField<String>(
                      value: _province,
                      decoration: const InputDecoration(labelText: '省', prefixIcon: Icon(Icons.public), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 14)),
                      items: CityData.provinces.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (v) { setState(() { _province = v!; _cities = CityData.citiesOf(_province); _city = _cities.first; _districts = CityData.districtsOf(_province, _city); _district = _districts.first; }); },
                    )),
                    const SizedBox(width: 8),
                    Expanded(flex: 3, child: DropdownButtonFormField<String>(
                      value: _city,
                      decoration: const InputDecoration(labelText: '市', prefixIcon: Icon(Icons.location_city), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 14)),
                      items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (v) { setState(() { _city = v!; _districts = CityData.districtsOf(_province, _city); _district = _districts.first; }); },
                    )),
                    const SizedBox(width: 8),
                    Expanded(flex: 3, child: DropdownButtonFormField<String>(
                      value: _district,
                      decoration: const InputDecoration(labelText: '区', prefixIcon: Icon(Icons.map), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 14)),
                      items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (v) => setState(() => _district = v!),
                    )),
                  ]),
                  const SizedBox(height: 14),
                  _buildField(
                    '详细地址 *',
                    _addressCtrl,
                    Icons.location_on,
                    (v) => (v ?? '').trim().isEmpty ? '请输入详细地址' : null,
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _buildField('经度 *', _longitudeCtrl, Icons.explore, (v) => double.tryParse((v ?? '').trim()) == null ? '请输入有效经度' : null, keyboardType: TextInputType.number)),
                    const SizedBox(width: 14),
                    Expanded(child: _buildField('纬度 *', _latitudeCtrl, Icons.explore_outlined, (v) => double.tryParse((v ?? '').trim()) == null ? '请输入有效纬度' : null, keyboardType: TextInputType.number)),
                  ]),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _openMapPicker,
                    icon: const Icon(Icons.map, size: 18),
                    label: const Text('在地图上选点'),
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    '营业时间',
                    _hoursCtrl,
                    Icons.schedule,
                    null,
                    hint: '如：9:00-21:00',
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    '营业执照号',
                    _licenseCtrl,
                    Icons.badge_outlined,
                    null,
                    hint: '可选',
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    '申请说明',
                    _reasonCtrl,
                    Icons.description_outlined,
                    null,
                    hint: '可填写经营范围、特色服务等',
                  ),

                  const SizedBox(height: 32),

                  // Submit
                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      onPressed: _submitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: PawmartColors.primary500,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child:
                          _submitting
                              ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                              : const Text(
                                '确认入驻',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                    ),
                  ),

                  const SizedBox(height: 14),
                  SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed:
                          _submitting ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PawmartColors.textSecondary,
                        side: BorderSide(color: PawmartColors.neutral200),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        '返回',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextStyle _sectionLabel() {
    return const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: PawmartColors.textPrimary,
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    IconData icon,
    String? Function(String?)? validator, {
    String? hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: PawmartColors.textSecondary),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(fontSize: 14, color: PawmartColors.textPrimary),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: PawmartColors.neutral400),
            hintText: hint ?? '请输入$label',
            hintStyle: TextStyle(
              fontSize: 14,
              color: PawmartColors.textSecondary.withAlpha(150),
            ),
            filled: true,
            fillColor: PawmartColors.surfaceCard,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: PawmartColors.neutral200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: PawmartColors.neutral200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: PawmartColors.primary500,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: PawmartColors.error),
            ),
          ),
        ),
      ],
    );
  }
}
