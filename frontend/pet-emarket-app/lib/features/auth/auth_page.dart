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
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.pets, size: 56, color: theme.colorScheme.primary),
                const SizedBox(height: 18),
                Text(
                  'Pet-Emarket',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  registerMode ? 'Create an account to get started' : 'Sign in to manage pets and products',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person)),
                  autofillHints: const [AutofillHints.username],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => submit(),
                ),
                if (registerMode) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: displayNameController,
                    decoration: const InputDecoration(labelText: 'Nickname', prefixIcon: Icon(Icons.badge)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone)),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
                if (errorText != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      Icon(Icons.error_outline, size: 18, color: theme.colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(child: Text(errorText!, style: TextStyle(color: theme.colorScheme.error, fontSize: 13))),
                    ]),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: loading ? null : submit,
                  icon: loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(registerMode ? Icons.person_add_alt_1 : Icons.login),
                  label: Text(registerMode ? 'Sign Up & Login' : 'Sign In'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: loading
                      ? null
                      : () {
                          setState(() {
                            registerMode = !registerMode;
                            errorText = null;
                          });
                        },
                  child: Text(registerMode ? 'Already have an account? Sign In' : 'No account? Create One'),
                ),
                const SizedBox(height: 18),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  'Demo account: admin / Admin@123456',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ],
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
