import 'package:flutter/material.dart';
// Using system fonts
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/api/api_client.dart';
import '../../core/session/session_store.dart';
import '../../core/theme/app_theme.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({required this.apiClient, required this.sessionStore, super.key});
  final ApiClient apiClient;
  final SessionStore sessionStore;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _usr = TextEditingController(text: 'admin');
  final _pwd = TextEditingController(text: 'Admin@123456');
  final _dn = TextEditingController(text: 'Pet User');
  final _ph = TextEditingController();
  final _em = TextEditingController();
  bool _reg = false, _busy = false;
  String? _err;

  static const String _ossUrl1 = 'https://pet-emarket.oss-cn-guangzhou.aliyuncs.com/image/pages/410a874a2b333ad076ad6c8f85aefbd2.jpg';
  static const String _ossUrl2 = 'https://pet-emarket.oss-cn-guangzhou.aliyuncs.com/image/pages/9944f9224e6cb20d8b9697fd22624d97.jpg';
  static const String _ossUrl3 = 'https://pet-emarket.oss-cn-guangzhou.aliyuncs.com/image/pages/9e8c37828cc4c7cade02789ab736d64d.jpg';
  static const String _ossUrl4 = 'https://pet-emarket.oss-cn-guangzhou.aliyuncs.com/image/pages/acabf95540953c92ceda9ae6cd9399f1.jpg';

  @override
  void dispose() {
    _usr.dispose();
    _pwd.dispose();
    _dn.dispose();
    _ph.dispose();
    _em.dispose();
    super.dispose();
  }

  Future<void> _sub() async {
    setState(() { _busy = true; _err = null; });
    try {
      if (_reg) {
        await widget.apiClient.register(username: _usr.text.trim(), password: _pwd.text, displayName: _dn.text.trim(), phone: _ph.text.trim(), email: _em.text.trim());
      } else {
        await widget.apiClient.login(username: _usr.text.trim(), password: _pwd.text);
      }
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext ctx) {
    final t = Theme.of(ctx);
    final s = t.colorScheme;
    final screenW = MediaQuery.of(ctx).size.width;
    final wide = screenW > 900;

    return Scaffold(
      backgroundColor: PawmartColors.surfaceBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (wide) _buildSection1Wide(ctx, s) else _buildSection1Narrow(ctx, s),
                _buildPromises(ctx),
                _buildFeatures(ctx),
                _buildCategories(ctx),
                _buildCTA(ctx),
                _buildFooter(ctx),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══ Section 1: Login + Hero (Wide) ═══
  Widget _buildSection1Wide(BuildContext ctx, ColorScheme s) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1200),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 5, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: _buildForm(ctx))),
          const SizedBox(width: 60),
          Expanded(flex: 7, child: _buildHero(ctx)),
        ],
      ),
    );
  }

  // ═══ Section 1: Login + Hero (Narrow) ═══
  Widget _buildSection1Narrow(BuildContext ctx, ColorScheme s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(fit: StackFit.expand, children: [
                CachedNetworkImage(imageUrl: _ossUrl1, fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [PawmartColors.primary100, PawmartColors.primary200])),
                    child: Center(child: Icon(Icons.pets, size: 80, color: PawmartColors.primary300.withAlpha(120))),
                  ),
                ),
                Positioned(bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, PawmartColors.primary700.withAlpha(180)])),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('PawMart', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('为每一只爱宠，找到最贴心的呵护', style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(200))),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 24),
          _buildForm(ctx),
        ],
      ),
    );
  }

  // ═══ Login Form Card ═══
  Widget _buildForm(BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: PawmartColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: pawmartShadow2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Paw brand
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: PawmartColors.primary500, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.pets, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text('PawMart', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: PawmartColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 24),
          // Title
          Text(_reg ? '创建账号' : '欢迎回来', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: PawmartColors.textPrimary)),
          const SizedBox(height: 6),
          Text(_reg ? '注册后开启宠物之旅' : '登录你的账号，探索优质宠物好物', style: TextStyle(fontSize: 16, color: PawmartColors.textSecondary)),
          const SizedBox(height: 24),
          // Form
          _buildField('手机号 / 邮箱', _usr, Icons.person_outline),
          const SizedBox(height: 14),
          _buildField('密码', _pwd, Icons.lock_outline, obscure: true),
          if (_reg) ...[
            const SizedBox(height: 14),
            _buildField('昵称', _dn, Icons.badge_outlined),
            const SizedBox(height: 14),
            _buildField('手机号', _ph, Icons.phone_outlined, phone: true),
            const SizedBox(height: 14),
            _buildField('邮箱', _em, Icons.email_outlined, email: true),
          ],
          // Links
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => setState(() { _reg = !_reg; _err = null; }),
                  child: Text(_reg ? '已有账号？去登录' : '没有账号？去注册', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: PawmartColors.primary500)),
                ),
                if (!_reg)
                  TextButton(
                    onPressed: () {},
                    child: Text('忘记密码？', style: TextStyle(fontSize: 13, color: PawmartColors.primary500)),
                  ),
              ],
            ),
          ),
          if (_err != null) ...[
            _buildError(_err!),
            const SizedBox(height: 12),
          ],
          // Login button
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _busy ? null : _sub,
              style: FilledButton.styleFrom(
                backgroundColor: PawmartColors.accent400,
                foregroundColor: PawmartColors.textOnAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
              ),
              child: _busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: PawmartColors.textOnAccent))
                : Text(_reg ? '注册并登录' : '登录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 24),
          // Divider
          _dividerWithText('其他登录方式'),
          const SizedBox(height: 16),
          // Social buttons
          Row(children: [
            Expanded(child: _socialBtn(Icons.wechat, '微信登录', PawmartColors.success)),
            const SizedBox(width: 10),
            Expanded(child: _socialBtn(Icons.smartphone_outlined, '验证码登录', PawmartColors.info)),
          ]),
          const SizedBox(height: 20),
          // Divider
          _dividerWithText('无需登录，直接体验'),
          const SizedBox(height: 16),
          // Dev bypass
          SizedBox(
            height: 48,
            child: Row(children: [
              Expanded(child: _userBtn()),
              const SizedBox(width: 12),
              Expanded(child: _adminBtn()),
            ]),
          ),
          const SizedBox(height: 10),
          Text('体验账号: admin / Admin@123456', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: PawmartColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildField(String hint, TextEditingController ctrl, IconData icon, {bool obscure = false, bool phone = false, bool email = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hint, style: TextStyle(fontSize: 13, color: PawmartColors.textSecondary)),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: TextField(
            controller: ctrl,
            obscureText: obscure,
            keyboardType: phone ? TextInputType.phone : (email ? TextInputType.emailAddress : null),
            onSubmitted: obscure ? (_) => _sub() : null,
            style: TextStyle(fontSize: 14, color: PawmartColors.textPrimary),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 18, color: PawmartColors.neutral400),
              hintText: '请输入$hint',
              hintStyle: TextStyle(fontSize: 14, color: PawmartColors.textSecondary),
              filled: true,
              fillColor: PawmartColors.neutral50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: PawmartColors.neutral200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: PawmartColors.neutral200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: PawmartColors.primary500, width: 1.5)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _socialBtn(IconData icon, String label, Color color) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 18, color: color),
      label: Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      style: OutlinedButton.styleFrom(
        foregroundColor: PawmartColors.textPrimary,
        side: BorderSide(color: PawmartColors.neutral200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 6),
        minimumSize: const Size(0, 32),
      ),
    );
  }

  Widget _userBtn() {
    return OutlinedButton.icon(
      onPressed: () => widget.sessionStore.devBypass(asAdmin: false),
      icon: const Icon(Icons.person_outline, size: 18),
      label: Text('用户首页', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      style: OutlinedButton.styleFrom(
        foregroundColor: PawmartColors.primary500,
        side: BorderSide(color: PawmartColors.primary200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _adminBtn() {
    return FilledButton.icon(
      onPressed: () => widget.sessionStore.devBypass(asAdmin: true),
      icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
      label: Text('管理后台', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      style: FilledButton.styleFrom(
        backgroundColor: PawmartColors.primary500,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildError(String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: PawmartColors.error.withAlpha(20), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Icon(Icons.error_outline, size: 18, color: PawmartColors.error),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: TextStyle(fontSize: 13, color: PawmartColors.error))),
      ]),
    );
  }

  Widget _dividerWithText(String label) {
    return Row(children: [
      const Expanded(child: Divider(color: PawmartColors.neutral200)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(label, style: TextStyle(fontSize: 12, color: PawmartColors.textSecondary)),
      ),
      const Expanded(child: Divider(color: PawmartColors.neutral200)),
    ]);
  }

  // ═══ Hero Image ═══
  Widget _buildHero(BuildContext ctx) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 480,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(fit: StackFit.expand, children: [
              CachedNetworkImage(imageUrl: _ossUrl1, fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [PawmartColors.primary100, PawmartColors.primary200])),
                  child: Center(child: Icon(Icons.pets, size: 80, color: PawmartColors.primary300.withAlpha(120))),
                ),
              ),
              Positioned(bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, PawmartColors.primary700.withAlpha(180)])),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('为每一只爱宠', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 6),
                    Text('找到最贴心的呵护', style: TextStyle(fontSize: 16, color: Colors.white.withAlpha(200))),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  // ═══ Section 2: Brand Promises ═══
  Widget _buildPromises(BuildContext ctx) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 40),
      color: PawmartColors.primary500,
      child: LayoutBuilder(
        builder: (_, constraints) {
          final maxW = constraints.maxWidth > 1024 ? 1024.0 : constraints.maxWidth;
          return Center(
            child: SizedBox(
              width: maxW,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _promiseItem(Icons.star, '品质保障', '严选全球优质品牌，安全放心'),
                  _promiseItem(Icons.local_shipping, '极速配送', '全国仓储网络，次日达服务'),
                  _promiseItem(Icons.favorite, '贴心售后', '7天无忧退换，专业客服支持'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _promiseItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: Colors.white.withAlpha(40), shape: BoxShape.circle),
            child: Icon(icon, size: 24, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          Text(desc, style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(200))),
        ],
      ),
    );
  }

  // ═══ Section 3: Features ═══
  Widget _buildFeatures(BuildContext ctx) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: LayoutBuilder(
        builder: (_, constraints) {
          final maxW = constraints.maxWidth > 1024 ? 1024.0 : constraints.maxWidth;
          return Center(
            child: SizedBox(
              width: maxW,
              child: Column(
                children: [
                  Text('为什么选择 PawMart？', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: PawmartColors.textPrimary)),
                  const SizedBox(height: 8),
                  Text('我们用科技与热爱，重新定义宠物消费体验', style: TextStyle(fontSize: 16, color: PawmartColors.textSecondary)),
                  const SizedBox(height: 36),
                  const Row(
                    children: [
                      Expanded(child: _FeatureCard(
                        icon: Icons.auto_awesome,
                        title: '智能推荐',
                        desc: '基于宠物画像的 AI 智能推荐，精准匹配品种、年龄和健康状况，为你的爱宠量身定制好物清单。',
                      )),
                      SizedBox(width: 20),
                      Expanded(child: _FeatureCard(
                        icon: Icons.pets,
                        title: '品种专属',
                        desc: '覆盖 200+ 品种的专属营养与护理方案，从拉布拉多到布偶猫，满足每一种宠物的独特需求。',
                      )),
                      SizedBox(width: 20),
                      Expanded(child: _FeatureCard(
                        icon: Icons.people,
                        title: '社区互动',
                        desc: '百万宠物主人的活跃社区，分享养宠心得、获取专业建议，结交志同道合的宠物朋友。',
                      )),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══ Section 4: Categories ═══
  Widget _buildCategories(BuildContext ctx) {
    final cats = [
      (_ossUrl2, '狗粮'),
      (_ossUrl3, '猫粮'),
      (_ossUrl4, '宠物用品'),
      (_ossUrl1, '宠物保健'),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      color: PawmartColors.neutral50,
      child: LayoutBuilder(
        builder: (_, constraints) {
          final maxW = constraints.maxWidth > 1024 ? 1024.0 : constraints.maxWidth;
          return Center(
            child: SizedBox(
              width: maxW,
              child: Column(
                children: [
                  Text('热门品类', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: PawmartColors.textPrimary)),
                  const SizedBox(height: 8),
                  Text('覆盖宠物生活全方位需求', style: TextStyle(fontSize: 16, color: PawmartColors.textSecondary)),
                  const SizedBox(height: 32),
                  LayoutBuilder(
                    builder: (_, inner) {
                      final isWide = inner.maxWidth > 600;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: cats.map((c) => _categoryCard(c.$1, c.$2, isWide)).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _categoryCard(String imgUrl, String label, bool isWide) {
    final w = isWide ? 220.0 : (MediaQuery.of(context).size.width - 80) / 2;
    return SizedBox(
      width: w,
      height: 180,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(fit: StackFit.expand, children: [
          CachedNetworkImage(imageUrl: imgUrl, fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Container(color: PawmartColors.primary200),
          ),
          Container(
            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, PawmartColors.primary700.withAlpha(180)])),
          ),
          Positioned(bottom: 16, left: 16, child: Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white))),
        ]),
      ),
    );
  }

  // ═══ Section 5: CTA ═══
  Widget _buildCTA(BuildContext ctx) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      color: PawmartColors.primary50,
      child: Column(
        children: [
          Text('立即加入 PawMart', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: PawmartColors.textPrimary)),
          const SizedBox(height: 12),
          Text('为你的爱宠找到最好的呵护', style: TextStyle(fontSize: 16, color: PawmartColors.textSecondary)),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: () => setState(() { _reg = true; _err = null; }),
              style: FilledButton.styleFrom(
                backgroundColor: PawmartColors.accent400,
                foregroundColor: PawmartColors.textOnAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                padding: const EdgeInsets.symmetric(horizontal: 32),
              ),
              child: Text('免费注册', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  // ═══ Section 6: Footer ═══
  Widget _buildFooter(BuildContext ctx) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      color: PawmartColors.neutral900,
      child: LayoutBuilder(
        builder: (_, constraints) {
          final maxW = constraints.maxWidth > 1024 ? 1024.0 : constraints.maxWidth;
          return Center(
            child: SizedBox(
              width: maxW,
              child: Column(
                children: [
                  Text('PawMart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('© 2026 PawMart. 保留所有权利。', style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(150))),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 24,
                    children: ['关于我们', '联系客服', '隐私政策', '用户协议', '帮助中心'].map((l) =>
                      Text(l, style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(180)))
                    ).toList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title, desc;
  const _FeatureCard({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PawmartColors.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PawmartColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: PawmartColors.primary50, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 22, color: PawmartColors.primary500),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: PawmartColors.textPrimary)),
          const SizedBox(height: 8),
          Text(desc, style: TextStyle(fontSize: 14, color: PawmartColors.textSecondary, height: 1.5)),
        ],
      ),
    );
  }
}