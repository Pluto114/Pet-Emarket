/// 地图选点 — 只负责取经纬度，不覆盖地址
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/api/api_client.dart';

class MapPickerResult {
  final double longitude, latitude;
  const MapPickerResult({required this.longitude, required this.latitude});
}

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({required this.apiClient, this.lat = 30.2741, this.lng = 120.1551, super.key});
  final ApiClient apiClient;
  final double lat, lng;

  @override State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  late double _lat, _lng;
  bool _picked = false;

  @override void initState() { super.initState(); _lat = widget.lat; _lng = widget.lng; }

  void _pick(LatLng ll) => setState(() { _lat = ll.latitude; _lng = ll.longitude; _picked = true; });

  void _confirm() {
    if (!_picked) return;
    Navigator.pop(context, MapPickerResult(longitude: _lng, latitude: _lat));
  }

  @override Widget build(BuildContext ctx) {
    final s = Theme.of(ctx).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('在地图上选点'), actions: [
        TextButton(onPressed: _picked ? _confirm : null, child: const Text('确认')),
      ]),
      body: Stack(children: [
        FlutterMap(
          options: MapOptions(initialCenter: LatLng(_lat, _lng), initialZoom: 14, onTap: (_, ll) => _pick(ll)),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.petemarket.app'),
            MarkerLayer(markers: [Marker(point: LatLng(_lat, _lng), width: 40, height: 40, child: const Icon(Icons.location_on, color: Color(0xFFFF4444), size: 40))]),
          ],
        ),
        if (_picked) Positioned(bottom: 16, left: 16, right: 16, child: Container(
          padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: s.surface, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
          child: Text('${_lng.toStringAsFixed(5)}, ${_lat.toStringAsFixed(5)}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
        )),
      ]),
    );
  }
}
