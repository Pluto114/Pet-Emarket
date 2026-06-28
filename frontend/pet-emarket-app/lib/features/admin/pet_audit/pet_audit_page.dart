import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../models/product.dart';

class PetAuditPage extends StatefulWidget {
  const PetAuditPage({required this.apiClient, super.key});
  final ApiClient apiClient;
  @override State<PetAuditPage> createState() => _PetAuditPageState();
}

class _PetAuditPageState extends State<PetAuditPage> {
  bool loading = true;
  List<Product> livePets = [];

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final all = await widget.apiClient.listProducts();
      livePets = all.where((p) => p.type == 'PET_LIVE').toList();
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(padding: const EdgeInsets.all(20), children: [
        Text('Pet Audit', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (loading) const Center(child: Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator())),
        if (!loading && livePets.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No live pets'))),
        ...livePets.map((p) => Card(
          child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.pets, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
              Chip(label: Text(p.status)),
            ]),
            const SizedBox(height: 8),
            Text('Code: ${p.livePet?['petCode']?.toString() ?? '-'}  Health: ${p.livePet?['healthStatus']?.toString() ?? '-'}'),
            Text('Vaccine: ${p.livePet?['vaccineCertNo']?.toString() ?? '-'}  Quarantine: ${p.livePet?['quarantineCertNo']?.toString() ?? '-'}'),
            if (p.status == 'DRAFT') ...[
              const SizedBox(height: 8),
              FilledButton(onPressed: () => _approve(p), child: const Text('Approve & List')),
            ],
          ])),
        )),
      ]),
    );
  }

  Future<void> _approve(Product p) async {
    try {
      await widget.apiClient.updateProduct(p.id, {'status': 'ON_SALE'});
      await load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

