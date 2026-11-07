
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_colors.dart';
import '../../models/habitat_model.dart';
import '../../providers/ecosystem_providers.dart';

class HabitatMapWidget extends ConsumerStatefulWidget {
  const HabitatMapWidget({super.key});

  @override
  ConsumerState<HabitatMapWidget> createState() =>
      _HabitatMapWidgetState();
}

class _HabitatMapWidgetState extends ConsumerState<HabitatMapWidget> {
  final MapController _mapController = MapController();

  HabitatMapBounds _bounds = const HabitatMapBounds(
    minLat: 5,
    maxLat: 38,
    minLon: 67,
    maxLon: 99,
  );

  HabitatCellModel? _selectedCell;
  bool _mapReady = false;

  Color _classColor(String suitabilityClass) {
    switch (suitabilityClass.toLowerCase()) {
      case 'very low':
        return const Color(0xFFB8C4C0);
      case 'low':
        return const Color(0xFFF2D35E);
      case 'moderate':
        return const Color(0xFFF59E42);
      case 'high':
        return const Color(0xFF43A66B);
      case 'very high':
        return const Color(0xFF12643D);
      default:
        return Colors.grey;
    }
  }

  void _updateBounds(MapCamera camera) {
    final bounds = camera.visibleBounds;

    final nextBounds = HabitatMapBounds(
      minLat: bounds.south,
      maxLat: bounds.north,
      minLon: bounds.west,
      maxLon: bounds.east,
    );

    if (nextBounds.minLat == _bounds.minLat &&
        nextBounds.maxLat == _bounds.maxLat &&
        nextBounds.minLon == _bounds.minLon &&
        nextBounds.maxLon == _bounds.maxLon) {
      return;
    }

    setState(() {
      _bounds = nextBounds;
      _selectedCell = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cellsAsync = ref.watch(habitatMapCellsProvider(_bounds));

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.borderDark),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'India-wide Teak Suitability Map',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Explore predicted suitability across mapped forest cells.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 480,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: const LatLng(22.5, 82.0),
                        initialZoom: 4.5,
                        minZoom: 3,
                        maxZoom: 15,
                        onMapReady: () {
                          _mapReady = true;
                          _updateBounds(_mapController.camera);
                        },
                        onPositionChanged: (camera, hasGesture) {
                          if (hasGesture && _mapReady) {
                            _updateBounds(camera);
                          }
                        },
                        onTap: (tapPosition, point) {
                          final cells = cellsAsync.asData?.value ?? <HabitatCellModel>[];

                          HabitatCellModel? nearest;
                          double nearestDistance = double.infinity;

                          for (final cell in cells) {
                            final distance = Distance().as(
                              LengthUnit.Meter,
                              point,
                              LatLng(cell.latitude, cell.longitude),
                            );

                            if (distance < nearestDistance) {
                              nearestDistance = distance;
                              nearest = cell;
                            }
                          }

                          if (nearest != null &&
                              nearestDistance <= 4000) {
                            setState(() {
                              _selectedCell = nearest;
                            });
                          } else {
                            setState(() {
                              _selectedCell = null;
                            });
                          }
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName:
                              'com.prithvilabs.ecosystem_rewind',
                        ),

                        CircleLayer<Object>(
                           circles: cellsAsync.asData?.value
                                     .map<CircleMarker<Object>>((cell) {
                                   return CircleMarker<Object>(
                                     point: LatLng(cell.latitude, cell.longitude),
                                     radius: 2500,
                                     useRadiusInMeter: true,
                                     color: _classColor(cell.suitabilityClass)
                                         .withValues(alpha: 0.78),
                                     borderColor: _classColor(cell.suitabilityClass),
                                     borderStrokeWidth: 0.5,
                                   );
                                 }).toList() ??
                                 <CircleMarker<Object>>[],
                        ),
                        if (_selectedCell != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(
                                  _selectedCell!.latitude,
                                  _selectedCell!.longitude,
                                ),
                                width: 24,
                                height: 24,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.black,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Column(
                        children: [
                          FloatingActionButton.small(
                            heroTag: 'habitat_zoom_in',
                            onPressed: () {
                              _mapController.move(
                                _mapController.camera.center,
                                _mapController.camera.zoom + 1,
                              );
                            },
                            child: const Icon(Icons.add),
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton.small(
                            heroTag: 'habitat_zoom_out',
                            onPressed: () {
                              _mapController.move(
                                _mapController.camera.center,
                                _mapController.camera.zoom - 1,
                              );
                            },
                            child: const Icon(Icons.remove),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: cellsAsync.when(
                            data: (cells) => Text(
                              '${cells.length} cells loaded',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            loading: () => const Text(
                              'Loading cells...',
                              style: TextStyle(fontSize: 11),
                            ),
                            error: (_, _) => const Text(
                              'Unable to load cells',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (cellsAsync.isLoading)
                      const Positioned(
                        bottom: 12,
                        left: 12,
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Loading habitat predictions...',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (cellsAsync.hasError)
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text(
                              'Map data error: ${cellsAsync.error}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _legendItem('Very Low', _classColor('Very Low')),
                _legendItem('Low', _classColor('Low')),
                _legendItem('Moderate', _classColor('Moderate')),
                _legendItem('High', _classColor('High')),
                _legendItem('Very High', _classColor('Very High')),
              ],
            ),
            if (_selectedCell != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected habitat cell',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Class: ${_selectedCell!.suitabilityClass}',
                    ),
                    Text(
                      'Suitability index: ${_selectedCell!.index.toStringAsFixed(1)} / 100',
                    ),
                    Text(
                      'Model score: ${_selectedCell!.score.toStringAsFixed(3)}',
                    ),
                    Text(
                      'Coordinates: ${_selectedCell!.latitude.toStringAsFixed(4)}, '
                      '${_selectedCell!.longitude.toStringAsFixed(4)}',
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }
}
