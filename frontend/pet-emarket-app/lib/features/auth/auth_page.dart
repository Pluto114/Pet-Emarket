import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      if (_reg) {
        await widget.apiClient.register(
          username: _usr.text.trim(),
          password: _pwd.text,
          displayName: _dn.text.trim(),
          phone: _ph.text.trim(),
          email: _em.text.trim(),
        );
      } else {
        await widget.apiClient.login(
          username: _usr.text.trim(),
          password: _pwd.text,
        );
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
    final wide = screenW > 860;

    return Scaffold(
      backgroundColor: s.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: wide ? _buildWideLayout(ctx, s) : _buildNarrowLayout(ctx, s),
          ),
        ),
      ),
    );
  }

  // ——— Wide screen: side-by-side layout ———
  Widget _buildWideLayout(BuildContext ctx, ColorScheme s) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1200),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Brand + Form
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: _buildFormColumn(ctx, s),
            ),
          ),
          const SizedBox(width: 60),
          // Right: Hero Image
          Expanded(
            child: _buildHeroImage(ctx),
          ),
        ],
      ),
    );
  }

  // ——— Narrow screen: stacked layout ———
  Widget _buildNarrowLayout(BuildContext ctx, ColorScheme s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Compact hero on top
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(pawmartRadiusXl),
              gradient: LinearGradient(
                colors: [PawmartColors.primary100, PawmartColors.primary200],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Icon(Icons.pets, size: 120, color: PawmartColors.primary300.withAlpha(80)),
                ),
                Positioned(
                  left: -10,
                  top: -10,
                  child: Icon(Icons.pets, size: 80, color: PawmartColors.primary200.withAlpha(60)),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'PawMart',
                        style: GoogleFonts.nunito(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: PawmartColors.primary700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '为每一只爱宠\n找到最贴心的呵护',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: PawmartColors.primary600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildFormCard(ctx, s),
        ],
      ),
    );
  }

  // ——— Form shared by both layouts ———
  Widget _buildFormColumn(BuildContext ctx, ColorScheme s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Brand
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: PawmartColors.primary500,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.pets, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 10),
            Text(
              'PawMart',
              style: GoogleFonts.nunito(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: PawmartColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '为每一只爱宠，找到最贴心的呵护',
          style: GoogleFonts.nunito(
            fontSize: 14,
            color: PawmartColors.textSecondary,
          ),
        ),
        const SizedBox(height: 32),
        _buildFormCard(ctx, s),
      ],
    );
  }

  Widget _buildFormCard(BuildContext ctx, ColorScheme s) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: PawmartColors.surfaceCard,
        borderRadius: BorderRadius.circular(pawmartRadiusLg),
        boxShadow: pawmartShadow2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _reg ? '创建账号' : '欢迎回来',
            style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: PawmartColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _reg ? '注册后开启宠物之旅 🐾' : '登录继续访问 PawMart',
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: PawmartColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          // Username
          TextField(
            controller: _usr,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.person_outline, size: 20),
              hintText: '用户名',
            ),
          ),
          const SizedBox(height: 14),
          // Password
          TextField(
            controller: _pwd,
            obscureText: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.lock_outline, size: 20),
              hintText: '密码',
            ),
            onSubmitted: (_) => _sub(),
          ),
          if (_reg) ...[
            const SizedBox(height: 14),
            TextField(
              controller: _dn,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.badge_outlined, size: 20),
                hintText: '昵称',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _ph,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.phone_outlined, size: 20),
                hintText: '手机号',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _em,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.email_outlined, size: 20),
                hintText: '邮箱',
              ),
            ),
          ],
          // Error
          if (_err != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PawmartColors.error.withAlpha(20),
                borderRadius: BorderRadius.circular(pawmartRadiusMd),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 18, color: PawmartColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _err!,
                      style: GoogleFonts.nunito(fontSize: 13, color: PawmartColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          // Login / Register button (accent yellow, pill-shaped)
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: _busy ? null : _sub,
              style: FilledButton.styleFrom(
                backgroundColor: PawmartColors.accent400,
                foregroundColor: PawmartColors.textOnAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(pawmartRadiusFull),
                ),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: PawmartColors.textOnAccent),
                    )
                  : Text(
                      _reg ? '注册并登录' : '登录',
                      style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          // Toggle login/register
          Center(
            child: TextButton(
              onPressed: _busy ? null : () => setState(() {
                _reg = !_reg;
                _err = null;
              }),
              child: Text(
                _reg ? '已有账号？去登录' : '没有账号？去注册',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w600,
                  color: PawmartColors.primary500,
                ),
              ),
            ),
          ),
          // Divider
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '快速体验',
                  style: GoogleFonts.nunito(fontSize: 12, color: PawmartColors.textSecondary),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 14),
          // Dev bypass buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => widget.sessionStore.devBypass(asAdmin: true),
                  icon: const Icon(Icons.admin_panel_settings, size: 18),
                  label: Text(
                    '管理员',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => widget.sessionStore.devBypass(asAdmin: false),
                  icon: const Icon(Icons.person, size: 18),
                  label: Text(
                    '用户',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'demo / Demo@123456',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(fontSize: 12, color: PawmartColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ——— Hero Image Section (wide layout) ———
  Widget _buildHeroImage(BuildContext ctx) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 380,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(pawmartRadiusXl),
            gradient: LinearGradient(
              colors: [PawmartColors.primary100, PawmartColors.primary200],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: pawmartShadow3,
          ),
          child: Stack(
            children: [
              // Pet icons as placeholder
              Positioned(
                right: 30,
                top: 40,
                child: Transform.rotate(
                  angle: -0.1,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(180),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.pets, size: 50, color: PawmartColors.primary400),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                bottom: 60,
                child: Transform.rotate(
                  angle: 0.15,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(180),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.pets, size: 40, color: PawmartColors.primary300),
                  ),
                ),
              ),
              Positioned(
                right: 40,
                bottom: 30,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(180),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.pets, size: 30, color: PawmartColors.accent400),
                ),
              ),
              // Overlay text
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(pawmartRadiusXl)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        PawmartColors.primary700.withAlpha(180),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '为每一只爱宠',
                        style: GoogleFonts.nunito(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '找到最贴心的呵护',
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          color: Colors.white.withAlpha(200),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Brand promise strip below hero
        Row(
          children: [
            _promiseItem(Icons.shield_outlined, '品质保障', '严选全球优质品牌'),
            const SizedBox(width: 16),
            _promiseItem(Icons.local_shipping_outlined, '极速配送', '全国次日达服务'),
            const SizedBox(width: 16),
            _promiseItem(Icons.support_agent_outlined, '贴心售后', '7天无忧退换'),
          ],
        ),
      ],
    );
  }

  Widget _promiseItem(IconData icon, String title, String subtitle) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: PawmartColors.accent400.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: PawmartColors.accent400),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: PawmartColors.textPrimary,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.nunito(
              fontSize: 10,
              color: PawmartColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
