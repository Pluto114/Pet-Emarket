import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../models/amap_poi.dart';
import '../../../models/store.dart';
import 'store_detail_page.dart';

class NearbyStorePage extends StatefulWidget {
  const NearbyStorePage({required this.apiClient, super.key});
  final ApiClient apiClient;

  @override
  State<NearbyStorePage> createState() => _NearbyStorePageState();
}

class _NearbyStorePageState extends State<NearbyStorePage> {
  bool loading = true;
  String? errorText;
  String? amapErrorText;
  List<PetStore> stores = [];
  List<AmapPoi> amapPois = [];
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() {
      loading = true;
      errorText = null;
    });
    try {
      final loaded = await widget.apiClient.nearbyStores();
      stores = loaded;
      selectedIndex =
          stores.isEmpty ? 0 : math.min(selectedIndex, stores.length - 1);
      try {
        amapPois = await widget.apiClient.nearbyAmapPetStores();
        amapErrorText = null;
      } catch (e) {
        amapPois = [];
        amapErrorText = e.toString();
      }
    } catch (e) {
      errorText = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('附近宠物商店')),
      body: RefreshIndicator(
        onRefresh: loadData,
        child:
            loading
                ? const Center(child: CircularProgressIndicator())
                : errorText != null
                ? _ErrorState(errorText: errorText!, onRetry: loadData)
                : stores.isEmpty
                ? _EmptyState(theme: theme)
                : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _StoreMapPanel(
                      stores: stores,
                      selectedIndex: selectedIndex,
                      onSelect:
                          (index) => setState(() => selectedIndex = index),
                    ),
                    const SizedBox(height: 14),
                    _SelectedStoreCard(store: stores[selectedIndex]),
                    const SizedBox(height: 18),
                    _AmapPoiSection(pois: amapPois, errorText: amapErrorText),
                    const SizedBox(height: 18),
                    Text(
                      '附近门店 ${stores.length}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...stores.asMap().entries.map((entry) {
                      final index = entry.key;
                      final store = entry.value;
                      final selected = index == selectedIndex;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _StoreListTile(
                          store: store,
                          index: index,
                          selected: selected,
                          onTap: () => setState(() => selectedIndex = index),
                          onOpen: () => _openDetail(context, store),
                        ),
                      );
                    }),
                  ],
                ),
      ),
    );
  }

  void _openDetail(BuildContext context, PetStore store) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoreDetailPage(apiClient: widget.apiClient, store: store),
      ),
    );
  }
}

class _AmapPoiSection extends StatelessWidget {
  const _AmapPoiSection({required this.pois, required this.errorText});

  final List<AmapPoi> pois;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.public, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '高德真实附近宠物店',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text('${pois.length} 家', style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 10),
            if (errorText != null)
              Text(errorText!, style: TextStyle(color: theme.colorScheme.error))
            else if (pois.isEmpty)
              Text('暂无高德 POI 结果', style: theme.textTheme.bodySmall)
            else
              ...pois.take(5).map((poi) {
                final distance =
                    poi.distanceMeters == null
                        ? ''
                        : '  |  ${poi.distanceMeters!.toStringAsFixed(0)}m';
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.pets_outlined),
                  title: Text(
                    poi.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${poi.district}  |  ${poi.address}$distance',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _StoreMapPanel extends StatelessWidget {
  const _StoreMapPanel({
    required this.stores,
    required this.selectedIndex,
    required this.onSelect,
  });

  static const double userLongitude = 120.1551;
  static const double userLatitude = 30.2741;

  final List<PetStore> stores;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final markers = _markerOffsets(size);
          final user = _project(userLongitude, userLatitude, size);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              int? nearest;
              double nearestDistance = 34;
              for (int i = 0; i < markers.length; i++) {
                final distance = (markers[i] - details.localPosition).distance;
                if (distance < nearestDistance) {
                  nearest = i;
                  nearestDistance = distance;
                }
              }
              if (nearest != null) onSelect(nearest);
            },
            child: CustomPaint(
              painter: _StoreMapPainter(
                stores: stores,
                markers: markers,
                user: user,
                selectedIndex: selectedIndex,
                colorScheme: theme.colorScheme,
              ),
              child: const SizedBox.expand(),
            ),
          );
        },
      ),
    );
  }

  List<Offset> _markerOffsets(Size size) {
    return stores
        .map((store) => _project(store.longitude, store.latitude, size))
        .toList();
  }

  Offset _project(double longitude, double latitude, Size size) {
    double minLng = userLongitude;
    double maxLng = userLongitude;
    double minLat = userLatitude;
    double maxLat = userLatitude;
    for (final store in stores) {
      minLng = math.min(minLng, store.longitude);
      maxLng = math.max(maxLng, store.longitude);
      minLat = math.min(minLat, store.latitude);
      maxLat = math.max(maxLat, store.latitude);
    }

    const padding = 34.0;
    final width = math.max(1.0, size.width - padding * 2);
    final height = math.max(1.0, size.height - padding * 2);
    final x = padding + _ratio(longitude, minLng, maxLng) * width;
    final y = padding + (1 - _ratio(latitude, minLat, maxLat)) * height;
    return Offset(x, y);
  }

  double _ratio(double value, double min, double max) {
    if ((max - min).abs() < 0.0001) return 0.5;
    return ((value - min) / (max - min)).clamp(0.0, 1.0);
  }
}

