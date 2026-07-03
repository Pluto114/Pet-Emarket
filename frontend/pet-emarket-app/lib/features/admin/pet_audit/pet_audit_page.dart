import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../models/product.dart';

class PetAuditPage extends StatefulWidget {
  const PetAuditPage({required this.apiClient, super.key});
  final ApiClient apiClient;
  @override
  State<PetAuditPage> createState() => _PetAuditPageState();
}

class _PetAuditPageState extends State<PetAuditPage> {
  bool loading = true;
  List<Product> livePets = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      livePets = await widget.apiClient.listLivePetAudits();
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '宠物审核',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: CircularProgressIndicator(),
              ),
            ),
          if (!loading && livePets.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('暂无待审核宠物'),
              ),
            ),
          ...livePets.map(
            (p) => Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.pets, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            p.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Chip(
                          label: Text(
                            p.auditStatus.isNotEmpty ? p.auditStatus : p.status,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '编号：${p.livePet?['petCode']?.toString() ?? '-'}  健康：${p.livePet?['healthStatus']?.toString() ?? '-'}',
                    ),
                    Text(
                      '疫苗：${p.livePet?['vaccineCertNo']?.toString() ?? '-'}  检疫：${p.livePet?['quarantineCertNo']?.toString() ?? '-'}',
                    ),
                    if (p.auditStatus == 'PENDING' || p.status == 'DRAFT') ...[
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: () => _approve(p),
                        child: const Text('审核通过并上架'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approve(Product p) async {
    try {
      await widget.apiClient.auditProduct(
        p.id,
        approved: true,
        remark: 'Approved from admin panel',
      );
      await load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
