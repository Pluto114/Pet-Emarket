import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../models/merchant_application.dart';
import '../../../shared/widgets/toast.dart';

class MerchantApplicationPage extends StatefulWidget {
  const MerchantApplicationPage({required this.apiClient, super.key});

  final ApiClient apiClient;

  @override
  State<MerchantApplicationPage> createState() =>
      _MerchantApplicationPageState();
}

class _MerchantApplicationPageState extends State<MerchantApplicationPage> {
  bool loading = true;
  String? errorText;
  String status = '';
  List<MerchantApplication> applications = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      errorText = null;
    });
    try {
      applications = await widget.apiClient.listMerchantApplications(
        status: status,
      );
    } catch (e) {
      errorText = e.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _audit(MerchantApplication application, bool approved) async {
    try {
      await widget.apiClient.auditMerchantApplication(
        application.id,
        approved: approved,
        remark: approved ? '资料完整，准予入驻' : '资料不完整，请补充后重新申请',
      );
      await load();
      if (mounted) showSuccess(context, approved ? '已通过商家申请' : '已驳回商家申请');
    } catch (e) {
      if (mounted) showError(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '商家审核',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              DropdownButton<String>(
                value: status,
                items: const [
                  DropdownMenuItem(value: '', child: Text('全部')),
                  DropdownMenuItem(value: 'PENDING', child: Text('待审核')),
                  DropdownMenuItem(value: 'APPROVED', child: Text('已通过')),
                  DropdownMenuItem(value: 'REJECTED', child: Text('已驳回')),
                ],
                onChanged: (value) {
                  setState(() => status = value ?? '');
                  load();
                },
              ),
              IconButton(onPressed: load, icon: const Icon(Icons.refresh)),
            ],
          ),
          const SizedBox(height: 12),
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: CircularProgressIndicator(),
              ),
            ),
          if (errorText != null)
            Text(errorText!, style: TextStyle(color: theme.colorScheme.error)),
          if (!loading && errorText == null && applications.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('暂无商家申请'),
              ),
            ),
          if (!loading && errorText == null)
            ...applications.map(
              (application) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              application.storeName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Chip(label: Text(application.status)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${application.city} ${application.district} · ${application.address}',
                      ),
                      Text(
                        '坐标：${application.longitude.toStringAsFixed(4)}, ${application.latitude.toStringAsFixed(4)}',
                      ),
                      Text(
                        '联系人：${application.contactName} ${application.contactPhone}',
                      ),
                      if (application.businessLicenseNo.isNotEmpty)
                        Text('营业执照：${application.businessLicenseNo}'),
                      if (application.reason.isNotEmpty)
                        Text('申请说明：${application.reason}'),
                      if (application.auditRemark.isNotEmpty)
                        Text('审核意见：${application.auditRemark}'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilledButton(
                            onPressed:
                                application.status == 'PENDING'
                                    ? () => _audit(application, true)
                                    : null,
                            child: const Text('通过并开通商家'),
                          ),
                          OutlinedButton(
                            onPressed:
                                application.status == 'PENDING'
                                    ? () => _audit(application, false)
                                    : null,
                            child: const Text('驳回'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
