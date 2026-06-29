import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../models/store.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/toast.dart';

class StoreManagePage extends StatefulWidget {
  const StoreManagePage({required this.apiClient, super.key});
  final ApiClient apiClient;

  @override
  State<StoreManagePage> createState() => _StoreManagePageState();
}

class _StoreManagePageState extends State<StoreManagePage> {
  bool loading = true;
  String? errorText;
  List<PetStore> stores = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() { loading = true; errorText = null; });
    try {
      stores = await widget.apiClient.listStores(authenticated: true);
    } catch (e) {
      errorText = e.toString();
    }
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
          Row(
            children: [
              Expanded(child: Text('Store Management', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700))),
              FilledButton.icon(onPressed: () => _showDialog(), icon: const Icon(Icons.add), label: const Text('Add Store')),
            ],
          ),
          const SizedBox(height: 12),
          if (loading) const Center(child: Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator())),
          if (errorText != null) Text(errorText!, style: TextStyle(color: theme.colorScheme.error)),
          if (!loading && errorText == null && stores.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No stores yet'))),
          if (!loading && errorText == null)
            ...stores.map((store) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(Icons.store, color: theme.colorScheme.primary),
                ),
                title: Text(store.name),
                subtitle: Text('${store.city} ${store.district} · ${store.address}\nRating ${store.rating.toStringAsFixed(1)} · ${store.status}'),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit), onPressed: () => _showDialog(store: store)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(store)),
                  ],
                ),
              ),
            )),
        ],
      ),
    );
  }

  Future<void> _showDialog({PetStore? store}) async {
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (ctx) => _StoreDialog(store: store));
    if (result == null) return;
    try {
      if (store == null) {
        await widget.apiClient.createStore(result);
        if (mounted) showSuccess(context, 'Store created');
      } else {
        await widget.apiClient.updateStore(store.id, result);
        if (mounted) showSuccess(context, 'Store updated');
      }
      await load();
    } catch (e) {
      if (mounted) showError(context, e.toString());
    }
  }

  Future<void> _delete(PetStore store) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Store',
      message: 'Are you sure you want to delete "${store.name}"?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await widget.apiClient.deleteStore(store.id);
      await load();
      if (mounted) showSuccess(context, 'Store deleted');
    } catch (e) {
      if (mounted) showError(context, e.toString());
    }
  }
}

class _StoreDialog extends StatefulWidget {
  const _StoreDialog({this.store});
  final PetStore? store;

  @override
  State<_StoreDialog> createState() => _StoreDialogState();
}

class _StoreDialogState extends State<_StoreDialog> {
  late final nameCtrl = TextEditingController(text: widget.store?.name ?? '');
  late final addressCtrl = TextEditingController(text: widget.store?.address ?? '');
  late final cityCtrl = TextEditingController(text: widget.store?.city ?? 'Hangzhou');
  late final districtCtrl = TextEditingController(text: widget.store?.district ?? 'Xihu');
  late final longitudeCtrl = TextEditingController(text: widget.store?.longitude.toString() ?? '120.1551');
  late final latitudeCtrl = TextEditingController(text: widget.store?.latitude.toString() ?? '30.2741');
  late final phoneCtrl = TextEditingController(text: widget.store?.phone ?? '');
  late final hoursCtrl = TextEditingController(text: widget.store?.businessHours ?? '09:00-21:00');
  late final ratingCtrl = TextEditingController(text: widget.store?.rating.toString() ?? '4.8');
  late final tagsCtrl = TextEditingController(text: widget.store?.featureTags ?? '');
  String status = 'OPEN';

  @override
  void initState() {
    super.initState();
    status = widget.store?.status ?? 'OPEN';
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    addressCtrl.dispose();
    cityCtrl.dispose();
    districtCtrl.dispose();
    longitudeCtrl.dispose();
    latitudeCtrl.dispose();
    phoneCtrl.dispose();
    hoursCtrl.dispose();
    ratingCtrl.dispose();
    tagsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.store == null ? 'Add Store' : 'Edit Store'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Store Name')),
              const SizedBox(height: 10),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address')),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'City'))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: districtCtrl, decoration: const InputDecoration(labelText: 'District'))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextField(controller: longitudeCtrl, decoration: const InputDecoration(labelText: 'Longitude'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: latitudeCtrl, decoration: const InputDecoration(labelText: 'Latitude'), keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextField(controller: ratingCtrl, decoration: const InputDecoration(labelText: 'Rating'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(value: 'OPEN', child: Text('Open')),
                        DropdownMenuItem(value: 'CLOSED', child: Text('Closed')),
                      ],
                      onChanged: (value) => setState(() => status = value ?? status),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
              const SizedBox(height: 10),
              TextField(controller: hoursCtrl, decoration: const InputDecoration(labelText: 'Business Hours')),
              const SizedBox(height: 10),
              TextField(controller: tagsCtrl, decoration: const InputDecoration(labelText: 'Feature Tags')),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final payload = {
              'name': nameCtrl.text.trim(),
              'address': addressCtrl.text.trim(),
              'city': cityCtrl.text.trim(),
              'district': districtCtrl.text.trim(),
              'longitude': double.tryParse(longitudeCtrl.text) ?? 120.1551,
              'latitude': double.tryParse(latitudeCtrl.text) ?? 30.2741,
              'phone': phoneCtrl.text.trim(),
              'businessHours': hoursCtrl.text.trim(),
              'rating': double.tryParse(ratingCtrl.text) ?? 4.8,
              'status': status,
              'featureTags': tagsCtrl.text.trim(),
            };
            Navigator.pop(context, payload);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
