/// 用户个人中心 — 信息展示 + 编辑 + 退出
library;

import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/session/session_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/app_user.dart';
import '../../../models/merchant_application.dart';
import '../../../shared/widgets/toast.dart';
import '../order/order_page.dart';

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
    final user = widget.sessionStore.user;

    if (user == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_outline,
              size: 64,
              color: PawmartColors.neutral400,
            ),
            const SizedBox(height: 16),
            Text(
              '请先登录',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: PawmartColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: widget.onLogout,
              style: FilledButton.styleFrom(
                backgroundColor: PawmartColors.accent400,
                foregroundColor: PawmartColors.textOnAccent,
              ),
              child: const Text('去登录'),
            ),
          ],
        ),
      );
    }

    final w = MediaQuery.of(context).size.width;
    final wide = w > 800;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // ═══ Profile Header (Green Banner) ═══
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            wide ? 40 : 20,
            24,
            wide ? 40 : 20,
            24,
          ),
          decoration: BoxDecoration(
            color: PawmartColors.primary500,
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: PawmartColors.neutral100,
                  border: Border.all(
                    color: PawmartColors.primary300,
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Text(
                    user.displayName.isNotEmpty
                        ? user.displayName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: PawmartColors.primary600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.displayName,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: PawmartColors.accent400,
                            borderRadius: BorderRadius.circular(
                              pawmartRadiusFull,
                            ),
                          ),
                          child: Text(
                            _memberBadge(user.memberLevel),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: PawmartColors.textOnAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '会员等级: ${user.memberLevel}  |  积分: ${user.pointsBalance}',
                      style: TextStyle(
                        fontSize: 13,
                        color: PawmartColors.primary100,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ═══ Order Stats Row ═══
        Container(
          margin: EdgeInsets.symmetric(horizontal: wide ? 40 : 16),
          decoration: BoxDecoration(
            color: PawmartColors.surfaceCard,
            borderRadius: BorderRadius.circular(pawmartRadiusMd),
            boxShadow: pawmartShadow1,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                _orderStatItem(Icons.wallet_outlined, '待付款', '0', _warnColor(), _warnColor()),
                _orderStatDivider(),
                _orderStatItem(Icons.inventory_2_outlined, '待发货', '0', PawmartColors.info, _infoColor()),
                _orderStatDivider(),
                _orderStatItem(Icons.local_shipping_outlined, '待收货', '0', PawmartColors.primary500, PawmartColors.primary500),
                _orderStatDivider(),
                _orderStatItem(Icons.rate_review_outlined, '待评价', '0', PawmartColors.accent600, _accentColor()),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ═══ Two-Column Layout ═══
        Padding(
          padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 16),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _leftColumn(user)),
                    const SizedBox(width: 16),
                    Expanded(child: _rightColumn(user)),
                  ],
                )
              : Column(
                  children: [
                    _leftColumn(user),
                    const SizedBox(height: 16),
                    _rightColumn(user),
                  ],
                ),
        ),

        const SizedBox(height: 20),

        // ═══ Settings ═══
        Padding(
          padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 16),
          child: Container(
            decoration: BoxDecoration(
              color: PawmartColors.surfaceCard,
              borderRadius: BorderRadius.circular(pawmartRadiusMd),
              boxShadow: pawmartShadow1,
            ),
            child: Column(
              children: [
                _settingsTile(
                  Icons.edit_outlined,
                  '编辑资料',
                  onTap: () => _editProfile(user),
                ),
                const Divider(height: 1, indent: 52),
                _settingsTile(
                  Icons.brightness_6_outlined,
                  '切换主题',
                  onTap: widget.onThemeToggle,
                ),
                const Divider(height: 1, indent: 52),
                _settingsTile(
                  Icons.logout,
                  '退出登录',
                  textColor: PawmartColors.error,
                  onTap: widget.onLogout,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 100),
      ],
    );
  }

  // Color helpers
  Color _warnColor() => const Color(0xFFE8BF20);
  Color _infoColor() => const Color(0xFF388EDC);
  Color _accentColor() => const Color(0xFFB5B520);

  String _memberBadge(String level) {
    switch (level) {
      case 'VIP':
      case 'GOLD':
        return 'VIP会员';
      case 'SILVER':
        return '银卡会员';
      default:
        return '普通会员';
    }
  }

  Widget _orderStatItem(IconData icon, String label, String count, Color iconColor, Color countColor) {
    return Expanded(
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(pawmartRadiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(height: 4),
              Text(
                count,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: countColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: PawmartColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _orderStatDivider() {
    return Container(
      width: 1,
      height: 48,
      color: PawmartColors.neutral200,
    );
  }

  Widget _leftColumn(AppUser user) {
    return Column(
      children: [
        // My Info Card
        _sectionCard(
          title: '个人信息',
          children: [
            _infoRow(Icons.person_outline, '用户名', '@${user.username}'),
            const Divider(height: 1),
            _infoRow(Icons.phone_outlined, '手机', user.phone.isNotEmpty ? user.phone : '未设置'),
            const Divider(height: 1),
            _infoRow(Icons.email_outlined, '邮箱', user.email.isNotEmpty ? user.email : '未设置'),
            const Divider(height: 1),
            _infoRow(Icons.workspace_premium_outlined, '会员等级', user.memberLevel),
            const Divider(height: 1),
            _infoRow(Icons.stars_outlined, '积分', '${user.pointsBalance}'),
          ],
        ),
        const SizedBox(height: 16),
        // Merchant Application / Status
        if (user.role == 'CUSTOMER') _merchantApplicationCard(),
        if (user.role == 'MERCHANT')
          _sectionCard(
            title: '商家状态',
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: PawmartColors.success.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.storefront,
                        color: PawmartColors.success,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '商家身份已开通',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: PawmartColors.textPrimary,
                            ),
                          ),
                          Text(
                            '请从商家工作台维护店铺、商品和订单',
                            style: TextStyle(
                              fontSize: 12,
                              color: PawmartColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.verified,
                      color: PawmartColors.success,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _rightColumn(AppUser user) {
    return Column(
      children: [
        // Quick Actions
        _sectionCard(
          title: '快捷入口',
          children: [
            _settingsTile(
              Icons.shopping_bag_outlined,
              '我的订单',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('我的订单')),
                      body: OrderPage(
                        key: GlobalKey<OrderPageState>(),
                        apiClient: widget.apiClient,
                        sessionStore: widget.sessionStore,
                      ),
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 1, indent: 52),
            _settingsTile(
              Icons.favorite_outline,
              '我的收藏',
              onTap: () => showInfo(context, '收藏功能开发中，敬请期待'),
            ),
            const Divider(height: 1, indent: 52),
            _settingsTile(
              Icons.card_giftcard_outlined,
              '优惠券',
              onTap: () => showInfo(context, '优惠券功能开发中，敬请期待'),
            ),
            const Divider(height: 1, indent: 52),
            _settingsTile(
              Icons.support_agent_outlined,
              '联系客服',
              onTap: () => showInfo(context, '客服热线：400-123-4567（工作日 9:00-18:00）'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // About
        _sectionCard(
          title: '关于',
          children: [
            _infoRow(Icons.info_outline, '版本', 'v1.0.0'),
            const Divider(height: 1),
            _infoRow(Icons.description_outlined, '协议', '用户协议'),
          ],
        ),
      ],
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: PawmartColors.surfaceCard,
        borderRadius: BorderRadius.circular(pawmartRadiusMd),
        boxShadow: pawmartShadow1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: PawmartColors.textPrimary,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: PawmartColors.textSecondary),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: PawmartColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: PawmartColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsTile(
    IconData icon,
    String title, {
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(pawmartRadiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: textColor ?? PawmartColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textColor ?? PawmartColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: PawmartColors.neutral300,
            ),
          ],
        ),
      ),
    );
  }

  Widget _merchantApplicationCard() {
    final latest = applications.isEmpty ? null : applications.first;
    return Container(
      decoration: BoxDecoration(
        color: PawmartColors.surfaceCard,
        borderRadius: BorderRadius.circular(pawmartRadiusMd),
        boxShadow: pawmartShadow1,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storefront_outlined, color: PawmartColors.primary500),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '申请成为商家',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: PawmartColors.textPrimary,
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
              style: TextStyle(
                fontSize: 13,
                color: PawmartColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: FilledButton.icon(
                onPressed:
                    latest?.status == 'PENDING'
                        ? null
                        : _submitMerchantApplication,
                icon: const Icon(Icons.assignment_ind_outlined, size: 18),
                label: Text(
                  latest?.status == 'PENDING' ? '审核中' : '提交申请',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
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
        ).showSnackBar(const SnackBar(content: Text('资料已更新')));
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
      title: const Text('编辑资料'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dn,
                decoration: const InputDecoration(labelText: '昵称'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ph,
                decoration: const InputDecoration(labelText: '手机号'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: em,
                decoration: const InputDecoration(labelText: '邮箱'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: pw,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '新密码（留空不修改）',
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
              () => Navigator.pop(context, {
                'username': widget.user.username,
                'displayName': dn.text.trim(),
                'phone': ph.text.trim(),
                'email': em.text.trim(),
                if (pw.text.isNotEmpty) 'password': pw.text,
              }),
          child: const Text('保存'),
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
