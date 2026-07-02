import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/session/session_store.dart';
import '../../../core/theme/app_theme.dart';

class MerchantRegisterPage extends StatefulWidget {
  const MerchantRegisterPage({
    required this.apiClient,
    required this.sessionStore,
    this.onSuccess,
    super.key,
  });
  final ApiClient apiClient;
  final SessionStore sessionStore;
  final VoidCallback? onSuccess;

  @override
  State<MerchantRegisterPage> createState() => _MerchantRegisterPageState();
}

class _MerchantRegisterPageState extends State<MerchantRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _addressCtrl.dispose();
    _hoursCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final user = widget.sessionStore.user!;

      // 1. Upgrade user role to MERCHANT
      await widget.apiClient.updateUser(user.id, {
        'username': user.username,
        'displayName': user.displayName,
        'role': 'MERCHANT',
        'memberLevel': user.memberLevel,
        'phone': _phoneCtrl.text.trim(),
        'email': user.email,
      });

      // 2. Update local session
      widget.sessionStore.updateUser(user.copyWithRole('MERCHANT'));

      // 3. Create store
      await widget.apiClient.createStore({
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'district': _districtCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'businessHours': _hoursCtrl.text.trim(),
        'tags': _tagsCtrl.text.trim(),
        'longitude': 0.0,
        'latitude': 0.0,
        'status': 'OPEN',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('入驻成功！欢迎成为 PawMart 商家')),
      );
      widget.onSuccess?.call();
    } catch (e) {
      if (!mounted) return;
      // Even if store creation fails, role upgrade may have succeeded
      if (widget.sessionStore.isMerchant) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('入驻成功！请前往商家后台完善店铺信息')),
        );
        widget.onSuccess?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('入驻失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: PawmartColors.surfaceBg,
      appBar: AppBar(
        title: const Text('商家入驻'),
      ),
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
                        colors: [PawmartColors.primary400, PawmartColors.primary600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.storefront_rounded, size: 48, color: Colors.white),
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

                  _buildField('店铺名称 *', _nameCtrl, Icons.store, (v) => (v ?? '').trim().isEmpty ? '请输入店铺名称' : null),
                  const SizedBox(height: 14),
                  _buildField('联系电话 *', _phoneCtrl, Icons.phone, (v) {
                    if ((v ?? '').trim().isEmpty) return '请输入联系电话';
                    if ((v ?? '').trim().length < 7) return '请输入有效电话号码';
                    return null;
                  }, keyboardType: TextInputType.phone),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _buildField('城市 *', _cityCtrl, Icons.location_city, (v) => (v ?? '').trim().isEmpty ? '请输入城市' : null)),
                      const SizedBox(width: 14),
                      Expanded(child: _buildField('区域 *', _districtCtrl, Icons.map, (v) => (v ?? '').trim().isEmpty ? '请输入区域' : null)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildField('详细地址 *', _addressCtrl, Icons.location_on, (v) => (v ?? '').trim().isEmpty ? '请输入详细地址' : null),
                  const SizedBox(height: 14),
                  _buildField('营业时间', _hoursCtrl, Icons.schedule, null, hint: '如：9:00-21:00'),
                  const SizedBox(height: 14),
                  _buildField('特色标签', _tagsCtrl, Icons.label_outline, null, hint: '用逗号分隔，如：宠物美容,活体销售'),

                  const SizedBox(height: 32),

                  // Submit
                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      onPressed: _submitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: PawmartColors.primary500,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Text('确认入驻', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),

                  const SizedBox(height: 14),
                  SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _submitting ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PawmartColors.textSecondary,
                        side: BorderSide(color: PawmartColors.neutral200),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('返回', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
    return const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: PawmartColors.textPrimary);
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
        Text(label, style: TextStyle(fontSize: 13, color: PawmartColors.textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(fontSize: 14, color: PawmartColors.textPrimary),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: PawmartColors.neutral400),
            hintText: hint ?? '请输入$label',
            hintStyle: TextStyle(fontSize: 14, color: PawmartColors.textSecondary.withAlpha(150)),
            filled: true,
            fillColor: PawmartColors.surfaceCard,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              borderSide: const BorderSide(color: PawmartColors.primary500, width: 1.5),
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
