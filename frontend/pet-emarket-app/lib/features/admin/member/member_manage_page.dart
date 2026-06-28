import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../models/app_user.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/toast.dart';

class MemberManagePage extends StatefulWidget {
  const MemberManagePage({required this.apiClient, super.key});
  final ApiClient apiClient;
  @override State<MemberManagePage> createState() => _MemberManagePageState();
}

class _MemberManagePageState extends State<MemberManagePage> {
  bool loading = true;
  List<AppUser> users = [];

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    setState(() => loading = true);
    try { users = await widget.apiClient.listUsers(); } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  Future<void> _delete(AppUser u) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete User',
      message: 'Are you sure you want to delete "${u.displayName}"? This action cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await widget.apiClient.deleteUser(u.id);
      await load();
      if (mounted) showSuccess(context, '${u.displayName} deleted');
    } catch (e) {
      if (mounted) showError(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(padding: const EdgeInsets.all(20), children: [
        Row(children: [
          Expanded(child: Text('Member Management', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700))),
          FilledButton.icon(onPressed: () => _showDialog(), icon: const Icon(Icons.add), label: const Text('Add User')),
        ]),
        const SizedBox(height: 12),
        if (loading) const Center(child: Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator())),
        ...users.map((u) => Card(
          child: ListTile(
            leading: CircleAvatar(child: Text(u.username.isNotEmpty ? u.username[0].toUpperCase() : '?')),
            title: Text('${u.displayName} (${u.username})'),
            subtitle: Text('${u.role} | ${u.memberLevel} | ${u.status}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.edit), onPressed: () => _showDialog(user: u)),
              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(u)),
            ]),
          ),
        )),
      ]),
    );
  }

  Future<void> _showDialog({AppUser? user}) async {
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (ctx) => _UserDialog(user: user));
    if (result == null) return;
    try {
      if (user == null) {
        await widget.apiClient.createUser(result);
      } else {
        await widget.apiClient.updateUser(user.id, result);
      }
      await load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

class _UserDialog extends StatefulWidget {
  final AppUser? user;
  const _UserDialog({this.user});
  @override State<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<_UserDialog> {
  late final userCtrl = TextEditingController(text: widget.user?.username ?? '');
  late final pwdCtrl = TextEditingController();
  late final nameCtrl = TextEditingController(text: widget.user?.displayName ?? '');
  late final phoneCtrl = TextEditingController(text: widget.user?.phone ?? '');
  late final emailCtrl = TextEditingController(text: widget.user?.email ?? '');
  String role = 'CUSTOMER', level = 'NORMAL', status = 'ACTIVE';

  @override
  void initState() {
    super.initState();
    role = widget.user?.role ?? 'CUSTOMER';
    level = widget.user?.memberLevel ?? 'NORMAL';
    status = widget.user?.status ?? 'ACTIVE';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.user == null ? 'Add User' : 'Edit User'),
      content: SizedBox(width: 400, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: userCtrl, enabled: widget.user == null, decoration: const InputDecoration(labelText: 'Username')),
        const SizedBox(height: 8),
        TextField(controller: pwdCtrl, obscureText: true, decoration: InputDecoration(labelText: widget.user == null ? 'Password' : 'New Password (leave blank)')),
        const SizedBox(height: 8),
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nickname')),
        const SizedBox(height: 8),
        TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
        const SizedBox(height: 8),
        TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(value: role, decoration: const InputDecoration(labelText: 'Role'), items: const [DropdownMenuItem(value: 'ADMIN', child: Text('Admin')), DropdownMenuItem(value: 'MERCHANT', child: Text('Merchant')), DropdownMenuItem(value: 'CUSTOMER', child: Text('User'))], onChanged: (v) => setState(() => role = v ?? role)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(value: level, decoration: const InputDecoration(labelText: 'Member Level'), items: const [DropdownMenuItem(value: 'NORMAL', child: Text('Normal')), DropdownMenuItem(value: 'VIP', child: Text('VIP')), DropdownMenuItem(value: 'SVIP', child: Text('SVIP'))], onChanged: (v) => setState(() => level = v ?? level)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(value: status, decoration: const InputDecoration(labelText: 'Status'), items: const [DropdownMenuItem(value: 'ACTIVE', child: Text('Active')), DropdownMenuItem(value: 'DISABLED', child: Text('Disabled'))], onChanged: (v) => setState(() => status = v ?? status)),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () {
          final payload = <String, dynamic>{
            'displayName': nameCtrl.text.trim(), 'role': role, 'memberLevel': level, 'status': status,
            'phone': phoneCtrl.text.trim(), 'email': emailCtrl.text.trim(),
          };
          if (widget.user == null) { payload['username'] = userCtrl.text.trim(); payload['password'] = pwdCtrl.text; }
          if (widget.user != null && pwdCtrl.text.isNotEmpty) payload['password'] = pwdCtrl.text;
          Navigator.pop(context, payload);
        }, child: const Text('Save')),
      ],
    );
  }
}

