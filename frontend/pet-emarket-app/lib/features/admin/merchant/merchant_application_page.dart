import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../models/merchant_application.dart';
import '../../../shared/widgets/toast.dart';

class MerchantApplicationPage extends StatefulWidget {
  const MerchantApplicationPage({required this.apiClient, super.key});
  final ApiClient apiClient;

  @override
  State<MerchantApplicationPage> createState() => _State();
}

class _State extends State<MerchantApplicationPage> {
  bool _loading = true;
  String? _error;
  String _statusFilter = '';
  String _keyword = '';
  List<MerchantApplication> _all = [];
  final _searchCtrl = TextEditingController();

  List<MerchantApplication> get _filtered {
    var list = _all;
    if (_statusFilter.isNotEmpty) list = list.where((a) => a.status == _statusFilter).toList();
    if (_keyword.isNotEmpty) {
      final kw = _keyword.toLowerCase();
      list = list.where((a) => a.storeName.toLowerCase().contains(kw) || (a.contactName?.toLowerCase().contains(kw) ?? false) || (a.contactPhone?.contains(kw) ?? false)).toList();
    }
    return list;
  }

  int get _pendingCount => _all.where((a) => a.status == 'PENDING').length;
  int get _approvedCount => _all.where((a) => a.status == 'APPROVED').length;
  int get _rejectedCount => _all.where((a) => a.status == 'REJECTED').length;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _all = await widget.apiClient.listMerchantApplications(status: '');
    } catch (e) { _error = e.toString(); }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _audit(MerchantApplication a, bool approved) async {
    final remarkCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(approved ? '通过申请 — ${a.storeName}' : '驳回申请 — ${a.storeName}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          if (!approved) ...[
            const Text('请填写驳回原因，商家可据此修改后重新申请。', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: remarkCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: approved ? '审核意见（可选）' : '驳回原因',
              border: const OutlineInputBorder(),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () { remarkCtrl.dispose(); Navigator.pop(context, false); }, child: const Text('取消')),
          ElevatedButton(
            onPressed: () { remarkCtrl.dispose(); Navigator.pop(context, true); },
            style: ElevatedButton.styleFrom(backgroundColor: approved ? const Color(0xFF3F9E53) : Colors.red, foregroundColor: Colors.white),
            child: Text(approved ? '确认通过' : '确认驳回'),
          ),
        ],
      ),
    );
    if (result != true) return;
    try {
      await widget.apiClient.auditMerchantApplication(a.id, approved: approved, remark: remarkCtrl.text.trim().isEmpty ? (approved ? '资料完整，准予入驻' : '资料不完整，请补充后重新申请') : remarkCtrl.text.trim());
      await _load();
      if (mounted) showSuccess(context, approved ? '已通过' : '已驳回');
    } catch (e) { if (mounted) showError(context, e.toString()); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _load, child: const Text('重试')),
        ]),
      );
    }

    final items = _filtered;

    if (items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('商家审核', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          _buildStatsRow(),
          const SizedBox(height: 20),
          _buildSearchRow(),
          const SizedBox(height: 40),
          const Center(child: Text('暂无商家申请', style: TextStyle(color: Colors.grey, fontSize: 15))),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('商家审核', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),
        _buildStatsRow(),
        const SizedBox(height: 20),
        _buildSearchRow(),
        const SizedBox(height: 12),
        Text('共 ${items.length} 条记录', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        const SizedBox(height: 12),
        for (final a in items)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: a.status == 'PENDING' ? Colors.orange.withAlpha(40) : a.status == 'APPROVED' ? Colors.green.withAlpha(40) : Colors.red.withAlpha(40),
                  child: Icon(a.status == 'PENDING' ? Icons.access_time : a.status == 'APPROVED' ? Icons.check_circle : Icons.cancel, color: a.status == 'PENDING' ? Colors.orange : a.status == 'APPROVED' ? Colors.green : Colors.red, size: 20)),
              title: Text(a.storeName, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${a.city} ${a.district} · ${a.contactName} ${a.contactPhone}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (a.status == 'PENDING') ...[
                  TextButton(onPressed: () => _audit(a, false), child: const Text('驳回', style: TextStyle(color: Colors.red, fontSize: 12))),
                  const SizedBox(width: 4),
                  TextButton(onPressed: () => _audit(a, true), child: const Text('通过', style: TextStyle(fontSize: 12))),
                ],
                if (a.status == 'REJECTED')
                  TextButton(onPressed: () => _audit(a, true), child: const Text('重新审核', style: TextStyle(fontSize: 12))),
              ]),
            ),
          ),
      ],
    );
  }

  // ---- Stats Row ----
  Widget _buildStatsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        _statCard('全部申请', _all.length, Icons.fact_check_outlined, const Color(0xFF7A8B3C)),
        const SizedBox(width: 12),
        _statCard('待审核', _pendingCount, Icons.access_time, const Color(0xFFE8BF20)),
        const SizedBox(width: 12),
        _statCard('已通过', _approvedCount, Icons.check_circle_outline, const Color(0xFF3F9E53)),
        const SizedBox(width: 12),
        _statCard('已驳回', _rejectedCount, Icons.cancel_outlined, Colors.red),
      ]),
    );
  }

  Widget _statCard(String label, int count, IconData icon, Color color) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 6, offset: const Offset(0, 2))]),
      child: Row(children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 19, color: color)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.grey.shade800)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ]),
      ]),
    );
  }

  // ---- Search Row ----
  Widget _buildSearchRow() {
    return Row(children: [
      Expanded(
        child: TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(hintText: '搜索商家名称...', prefixIcon: const Icon(Icons.search, size: 20), isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
          onSubmitted: (v) => setState(() { _keyword = v.trim(); }),
        ),
      ),
      const SizedBox(width: 8),
      SizedBox(width: 110,
        child: DropdownButtonFormField<String>(
          value: _statusFilter.isEmpty ? null : _statusFilter,
          decoration: InputDecoration(isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
          hint: const Text('全部状态', style: TextStyle(fontSize: 13)),
          items: const [
            DropdownMenuItem(value: 'PENDING', child: Text('待审核', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: 'APPROVED', child: Text('已通过', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: 'REJECTED', child: Text('已驳回', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: '', child: Text('全部状态', style: TextStyle(fontSize: 13))),
          ],
          onChanged: (v) => setState(() { _statusFilter = v ?? ''; }),
          isExpanded: false,
        ),
      ),
    ]);
  }

  // ---- Application Card ----
  Widget _buildCard(MerchantApplication a, ThemeData theme) {
    final isPending = a.status == 'PENDING';
    final isApproved = a.status == 'APPROVED';
    final borderColor = isPending ? const Color(0xFFF0D345) : isApproved ? const Color(0xFF5DBA6E) : const Color(0xFFEF6E6E);
    final statusLabel = isPending ? '待审核' : isApproved ? '已通过' : '已驳回';
    final statusColor = isPending ? const Color(0xFFE8BF20) : isApproved ? const Color(0xFF3F9E53) : const Color(0xFFDC4A4A);
    final statusBg = isPending ? const Color(0xFFFDF7D5) : isApproved ? const Color(0xFFDCF5DF) : const Color(0xFFFDE0E0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6, offset: const Offset(0, 2))],
        border: Border(left: BorderSide(color: borderColor, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header: name + badge + time
          Row(children: [
            Expanded(child: Text(a.storeName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF36322E)))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(12)),
              child: Text(statusLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
            ),
            const SizedBox(width: 8),
            Text(_fmtTime(a.createdAt), style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
          ]),
          const SizedBox(height: 14),

          // Info grid (2 cols)
          Row(children: [
            Expanded(child: _infoRow('联系人', a.contactName)),
            const SizedBox(width: 24),
            Expanded(child: _infoRow('联系电话', a.contactPhone)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _infoRow('经营地址', '${a.city} ${a.district} ${a.address}')),
            const SizedBox(width: 24),
            Expanded(child: _infoRow('营业执照', a.businessLicenseNo.isNotEmpty ? a.businessLicenseNo : '未提供')),
          ]),
          if (a.reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            _infoRow('申请说明', a.reason),
          ],

          // Audit remark (for approved/rejected)
          if (a.auditRemark.isNotEmpty && !isPending) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isApproved ? const Color(0xFFF0FAF2) : const Color(0xFFFEF2F2),
                border: Border(left: BorderSide(color: isApproved ? const Color(0xFF8CD49B) : const Color(0xFFF79E9E), width: 3)),
                borderRadius: const BorderRadius.only(topRight: Radius.circular(6), bottomRight: Radius.circular(6)),
              ),
              child: Text('"${a.auditRemark}"', style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: isApproved ? const Color(0xFF256436) : const Color(0xFF9C2828))),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Action bar
          if (isPending)
            Row(children: [
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => _audit(a, false),
                icon: const Icon(Icons.close, size: 16, color: Colors.red),
                label: const Text('驳回申请', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _audit(a, true),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('通过并开通'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3F9E53), foregroundColor: Colors.white),
              ),
            ]),
          if (isApproved)
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.visibility_outlined, size: 16), label: const Text('查看详情')),
              const SizedBox(width: 8),
              OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.pause_circle_outline, size: 16), label: const Text('暂停营业')),
            ]),
          if (!isPending && !isApproved)
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              OutlinedButton.icon(onPressed: () => _audit(a, true), icon: const Icon(Icons.refresh, size: 16), label: const Text('重新审核')),
            ]),
        ]),
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 60, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500))),
      Expanded(child: Text(value ?? '-', style: const TextStyle(fontSize: 13, color: Color(0xFF36322E)))),
    ]);
  }

  String _fmtTime(String? t) {
    if (t == null || t.isEmpty) return '';
    try { final d = DateTime.parse(t); return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}'; } catch (_) { return ''; }
  }
}
