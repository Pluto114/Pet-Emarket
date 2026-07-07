import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../models/app_user.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/toast.dart';

class UserManagePage extends StatefulWidget {
  const UserManagePage({required this.apiClient, super.key});
  final ApiClient apiClient;
  @override
  State<UserManagePage> createState() => _State();
}

class _State extends State<UserManagePage> {
  bool _loading = true;
  String? _error;
  List<AppUser> _users = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await widget.apiClient.listUsers();
      if (!mounted) return;
      setState(() { _users = result; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _deleteUser(AppUser u) async {
    final ok = await showConfirmDialog(context, title: '删除', message: '确定删除 "${u.displayName}"？', confirmLabel: '删除', destructive: true);
    if (!ok) return;
    try {
      await widget.apiClient.deleteUser(u.id);
      await _load();
      if (mounted) showSuccess(context, '已删除');
    } catch (e) {
      if (mounted) showError(context, e.toString());
    }
  }

  Future<void> _openEditor({AppUser? user}) async {
    final r = await showDialog<Map<String, dynamic>>(context: context, builder: (_) => _Editor(user: user));
    if (r == null) return;
    try {
      if (user == null) {
        await widget.apiClient.createUser(r);
      } else {
        await widget.apiClient.updateUser(user.id, r);
      }
      await _load();
      if (mounted) showSuccess(context, user == null ? '已创建' : '已更新');
    } catch (e) {
      if (mounted) showError(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_error!, style: TextStyle(color: Colors.red), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('重试')),
          ]),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text('用户管理  (${_users.length}人)', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700))),
            ElevatedButton.icon(onPressed: () => _openEditor(), icon: const Icon(Icons.add, size: 18), label: const Text('添加用户')),
          ]),
          const SizedBox(height: 16),
          if (_users.isEmpty)
            const Expanded(child: Center(child: Text('暂无用户', style: TextStyle(color: Colors.grey, fontSize: 16))))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _users.length,
                itemBuilder: (ctx, i) {
                  final u = _users[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: Text((u.displayName.isNotEmpty ? u.displayName[0] : '?').toUpperCase(),
                                  style: TextStyle(fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(u.displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                Text('@${u.username}  |  ${u.role}  |  ${u.memberLevel}  |  ${u.status == "ACTIVE" ? "启用" : "禁用"}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              ]),
                            ),
                            IconButton(icon: const Icon(Icons.edit_outlined, size: 19), onPressed: () => _openEditor(user: u)),
                            IconButton(icon: const Icon(Icons.delete_outline, size: 19, color: Colors.red), onPressed: () => _deleteUser(u)),
                          ]),
                          const SizedBox(height: 8),
                          Text('${u.email.isNotEmpty ? u.email : "未绑定邮箱"}  |  ${u.phone.isNotEmpty ? u.phone : "未绑定手机"}  |  积分 ${u.pointsBalance}  |  消费 ¥${u.totalSpent.toStringAsFixed(0)}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ===== 编辑弹窗 =====
class _Editor extends StatefulWidget {
  final AppUser? user;
  const _Editor({this.user});
  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  late final _uname = TextEditingController(text: widget.user?.username ?? '');
  late final _pwd   = TextEditingController();
  late final _name  = TextEditingController(text: widget.user?.displayName ?? '');
  late final _phone = TextEditingController(text: widget.user?.phone ?? '');
  late final _email = TextEditingController(text: widget.user?.email ?? '');
  String _role = 'CUSTOMER', _level = 'NORMAL', _status = 'ACTIVE';

  @override
  void initState() {
    super.initState();
    _role = widget.user?.role ?? 'CUSTOMER';
    _level = widget.user?.memberLevel ?? 'NORMAL';
    _status = widget.user?.status ?? 'ACTIVE';
  }

  @override
  void dispose() {
    _uname.dispose(); _pwd.dispose(); _name.dispose(); _phone.dispose(); _email.dispose();
    super.dispose();
  }

  bool get _isNew => widget.user == null;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isNew ? '添加用户' : '编辑用户'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _uname, enabled: _isNew, decoration: InputDecoration(labelText: '用户名', hintText: _isNew ? '请输入用户名' : '不可修改', border: const OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _pwd, obscureText: true, decoration: InputDecoration(labelText: _isNew ? '密码' : '新密码(留空不修改)', border: const OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _name, decoration: const InputDecoration(labelText: '昵称', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _phone, decoration: const InputDecoration(labelText: '手机号', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _email, decoration: const InputDecoration(labelText: '邮箱', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          _dd('角色', _role, [('ADMIN', '管理员'), ('MERCHANT', '商家'), ('CUSTOMER', '用户')], (v) => setState(() => _role = v)),
          const SizedBox(height: 12),
          _dd('会员等级', _level, [('NORMAL', '普通'), ('VIP', 'VIP'), ('SVIP', 'SVIP')], (v) => setState(() => _level = v)),
          const SizedBox(height: 12),
          _dd('状态', _status, [('ACTIVE', '启用'), ('DISABLED', '禁用')], (v) => setState(() => _status = v)),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        ElevatedButton(onPressed: () {
          final p = <String, dynamic>{
            'displayName': _name.text.trim(), 'role': _role, 'memberLevel': _level, 'status': _status,
            'phone': _phone.text.trim(), 'email': _email.text.trim(),
          };
          if (_isNew) {
            if (_uname.text.trim().isEmpty) return _snack('请输入用户名');
            if (_pwd.text.isEmpty) return _snack('请输入密码');
            p['username'] = _uname.text.trim();
            p['password'] = _pwd.text;
          } else if (_pwd.text.isNotEmpty) {
            p['password'] = _pwd.text;
          }
          Navigator.pop(context, p);
        }, child: const Text('保存')),
      ],
    );
  }

  Widget _dd(String label, String val, List<(String, String)> items, ValueChanged<String> cb) {
    return DropdownButtonFormField<String>(
      value: val,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: items.map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2))).toList(),
      onChanged: (v) { if (v != null) cb(v); },
    );
  }

  void _snack(String s) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s), behavior: SnackBarBehavior.floating));
  }
}
