import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/session/session_store.dart';
import '../../../models/app_user.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({
    required this.apiClient,
    required this.sessionStore,
    super.key,
  });

  final ApiClient apiClient;
  final SessionStore sessionStore;

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  bool loading = true;
  String? errorText;
  List<AppUser> users = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.sessionStore.user?.isAdmin == true;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '用户管理',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                ),
                FilledButton.icon(
                  onPressed: isAdmin ? () => showUserDialog() : null,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('新增用户'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!isAdmin)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('当前后端规定：用户列表和新增/删除用户仅管理员可操作。请使用 admin 演示账号登录。'),
                ),
              ),
            if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: CircularProgressIndicator(),
                ),
              ),
            if (errorText != null)
              Text(
                errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (!loading && errorText == null)
              ...users.map(
                (user) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          user.username.isEmpty
                              ? '?'
                              : user.username[0].toUpperCase(),
                        ),
                      ),
                      title: Text('${user.displayName} (${user.username})'),
                      subtitle: Text(
                        '${user.role} / ${user.memberLevel} / ${user.status}\n${user.phone} ${user.email}',
                      ),
                      isThreeLine: true,
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: '编辑',
                            onPressed:
                                isAdmin ||
                                        user.id == widget.sessionStore.user?.id
                                    ? () => showUserDialog(user: user)
                                    : null,
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: '删除',
                            onPressed: isAdmin ? () => deleteUser(user) : null,
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      errorText = null;
    });
    try {
      users = await widget.apiClient.listUsers();
    } catch (error) {
      errorText = error.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> showUserDialog({AppUser? user}) async {
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _UserDialog(user: user),
    );
    if (payload == null) return;
    try {
      if (user == null) {
        await widget.apiClient.createUser(payload);
      } else {
        await widget.apiClient.updateUser(user.id, payload);
      }
      await load();
    } catch (error) {
      if (mounted) showError(error);
    }
  }

  Future<void> deleteUser(AppUser user) async {
    try {
      await widget.apiClient.deleteUser(user.id);
      await load();
    } catch (error) {
      if (mounted) showError(error);
    }
  }

  void showError(Object error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.toString())));
  }
}

class _UserDialog extends StatefulWidget {
  const _UserDialog({this.user});

  final AppUser? user;

  @override
  State<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<_UserDialog> {
  late final TextEditingController username;
  late final TextEditingController password;
  late final TextEditingController displayName;
  late final TextEditingController phone;
  late final TextEditingController email;
  String role = 'CUSTOMER';
  String memberLevel = 'NORMAL';
  String status = 'ACTIVE';

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    username = TextEditingController(text: user?.username ?? '');
    password = TextEditingController();
    displayName = TextEditingController(text: user?.displayName ?? '');
    phone = TextEditingController(text: user?.phone ?? '');
    email = TextEditingController(text: user?.email ?? '');
    role = user?.role ?? 'CUSTOMER';
    memberLevel = user?.memberLevel ?? 'NORMAL';
    status = user?.status ?? 'ACTIVE';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.user == null ? '新增用户' : '编辑用户'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: username,
                enabled: widget.user == null,
                decoration: const InputDecoration(labelText: '用户名'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: password,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: widget.user == null ? '密码' : '新密码（可空）',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: displayName,
                decoration: const InputDecoration(labelText: '昵称'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phone,
                decoration: const InputDecoration(labelText: '手机号'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: email,
                decoration: const InputDecoration(labelText: '邮箱'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(labelText: '角色'),
                items:
                    const ['ADMIN', 'MERCHANT', 'CUSTOMER']
                        .map(
                          (item) =>
                              DropdownMenuItem(value: item, child: Text(item)),
                        )
                        .toList(),
                onChanged: (value) => setState(() => role = value ?? role),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: memberLevel,
                decoration: const InputDecoration(labelText: '会员等级'),
                items:
                    const ['NORMAL', 'VIP', 'SVIP']
                        .map(
                          (item) =>
                              DropdownMenuItem(value: item, child: Text(item)),
                        )
                        .toList(),
                onChanged:
                    (value) =>
                        setState(() => memberLevel = value ?? memberLevel),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(labelText: '状态'),
                items:
                    const ['ACTIVE', 'DISABLED']
                        .map(
                          (item) =>
                              DropdownMenuItem(value: item, child: Text(item)),
                        )
                        .toList(),
                onChanged: (value) => setState(() => status = value ?? status),
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
            final payload = {
              'username': username.text.trim(),
              if (password.text.isNotEmpty) 'password': password.text,
              'displayName': displayName.text.trim(),
              'phone': phone.text.trim(),
              'email': email.text.trim(),
              'role': role,
              'memberLevel': memberLevel,
              'status': status,
            };
            Navigator.pop(context, payload);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
