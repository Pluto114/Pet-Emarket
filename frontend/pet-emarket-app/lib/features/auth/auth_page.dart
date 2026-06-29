import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/session/session_store.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({
    required this.apiClient,
    required this.sessionStore,
    super.key,
  });

  final ApiClient apiClient;
  final SessionStore sessionStore;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final usernameController = TextEditingController(text: 'admin');
  final passwordController = TextEditingController(text: 'Admin@123456');
  final displayNameController = TextEditingController(text: 'Pet User');
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  bool registerMode = false;
  bool loading = false;
  String? errorText;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    displayNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: isLight ? const Color(0xFFF4F1EB) : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Brand ──
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF204E4A),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(Icons.pets, size: 36, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Pet-Emarket',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF204E4A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    registerMode
                        ? '创建账号，开启宠物之旅'
                        : '为你心爱的宠物找到最好的',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Form card ──
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.light
                          ? Colors.white
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                      border: isLight
                          ? Border.all(color: theme.colorScheme.outlineVariant.withAlpha(50))
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(6),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Username
                        TextField(
                          controller: usernameController,
                          decoration: const InputDecoration(
                            labelText: '用户名',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          autofillHints: const [AutofillHints.username],
                        ),
                        const SizedBox(height: 16),

                        // Password
                        TextField(
                          controller: passwordController,
                          decoration: const InputDecoration(
                            labelText: '密码',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          obscureText: true,
                          autofillHints: const [AutofillHints.password],
                          onSubmitted: (_) => submit(),
                        ),

                        // Register fields
                        if (registerMode) ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: displayNameController,
                            decoration: const InputDecoration(
                              labelText: '昵称',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: phoneController,
                            decoration: const InputDecoration(
                              labelText: '手机号',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: emailController,
                            decoration: const InputDecoration(
                              labelText: '邮箱',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ],

                        // Error
                        if (errorText != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer.withAlpha(120),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(children: [
                              Icon(Icons.error_outline, size: 18, color: theme.colorScheme.error),
                              const SizedBox(width: 8),
                              Expanded(child: Text(errorText!, style: TextStyle(color: theme.colorScheme.error, fontSize: 13))),
                            ]),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Submit button
                        FilledButton.icon(
                          onPressed: loading ? null : submit,
                          icon: loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Icon(registerMode ? Icons.person_add_alt_1 : Icons.login),
                          label: Text(registerMode ? '注册并登录' : '登录'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF204E4A),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Toggle register/login
                        Center(
                          child: TextButton(
                            onPressed: loading
                                ? null
                                : () {
                                    setState(() {
                                      registerMode = !registerMode;
                                      errorText = null;
                                    });
                                  },
                            child: Text(
                              registerMode
                                  ? '已有账号？去登录'
                                  : '没有账号？去注册',
                              style: TextStyle(
                                color: const Color(0xFF204E4A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Dev mode ──
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.light
                          ? Colors.white
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                      border: isLight
                          ? Border.all(color: theme.colorScheme.outlineVariant.withAlpha(50))
                          : null,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                '开发者模式',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: () => widget.sessionStore.devBypass(asAdmin: true),
                          icon: const Icon(Icons.admin_panel_settings, size: 18),
                          label: const Text('以管理员身份进入'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 44),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => widget.sessionStore.devBypass(asAdmin: false),
                          icon: const Icon(Icons.person, size: 18),
                          label: const Text('以用户身份进入'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 44),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text(
                    '演示账号：admin / Admin@123456',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> submit() async {
    setState(() {
      loading = true;
      errorText = null;
    });
    try {
      if (registerMode) {
        await widget.apiClient.register(
          username: usernameController.text.trim(),
          password: passwordController.text,
          displayName: displayNameController.text.trim(),
          phone: phoneController.text.trim(),
          email: emailController.text.trim(),
        );
      } else {
        await widget.apiClient.login(
          username: usernameController.text.trim(),
          password: passwordController.text,
        );
      }
    } catch (error) {
      setState(() => errorText = error.toString());
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }
}
