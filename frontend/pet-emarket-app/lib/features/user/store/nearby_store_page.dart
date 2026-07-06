/// 附近宠物商店 — flutter_map 真实瓦片地图
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
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
  final MapController _mapController = MapController();
  bool loading = true;
  bool locating = false;
  String? errorText;
  String? locationHint;
  List<PetStore> stores = [];
  List<AmapPoi> amapPois = [];
  int selectedIndex = -1;
  LatLng center = const LatLng(_defaultLat, _defaultLng);
  LatLng? userLocation;

  @override
  void initState() {
    super.initState();
    loadData(refreshLocation: true);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> loadData({bool refreshLocation = false}) async {
    setState(() {
      loading = true;
      errorText = null;
      if (refreshLocation) locationHint = null;
    });
    try {
      final current = await _resolveLocation(refresh: refreshLocation);
      final nextStores = await widget.apiClient.nearbyStores(
        longitude: current.longitude,
        latitude: current.latitude,
        radiusKm: 30,
      );
      List<AmapPoi> nextPois = [];
      try {
        nextPois = await widget.apiClient.nearbyAmapPetStores(
          longitude: current.longitude,
          latitude: current.latitude,
          radius: 10000,
        );
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        center = current;
        stores = nextStores;
        amapPois = nextPois;
        selectedIndex = -1;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _mapController.move(center, 13.5);
      });
    } catch (e) {
      if (mounted) setState(() => errorText = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<LatLng> _resolveLocation({bool refresh = false}) async {
    if (!refresh && userLocation != null) return userLocation!;
    setState(() => locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return const LatLng(_defaultLat, _defaultLng);
      if (!serviceEnabled) {
        setState(() => locationHint = '定位服务未开启，已显示默认城市附近商家');
        return const LatLng(_defaultLat, _defaultLng);
      }

      var permission = await Geolocator.checkPermission();
      if (!mounted) return const LatLng(_defaultLat, _defaultLng);
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (!mounted) return const LatLng(_defaultLat, _defaultLng);
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => locationHint = '未获得定位权限，已显示默认城市附近商家');
        return const LatLng(_defaultLat, _defaultLng);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      if (!mounted) return const LatLng(_defaultLat, _defaultLng);
      final current = LatLng(position.latitude, position.longitude);
      setState(() {
        userLocation = current;
        locationHint = null;
      });
      return current;
    } catch (_) {
      if (mounted) setState(() => locationHint = '定位暂不可用，已显示默认城市附近商家');
      return userLocation ?? const LatLng(_defaultLat, _defaultLng);
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  void _selectStore(int index) {
    final store = stores[index];
    final point = LatLng(store.latitude, store.longitude);
    setState(() => selectedIndex = index);
    _mapController.move(point, 15);
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    if (userLocation != null) {
      markers.add(Marker(
        point: userLocation!,
        width: 34,
        height: 34,
        child: const _UserMarker(),
      ));
    }
    for (var i = 0; i < stores.length; i++) {
      final s = stores[i];
      markers.add(Marker(
        point: LatLng(s.latitude, s.longitude), width: 40, height: 40,
        child: GestureDetector(onTap: () => _selectStore(i), child: _StoreMarker(label: '${i + 1}', selected: selectedIndex == i)),
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
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(initialCenter: center, initialZoom: 13.5, onTap: (_, __) => setState(() => selectedIndex = -1)),
                children: [
                  TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.petemarket.app'),
                  MarkerLayer(markers: _buildMarkers()),
                ],
              ),
              Positioned(
                right: 14,
                bottom: 14,
                child: FloatingActionButton.small(
                  heroTag: 'nearby-locate',
                  onPressed: locating ? null : () => loadData(refreshLocation: true),
                  backgroundColor: Colors.white,
                  foregroundColor: PawmartColors.primary500,
                  child: locating
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location_rounded),
                ),
              ),
              if (locationHint != null)
                Positioned(
                  left: 12,
                  right: 72,
                  top: 12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(235),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: pawmartShadow1,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Text(
                        locationHint!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: PawmartColors.textSecondary),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(child: loading
          ? const Center(child: CircularProgressIndicator())
          : errorText != null
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(errorText!, style: TextStyle(color: theme.colorScheme.error)), const SizedBox(height: 8), OutlinedButton(onPressed: () => loadData(), child: const Text('重试'))]))
            : ListView(physics: const BouncingScrollPhysics(), padding: const EdgeInsets.only(top: 8), children: [
                if (stores.isEmpty) _emptyStoreHint(theme),
                ..._storeTiles(theme),
                if (amapPois.isNotEmpty) _poiSection(theme),
              ])),
      ]),
    );
  }

  Widget _emptyStoreHint(ThemeData theme) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 44, 24, 20),
    child: Column(
      children: [
        Icon(Icons.storefront_outlined, size: 42, color: PawmartColors.neutral400),
        const SizedBox(height: 10),
        Text(
          '附近没有哦',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: PawmartColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '可以稍后再试，或看看下方高德附近宠物店',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: PawmartColors.textSecondary),
        ),
      ],
    ),
  );

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
        onTap: () => _selectStore(i),
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
      ...List.generate(amapPois.length > 5 ? 5 : amapPois.length, (i) {
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

class _UserMarker extends StatelessWidget {
  const _UserMarker();

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF2F80ED).withAlpha(45),
      shape: BoxShape.circle,
    ),
    child: Center(
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: const Color(0xFF2F80ED),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
        ),
      ),
    ),
  );
}
