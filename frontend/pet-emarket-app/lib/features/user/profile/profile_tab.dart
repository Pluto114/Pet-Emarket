/// 用户个人中心 — 信息展示 + 编辑 + 退出
library;

import 'package:flutter/material.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/session/session_store.dart';
import '../../../../models/app_user.dart';

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
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = widget.sessionStore.user;

    if (user == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline, size: 64, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('Please sign in first', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            FilledButton(onPressed: widget.onLogout, child: const Text('Go to Login')),
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
            child: Row(children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: theme.colorScheme.primary,
                child: Text(user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: 24, color: theme.colorScheme.onPrimary)),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user.displayName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('@${user.username}  |  ${user.role}  |  ${user.memberLevel}', style: theme.textTheme.bodySmall),
              ])),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        _InfoCard(icon: Icons.phone, title: 'Phone', value: user.phone.isNotEmpty ? user.phone : 'Not set'),
        _InfoCard(icon: Icons.email, title: 'Email', value: user.email.isNotEmpty ? user.email : 'Not set'),
        _InfoCard(icon: Icons.verified_user, title: 'Role', value: user.role),
        _InfoCard(icon: Icons.workspace_premium, title: 'Member Level', value: user.memberLevel),
        _InfoCard(icon: Icons.stars_outlined, title: 'Points', value: user.pointsBalance.toString()),
        const SizedBox(height: 12),
        ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('Edit Profile'), onTap: () => _editProfile(user)),
        ListTile(leading: const Icon(Icons.brightness_6), title: const Text('Toggle Theme'), onTap: widget.onThemeToggle),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: widget.onLogout, icon: const Icon(Icons.logout), label: const Text('Logout')),
      ],
    );
  }

  Future<void> _editProfile(AppUser user) async {
    final payload = await showDialog<Map<String, dynamic>>(context: context, builder: (_) => _EditDialog(user: user));
    if (payload == null) return;
    try {
      final updated = await widget.apiClient.updateUser(user.id, payload);
      widget.sessionStore.updateUser(updated);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
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
  void dispose() { dn.dispose(); ph.dispose(); em.dispose(); pw.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Profile'),
      content: SizedBox(width: 420, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: dn, decoration: const InputDecoration(labelText: 'Display Name')),
        const SizedBox(height: 10),
        TextField(controller: ph, decoration: const InputDecoration(labelText: 'Phone')),
        const SizedBox(height: 10),
        TextField(controller: em, decoration: const InputDecoration(labelText: 'Email')),
        const SizedBox(height: 10),
        TextField(controller: pw, obscureText: true, decoration: const InputDecoration(labelText: 'New Password (optional)')),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, {
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.title, required this.value});
  final IconData icon;
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Card(child: ListTile(leading: Icon(icon), title: Text(title), trailing: Text(value)));
  }
}
