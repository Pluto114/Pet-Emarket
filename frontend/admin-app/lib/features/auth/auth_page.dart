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
  final usernameController = TextEditingController(text: 'admin');
  final passwordController = TextEditingController(text: 'Admin@123456');
  bool loading = false;
  String? errorText;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    setState(() { loading = true; errorText = null; });
    try {
      await widget.apiClient.login(
        username: usernameController.text.trim(),
        password: passwordController.text,
      );
    } catch (e) {
      setState(() => errorText = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.admin_panel_settings, size: 56, color: theme.colorScheme.primary),
                const SizedBox(height: 18),
                Text('Pet-Emarket 管理后台', textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('请使用管理员账号登录', textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 28),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: '用户名', prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: '密码', prefixIcon: Icon(Icons.lock)),
                  obscureText: true,
                  onSubmitted: (_) => login(),
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 12),
                  Text(errorText!, style: TextStyle(color: theme.colorScheme.error)),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: loading ? null : login,
                  icon: loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.login),
                  label: const Text('登 录'),
                ),
                const SizedBox(height: 16),
                Text('演示账号：admin / Admin@123456', textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

