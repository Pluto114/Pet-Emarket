/// 用户个人中心 — 信息展示 + 编辑 + 退出
library;

import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/session/session_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/app_user.dart';
import '../../../models/merchant_application.dart';
import '../../../shared/widgets/city_data.dart';
import '../../../shared/widgets/map_picker_page.dart';
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
                            user.memberLevelLabel,
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
                      '累计消费 ¥${user.totalSpent.toStringAsFixed(0)}  |  积分 ${user.pointsBalance}',
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

        const SizedBox(height: 16),

        // ═══ Membership Upgrade Progress ═══
        if (user.nextLevelThreshold > 0)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: PawmartColors.surfaceCard,
                borderRadius: BorderRadius.circular(pawmartRadiusMd),
                boxShadow: pawmartShadow1,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_up, size: 18, color: PawmartColors.accent400),
                      const SizedBox(width: 8),
                      Text(
                        '升级进度',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: PawmartColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '距${user.nextLevelLabel}还需 ¥${user.amountToNextLevel.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: PawmartColors.accent400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: user.levelProgress,
                      minHeight: 8,
                      backgroundColor: PawmartColors.neutral200,
                      valueColor: AlwaysStoppedAnimation(PawmartColors.accent400),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '¥${user.totalSpent.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 11, color: PawmartColors.textSecondary),
                      ),
                      const Spacer(),
                      Text(
                        '¥${user.nextLevelThreshold.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 11, color: PawmartColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),

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
                _fontSizeTile(),
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
        // Merchant Application — CUSTOMER 和 MERCHANT 都可申请
        if (user.role != 'ADMIN') _merchantApplicationCard(),
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

  Widget _fontSizeTile() {
    final s = widget.sessionStore.textScale;
    final labels = {1.0: '标准', 1.25: '大号', 1.5: '特大'};
    return ListTile(
      leading: const Icon(Icons.text_fields, color: PawmartColors.textSecondary),
      title: const Text('字体大小'),
      trailing: SegmentedButton<double>(
        segments: const [
          ButtonSegment(value: 1.0, label: Text('标准', style: TextStyle(fontSize: 11))),
          ButtonSegment(value: 1.25, label: Text('大号', style: TextStyle(fontSize: 11))),
          ButtonSegment(value: 1.5, label: Text('特大', style: TextStyle(fontSize: 11))),
        ],
        selected: {s},
        onSelectionChanged: (v) => widget.sessionStore.setTextScale(v.first),
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
    final isMerchant = widget.sessionStore.user?.role == 'MERCHANT';
    final hasPending = applications.any((a) => a.status == 'PENDING');
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
            Row(children: [
              Icon(Icons.storefront_outlined, color: PawmartColors.primary500),
              const SizedBox(width: 10),
              Expanded(child: Text(isMerchant ? '店铺管理' : '申请成为商家',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: PawmartColors.textPrimary))),
              if (isMerchant) Icon(Icons.verified, color: PawmartColors.success, size: 20),
              if (applicationLoading) const Padding(padding: EdgeInsets.only(left: 8), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
            ]),
            const SizedBox(height: 8),
            // 申请历史
            if (applications.isNotEmpty) ...[
              const SizedBox(height: 4),
              ...applications.take(3).map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(
                    color: a.status == 'APPROVED' ? Colors.green : a.status == 'PENDING' ? Colors.orange : Colors.red,
                    shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(a.storeName, style: TextStyle(fontSize: 13, color: PawmartColors.textPrimary))),
                  Text(_statusLabel(a.status), style: TextStyle(fontSize: 12, color: _statusColor(a.status))),
                ]),
              )),
              if (applications.length > 3) Text('...还有 ${applications.length - 3} 条申请', style: TextStyle(fontSize: 12, color: PawmartColors.textSecondary)),
              const SizedBox(height: 8),
            ] else
              Text('提交门店信息后，由管理员审核，通过后自动开通商家工作台。',
                  style: TextStyle(fontSize: 13, color: PawmartColors.textSecondary)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: FilledButton.icon(
                onPressed: hasPending ? null : _submitMerchantApplication,
                icon: Icon(isMerchant ? Icons.add_business : Icons.assignment_ind_outlined, size: 18),
                label: Text(hasPending ? '审核中' : (isMerchant ? '申请新店铺' : '提交申请'),
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String s) => switch (s) { 'PENDING' => '审核中', 'APPROVED' => '已通过', 'REJECTED' => '已驳回', _ => s };
  Color _statusColor(String s) => switch (s) { 'PENDING' => Colors.orange, 'APPROVED' => Colors.green, 'REJECTED' => Colors.red, _ => PawmartColors.textSecondary };

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
  final _name = TextEditingController(), _address = TextEditingController(), _phone = TextEditingController();
  final _lng = TextEditingController(text: '120.1551'), _lat = TextEditingController(text: '30.2741');
  final _license = TextEditingController(), _reason = TextEditingController();
  String _province = '浙江省', _city = '杭州市', _district = '西湖区';
  List<String> _cities = CityData.citiesOf('浙江省'), _districts = CityData.districtsOf('浙江省', '杭州市');
  bool _picked = false;

  @override
  void dispose() { _name.dispose(); _address.dispose(); _phone.dispose(); _lng.dispose(); _lat.dispose(); _license.dispose(); _reason.dispose(); super.dispose(); }

  Future<void> _openMap() async {
    double lng = CityData.cityCoord(_province, _city)[0], lat = CityData.cityCoord(_province, _city)[1];
    try {
      final addr = CityData.addressForGeocode(_province, _city, _district);
      final geo = await ApiClient(sessionStore: SessionStore()).geocode(addr, city: _city);
      lng = geo.longitude; lat = geo.latitude;
    } catch (_) {}
    final r = await Navigator.push<MapPickerResult>(context, MaterialPageRoute(builder: (_) => MapPickerPage(apiClient: ApiClient(sessionStore: SessionStore()), lng: lng, lat: lat)));
    if (r == null) return;
    _lng.text = r.longitude.toString(); _lat.text = r.latitude.toString(); _picked = true;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('申请成为商家'),
    content: SizedBox(width: 520, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: _name, decoration: const InputDecoration(labelText: '店铺名称 *')),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(flex: 3, child: DropdownButtonFormField<String>(value: _province, decoration: const InputDecoration(labelText: '省', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 14)),
          items: CityData.provinces.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (v) => setState(() { _province = v!; _cities = CityData.citiesOf(_province); _city = _cities.first; _districts = CityData.districtsOf(_province, _city); _district = _districts.first; }))),
        const SizedBox(width: 6),
        Expanded(flex: 3, child: DropdownButtonFormField<String>(value: _city, decoration: const InputDecoration(labelText: '市', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 14)),
          items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (v) => setState(() { _city = v!; _districts = CityData.districtsOf(_province, _city); _district = _districts.first; }))),
        const SizedBox(width: 6),
        Expanded(flex: 3, child: DropdownButtonFormField<String>(value: _district, decoration: const InputDecoration(labelText: '区', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 14)),
          items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (v) => setState(() => _district = v!))),
      ]),
      const SizedBox(height: 10),
      TextField(controller: _address, decoration: const InputDecoration(labelText: '详细地址 *')),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: TextField(controller: _lng, decoration: const InputDecoration(labelText: '经度'), keyboardType: TextInputType.number)),
        const SizedBox(width: 8),
        Expanded(child: TextField(controller: _lat, decoration: const InputDecoration(labelText: '纬度'), keyboardType: TextInputType.number)),
      ]),
      const SizedBox(height: 6),
      OutlinedButton.icon(onPressed: _openMap, icon: const Icon(Icons.map, size: 16), label: const Text('在地图上选点')),
      const SizedBox(height: 10),
      TextField(controller: _phone, decoration: const InputDecoration(labelText: '联系电话'), keyboardType: TextInputType.phone),
      const SizedBox(height: 10),
      TextField(controller: _license, decoration: const InputDecoration(labelText: '营业执照号')),
      const SizedBox(height: 10),
      TextField(controller: _reason, decoration: const InputDecoration(labelText: '申请说明'), maxLines: 2),
    ]))),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
      FilledButton(onPressed: () {
        if (_name.text.trim().isEmpty || _address.text.trim().isEmpty) { showError(context, '请填写店铺名称和详细地址'); return; }
        Navigator.pop(context, {'storeName': _name.text.trim(), 'city': _city, 'district': _district, 'address': _address.text.trim(), 'longitude': double.tryParse(_lng.text) ?? 120.1551, 'latitude': double.tryParse(_lat.text) ?? 30.2741, 'contactName': '', 'contactPhone': _phone.text.trim(), 'businessLicenseNo': _license.text.trim(), 'reason': _reason.text.trim()});
      }, child: const Text('提交')),
    ],
  );
}