class _StoreMapPainter extends CustomPainter {
  const _StoreMapPainter({
    required this.stores,
    required this.markers,
    required this.user,
    required this.selectedIndex,
    required this.colorScheme,
  });

  final List<PetStore> stores;
  final List<Offset> markers;
  final Offset user;
  final int selectedIndex;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bg =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colorScheme.primaryContainer, colorScheme.surface],
          ).createShader(rect);
    canvas.drawRect(rect, bg);

    final gridPaint =
        Paint()
          ..color = colorScheme.outlineVariant.withAlpha(120)
          ..strokeWidth = 1;
    for (double x = 28; x < size.width; x += 42) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 28; y < size.height; y += 42) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final radiusPaint =
        Paint()
          ..color = colorScheme.primary.withAlpha(28)
          ..style = PaintingStyle.fill;
    canvas.drawCircle(user, 88, radiusPaint);
    canvas.drawCircle(
      user,
      48,
      radiusPaint..color = colorScheme.primary.withAlpha(42),
    );

    if (selectedIndex >= 0 && selectedIndex < markers.length) {
      final selected = markers[selectedIndex];
      final routePaint =
          Paint()
            ..color = colorScheme.primary.withAlpha(180)
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round;
      canvas.drawLine(user, selected, routePaint);
    }

    _drawUser(canvas, user);
    for (int i = 0; i < markers.length; i++) {
      _drawStore(canvas, markers[i], i, i == selectedIndex);
    }

    _drawLabel(canvas, const Offset(16, 14), 'LBS 门店地图');
  }

  void _drawUser(Canvas canvas, Offset offset) {
    canvas.drawCircle(offset, 13, Paint()..color = colorScheme.primary);
    canvas.drawCircle(offset, 5, Paint()..color = colorScheme.onPrimary);
    _drawSmallLabel(canvas, offset + const Offset(15, -22), '你的位置');
  }

  void _drawStore(Canvas canvas, Offset offset, int index, bool selected) {
    final shadow = Paint()..color = Colors.black.withAlpha(selected ? 55 : 32);
    canvas.drawCircle(offset + const Offset(0, 3), selected ? 16 : 12, shadow);
    canvas.drawCircle(
      offset,
      selected ? 16 : 12,
      Paint()..color = selected ? colorScheme.secondary : colorScheme.surface,
    );
    canvas.drawCircle(
      offset,
      selected ? 9 : 7,
      Paint()..color = selected ? colorScheme.onSecondary : colorScheme.primary,
    );
    if (selected) {
      _drawSmallLabel(
        canvas,
        offset + const Offset(18, -28),
        stores[index].name,
      );
    }
  }

  void _drawLabel(Canvas canvas, Offset offset, String text) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final box = Rect.fromLTWH(
      offset.dx - 8,
      offset.dy - 6,
      painter.width + 16,
      painter.height + 12,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, const Radius.circular(10)),
      Paint()..color = colorScheme.surface.withAlpha(220),
    );
    painter.paint(canvas, offset);
  }

  void _drawSmallLabel(Canvas canvas, Offset offset, String text) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 140);
    final box = Rect.fromLTWH(
      offset.dx - 6,
      offset.dy - 4,
      painter.width + 12,
      painter.height + 8,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, const Radius.circular(8)),
      Paint()..color = colorScheme.surface.withAlpha(230),
    );
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _StoreMapPainter oldDelegate) {
    return oldDelegate.stores != stores ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.colorScheme != colorScheme;
  }
}

class _SelectedStoreCard extends StatelessWidget {
  const _SelectedStoreCard({required this.store});

  final PetStore store;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.place_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    store.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text('${store.rating.toStringAsFixed(1)} 分'),
              ],
            ),
            const SizedBox(height: 8),
            Text(store.address),
            const SizedBox(height: 6),
            Text(
              '${store.district}  |  ${store.businessHours.isEmpty ? '营业时间待更新' : store.businessHours}'
              '${store.distanceKm == null ? '' : '  |  ${store.distanceKm!.toStringAsFixed(2)}km'}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreListTile extends StatelessWidget {
  const _StoreListTile({
    required this.store,
    required this.index,
    required this.selected,
    required this.onTap,
    required this.onOpen,
  });

  final PetStore store;
  final int index;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: selected ? theme.colorScheme.primaryContainer : null,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor:
              selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.primaryContainer,
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color:
                  selected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.primary,
            ),
          ),
        ),
        title: Text(store.name),
        subtitle: Text(
          '${store.district}  |  评分 ${store.rating.toStringAsFixed(1)}'
          '${store.distanceKm == null ? '' : '  |  ${store.distanceKm!.toStringAsFixed(2)}km'}',
        ),
        trailing: IconButton(
          tooltip: '查看详情',
          icon: const Icon(Icons.chevron_right),
          onPressed: onOpen,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.errorText, required this.onRetry});

  final String errorText;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text(errorText, style: TextStyle(color: theme.colorScheme.error)),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.store_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          const Text('附近暂无商店'),
          const SizedBox(height: 8),
          Text('可稍后扩大搜索半径或检查定位信息', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
