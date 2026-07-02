/// 用户个人中心 — 信息展示 + 编辑 + 退出
library;

import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/session/session_store.dart';
import '../../../models/app_user.dart';
import '../../../models/merchant_application.dart';
import '../../../shared/widgets/toast.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({
    required this.apiClient,
    required this.sessionStore,
    required this.onThemeToggle,
    required this.onLogout,
    super.key,
  });

  final ApiClient apiClient;
  final SessionStore sessionStore;
  final VoidCallback onThemeToggle;
  final VoidCallback onLogout;

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool applicationLoading = false;
  List<MerchantApplication> applications = [];

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    if (widget.sessionStore.user == null) return;
    setState(() => applicationLoading = true);
    try {
      applications = await widget.apiClient.myMerchantApplications();
    } catch (_) {
      applications = [];
    }
    if (mounted) setState(() => applicationLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = widget.sessionStore.user;

    if (user == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_outline,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text('Please sign in first', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: widget.onLogout,
              child: const Text('Go to Login'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    user.displayName.isNotEmpty
                        ? user.displayName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 24,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${user.username}  |  ${user.role}  |  ${user.memberLevel}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _InfoCard(
          icon: Icons.phone,
          title: 'Phone',
          value: user.phone.isNotEmpty ? user.phone : 'Not set',
        ),
        _InfoCard(
          icon: Icons.email,
          title: 'Email',
          value: user.email.isNotEmpty ? user.email : 'Not set',
        ),
        _InfoCard(icon: Icons.verified_user, title: 'Role', value: user.role),
        _InfoCard(
          icon: Icons.workspace_premium,
          title: 'Member Level',
          value: user.memberLevel,
        ),
        _InfoCard(
          icon: Icons.stars_outlined,
          title: 'Points',
          value: user.pointsBalance.toString(),
        ),
        const SizedBox(height: 12),
        if (user.role == 'CUSTOMER') _merchantApplicationCard(theme),
        if (user.role == 'MERCHANT')
          Card(
            child: ListTile(
              leading: const Icon(Icons.storefront),
              title: const Text('商家身份已开通'),
              subtitle: const Text('请从商家工作台维护店铺、商品和订单'),
              trailing: const Icon(Icons.verified),
            ),
          ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: const Text('Edit Profile'),
          onTap: () => _editProfile(user),
        ),
        ListTile(
          leading: const Icon(Icons.brightness_6),
          title: const Text('Toggle Theme'),
          onTap: widget.onThemeToggle,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: widget.onLogout,
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
        ),
      ],
    );
  }

  Widget _merchantApplicationCard(ThemeData theme) {
    final latest = applications.isEmpty ? null : applications.first;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.storefront_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '申请成为商家',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (applicationLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              latest == null
                  ? '提交门店信息后，由管理员审核，通过后自动开通商家工作台。'
                  : '最近申请：${latest.storeName} · ${latest.status}${latest.auditRemark.isEmpty ? '' : ' · ${latest.auditRemark}'}',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed:
                  latest?.status == 'PENDING'
                      ? null
                      : _submitMerchantApplication,
              icon: const Icon(Icons.assignment_ind_outlined),
              label: Text(latest?.status == 'PENDING' ? '审核中' : '提交申请'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitMerchantApplication() async {
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _MerchantApplyDialog(),
    );
    if (payload == null) return;
    try {
      await widget.apiClient.submitMerchantApplication(payload);
      await _loadApplications();
      if (mounted) showSuccess(context, '商家申请已提交，等待管理员审核');
    } catch (e) {
      if (mounted) showError(context, e.toString());
    }
  }

  Future<void> _editProfile(AppUser user) async {
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _EditDialog(user: user),
    );
    if (payload == null) return;
    try {
      final updated = await widget.apiClient.updateUser(user.id, payload);
      widget.sessionStore.updateUser(updated);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile updated')));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

class _EditDialog extends StatefulWidget {
  const _EditDialog({required this.user});
  final AppUser user;
  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late final dn = TextEditingController(text: widget.user.displayName);
  late final ph = TextEditingController(text: widget.user.phone);
  late final em = TextEditingController(text: widget.user.email);
  final pw = TextEditingController();

  @override
  void dispose() {
    dn.dispose();
    ph.dispose();
    em.dispose();
    pw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Profile'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dn,
                decoration: const InputDecoration(labelText: 'Display Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ph,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: em,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: pw,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password (optional)',
                ),
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
          onPressed:
              () => Navigator.pop(context, {
                'username': widget.user.username,
                'displayName': dn.text.trim(),
                'phone': ph.text.trim(),
                'email': em.text.trim(),
                if (pw.text.isNotEmpty) 'password': pw.text,
              }),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _MerchantApplyDialog extends StatefulWidget {
  const _MerchantApplyDialog();

  @override
  State<_MerchantApplyDialog> createState() => _MerchantApplyDialogState();
}

class _MerchantApplyDialogState extends State<_MerchantApplyDialog> {
  final storeName = TextEditingController();
  final city = TextEditingController(text: '杭州');
  final district = TextEditingController(text: '西湖区');
  final address = TextEditingController();
  final longitude = TextEditingController(text: '120.1551');
  final latitude = TextEditingController(text: '30.2741');
  final contactName = TextEditingController();
  final contactPhone = TextEditingController();
  final licenseNo = TextEditingController();
  final reason = TextEditingController();

  @override
  void dispose() {
    storeName.dispose();
    city.dispose();
    district.dispose();
    address.dispose();
    longitude.dispose();
    latitude.dispose();
    contactName.dispose();
    contactPhone.dispose();
    licenseNo.dispose();
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('申请成为商家'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: storeName,
                decoration: const InputDecoration(labelText: '店铺名称'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: city,
                      decoration: const InputDecoration(labelText: '城市'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: district,
                      decoration: const InputDecoration(labelText: '区域'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: address,
                decoration: const InputDecoration(labelText: '详细地址'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: longitude,
                      decoration: const InputDecoration(labelText: '经度'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: latitude,
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
                      controller: contactName,
                      decoration: const InputDecoration(labelText: '联系人'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: contactPhone,
                      decoration: const InputDecoration(labelText: '联系电话'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: licenseNo,
                decoration: const InputDecoration(labelText: '营业执照号'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: reason,
                decoration: const InputDecoration(labelText: '申请说明'),
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
            if (storeName.text.trim().isEmpty || address.text.trim().isEmpty) {
              showError(context, '请填写店铺名称和详细地址');
              return;
            }
            Navigator.pop(context, {
              'storeName': storeName.text.trim(),
              'city': city.text.trim(),
              'district': district.text.trim(),
              'address': address.text.trim(),
              'longitude': double.tryParse(longitude.text) ?? 120.1551,
              'latitude': double.tryParse(latitude.text) ?? 30.2741,
              'contactName': contactName.text.trim(),
              'contactPhone': contactPhone.text.trim(),
              'businessLicenseNo': licenseNo.text.trim(),
              'reason': reason.text.trim(),
            });
          },
          child: const Text('提交'),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });
  final IconData icon;
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: Text(value),
      ),
    );
  }
}
