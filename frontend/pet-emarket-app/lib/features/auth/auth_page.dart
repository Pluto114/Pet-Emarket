/// 登录/注册页 — Voldog 暖橘治愈风 · 零硬编码
library;

import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/session/session_store.dart';

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
  void dispose() { _usr.dispose(); _pwd.dispose(); _dn.dispose(); _ph.dispose(); _em.dispose(); super.dispose(); }

  Future<void> _sub() async {
    setState(() { _busy = true; _err = null; });
    try {
      if (_reg) { await widget.apiClient.register(username: _usr.text.trim(), password: _pwd.text, displayName: _dn.text.trim(), phone: _ph.text.trim(), email: _em.text.trim()); }
      else { await widget.apiClient.login(username: _usr.text.trim(), password: _pwd.text); }
    } catch (e) { setState(() => _err = e.toString()); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: s.surface,
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // 宠物插画
          Container(width: 100, height: 100,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), color: s.primaryContainer, boxShadow: [BoxShadow(color: s.primary.withAlpha(30), blurRadius: 20, offset: const Offset(0, 8))]),
            child: Stack(children: [
              Center(child: Icon(Icons.pets, size: 44, color: s.primary)),
              Positioned(right: 6, bottom: 6, child: const Text('🐱', style: TextStyle(fontSize: 26))),
              Positioned(left: 4, top: 4, child: const Text('🐶', style: TextStyle(fontSize: 20))),
            ])),
          const SizedBox(height: 20),
          Text('Pet-Emarket', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: s.onSurface)),
          const SizedBox(height: 6),
          Text(_reg ? '创建账号，开启宠物之旅 🐾' : '为你心爱的宠物找到最好的', style: TextStyle(fontSize: 14, color: s.onSurfaceVariant)),
          const SizedBox(height: 32),

          // 表单卡
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: s.surfaceContainerLow, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: s.shadow.withAlpha(12), blurRadius: 20, offset: const Offset(0, 4))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _F(ctrl: _usr, label: '用户名', icon: Icons.person_outline),
              const SizedBox(height: 16),
              _F(ctrl: _pwd, label: '密码', icon: Icons.lock_outline, obscure: true, onSubmit: (_) => _sub()),
              if (_reg) ...[
                const SizedBox(height: 16),
                _F(ctrl: _dn, label: '昵称', icon: Icons.badge_outlined),
                const SizedBox(height: 16),
                _F(ctrl: _ph, label: '手机号', icon: Icons.phone_outlined, keyboard: TextInputType.phone),
                const SizedBox(height: 16),
                _F(ctrl: _em, label: '邮箱', icon: Icons.email_outlined, keyboard: TextInputType.emailAddress),
              ],
              if (_err != null) ...[
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: s.errorContainer, borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [Icon(Icons.error_outline, size: 18, color: s.error), const SizedBox(width: 8), Expanded(child: Text(_err!, style: TextStyle(color: s.error, fontSize: 13)))])),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _busy ? null : _sub,
                icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(_reg ? Icons.person_add_alt_1 : Icons.login),
                label: Text(_reg ? '注册并登录' : '登录'),
              ),
              const SizedBox(height: 12),
              Center(child: TextButton(onPressed: _busy ? null : () => setState(() { _reg = !_reg; _err = null; }), child: Text(_reg ? '已有账号？去登录' : '没有账号？去注册', style: TextStyle(fontWeight: FontWeight.w600, color: s.primary)))),
            ]),
          ),
          const SizedBox(height: 28),

          // 快速体验
          Container(
            padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: s.surfaceContainerLow, borderRadius: BorderRadius.circular(28)),
            child: Column(children: [
              Row(children: [const Expanded(child: Divider()), Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('快速体验', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: s.onSurfaceVariant))), const Expanded(child: Divider())]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: OutlinedButton.icon(onPressed: () => widget.sessionStore.devBypass(asAdmin: true), icon: const Icon(Icons.admin_panel_settings, size: 18), label: const Text('管理员'))),
                const SizedBox(width: 10),
                Expanded(child: OutlinedButton.icon(onPressed: () => widget.sessionStore.devBypass(asAdmin: false), icon: const Icon(Icons.person, size: 18), label: const Text('用户'))),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          Text('demo / Demo@123456', style: TextStyle(fontSize: 12, color: s.onSurfaceVariant)),
        ]),
      )))),
    );
  }
}

class _F extends StatelessWidget {
  const _F({required this.ctrl, required this.label, required this.icon, this.obscure = false, this.keyboard, this.onSubmit});
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboard;
  final ValueChanged<String>? onSubmit;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return TextField(
      controller: ctrl, obscureText: obscure, keyboardType: keyboard,
      style: TextStyle(color: s.onSurface),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: s.onSurfaceVariant)),
      onSubmitted: onSubmit,
    );
  }
}
