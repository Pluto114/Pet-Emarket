/// 附近宠物商店 — flutter_map 真实瓦片地图
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/amap_poi.dart';
import '../../../models/store.dart';
import 'store_detail_page.dart';

const _defaultLat = 30.2741;
const _defaultLng = 120.1551;

class NearbyStorePage extends StatefulWidget {
  const NearbyStorePage({required this.apiClient, super.key});
  final ApiClient apiClient;
  @override State<NearbyStorePage> createState() => _NearbyStorePageState();
}

class _NearbyStorePageState extends State<NearbyStorePage> {
  bool loading = true;
  String? errorText;
  List<PetStore> stores = [];
  List<AmapPoi> amapPois = [];
  int selectedIndex = -1;

  @override void initState() { super.initState(); loadData(); }

  Future<void> loadData() async {
    setState(() { loading = true; errorText = null; });
    try { stores = await widget.apiClient.nearbyStores(longitude: _defaultLng, latitude: _defaultLat, radiusKm: 30); } catch (e) { errorText = e.toString(); }
    try { amapPois = await widget.apiClient.nearbyAmapPetStores(longitude: _defaultLng, latitude: _defaultLat, radius: 10000); } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    for (var i = 0; i < stores.length; i++) {
      final s = stores[i];
      markers.add(Marker(
        point: LatLng(s.latitude, s.longitude), width: 40, height: 40,
        child: GestureDetector(onTap: () => setState(() => selectedIndex = i), child: _StoreMarker(label: '${i + 1}', selected: selectedIndex == i)),
      ));
    }
    for (final p in amapPois) {
      markers.add(Marker(
        point: LatLng(p.latitude, p.longitude), width: 32, height: 32,
        child: _PoiMarker(),
      ));
    }
    return markers;
  }

  @override Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    return Scaffold(
      body: Column(children: [
        SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.42,
          child: FlutterMap(
            options: MapOptions(initialCenter: const LatLng(_defaultLat, _defaultLng), initialZoom: 13.5, onTap: (_, __) => setState(() => selectedIndex = -1)),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.petemarket.app'),
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),
        ),
        Expanded(child: loading
          ? const Center(child: CircularProgressIndicator())
          : errorText != null
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(errorText!, style: TextStyle(color: theme.colorScheme.error)), const SizedBox(height: 8), OutlinedButton(onPressed: loadData, child: const Text('重试'))]))
            : ListView(physics: const BouncingScrollPhysics(), padding: const EdgeInsets.only(top: 8), children: [
                ..._storeTiles(theme),
                if (amapPois.isNotEmpty) _poiSection(theme),
              ])),
      ]),
    );
  }

  void _openDetail(BuildContext context, PetStore store) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoreDetailPage(apiClient: widget.apiClient, store: store),
      ),
    );
  }

  List<Widget> _storeTiles(ThemeData theme) => List.generate(stores.length, (i) {
    final s = stores[i];
    final isSelected = selectedIndex == i;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => setState(() => selectedIndex = i),
        borderRadius: BorderRadius.circular(pawmartRadiusMd),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? PawmartColors.primary50 : PawmartColors.surfaceCard,
            borderRadius: BorderRadius.circular(pawmartRadiusMd),
            border: Border.all(
              color: isSelected ? PawmartColors.primary200 : PawmartColors.neutral200,
            ),
            boxShadow: isSelected ? pawmartShadow1 : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected ? PawmartColors.primary500 : PawmartColors.primary100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: isSelected ? Colors.white : PawmartColors.primary500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: PawmartColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 13, color: PawmartColors.textSecondary),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '${s.district} · ${s.address}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: PawmartColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 14, color: PawmartColors.accent400),
                        const SizedBox(width: 2),
                        Text(
                          '${s.rating}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: PawmartColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.near_me_outlined, size: 12, color: PawmartColors.textSecondary),
                        const SizedBox(width: 2),
                        Text(
                          '${s.distanceKm?.toStringAsFixed(1) ?? "?"}km',
                          style: TextStyle(
                            fontSize: 12,
                            color: PawmartColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _openDetail(context, s),
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                color: PawmartColors.neutral400,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
      ),
    );
  });

  Widget _poiSection(ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: PawmartColors.info,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '高德真实附近宠物店',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: PawmartColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
      ...List.generate(amapPois.length.clamp(0, 5), (i) {
        final p = amapPois[i];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PawmartColors.surfaceCard,
              borderRadius: BorderRadius.circular(pawmartRadiusMd),
              border: Border.all(color: PawmartColors.neutral200),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: PawmartColors.info.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.location_on, size: 16, color: PawmartColors.info),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: PawmartColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${p.address} · ${p.distanceMeters != null ? "${(p.distanceMeters! / 1000).toStringAsFixed(1)}km" : ""}',
                        style: TextStyle(
                          fontSize: 12,
                          color: PawmartColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    ],
  );
}

class _StoreMarker extends StatelessWidget {
  const _StoreMarker({required this.label, required this.selected});
  final String label; final bool selected;
  @override Widget build(BuildContext c) => Container(
    width: selected ? 40 : 32, height: selected ? 40 : 32,
    decoration: BoxDecoration(color: selected ? const Color(0xFFFF6F22) : const Color(0xFF7A8B3C), shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: selected ? 3 : 2), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)]),
    child: Center(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))),
  );
}

class _PoiMarker extends StatelessWidget {
  @override Widget build(BuildContext c) => Container(width: 24, height: 24,
    decoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
    child: const Icon(Icons.location_on, color: Colors.white, size: 14),
  );
}
