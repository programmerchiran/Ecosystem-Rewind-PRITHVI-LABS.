import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/ecosystem_providers.dart';
import '../../models/area_model.dart';
import '../../shared/widgets/error_display.dart';

class AreaSelectionPage extends ConsumerStatefulWidget {
  const AreaSelectionPage({super.key});

  @override
  ConsumerState<AreaSelectionPage> createState() => _AreaSelectionPageState();
}

class _AreaSelectionPageState extends ConsumerState<AreaSelectionPage> {
  final MapController _mapController = MapController();
  String _selectedId = 'western_ghats_forest';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final areasAsync = ref.watch(areasListProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 1000;

    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.public_rounded, color: AppColors.emerald),
            SizedBox(width: 10),
            Text(
              'Select Study Ecosystem',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: AppColors.borderSubtle, height: 1),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.home_rounded, size: 16),
            label: const Text('Back to Home'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: areasAsync.when(
        data: (areas) {
          final filteredAreas = areas.where((a) {
            final q = _searchQuery.toLowerCase();
            return a.name.toLowerCase().contains(q) ||
                a.ecosystemType.toLowerCase().contains(q);
          }).toList();

          final currentArea = areas.firstWhere(
            (a) => a.areaId == _selectedId,
            orElse: () => areas.first,
          );

          return isDesktop
              ? Row(
                  children: [
                    // Left Side: Area Directory & Inspection Panel
                    SizedBox(
                      width: 440,
                      child: _buildSidebarPanel(
                        context,
                        areas,
                        filteredAreas,
                        currentArea,
                      ),
                    ),
                    const VerticalDivider(
                      width: 1,
                      color: AppColors.borderSubtle,
                    ),
                    // Right Side: Interactive flutter_map
                    Expanded(child: _buildMap(currentArea, areas)),
                  ],
                )
              : Column(
                  children: [
                    Expanded(flex: 5, child: _buildMap(currentArea, areas)),
                    Expanded(
                      flex: 6,
                      child: _buildSidebarPanel(
                        context,
                        areas,
                        filteredAreas,
                        currentArea,
                      ),
                    ),
                  ],
                );
        },
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading ecosystem boundaries and spatial registers...'),
            ],
          ),
        ),
        error: (err, _) => ErrorDisplay(
          title: 'Failed to Load Study Areas',
          message: err.toString(),
          onRetry: () => ref.refresh(areasListProvider),
        ),
      ),
    );
  }

  Widget _buildMap(
    EcosystemAreaModel currentArea,
    List<EcosystemAreaModel> allAreas,
  ) {
    // Generate Polygon layers from GeoJSON
    final polygons = allAreas.map((area) {
      final isSelected = area.areaId == _selectedId;
      final coords =
          (area.boundaryGeojson['coordinates'] as List<dynamic>?)?[0]
              as List<dynamic>?;
      final points = <LatLng>[];
      if (coords != null) {
        for (var c in coords) {
          points.add(
            LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
          );
        }
      }

      return Polygon(
        points: points,
        color: isSelected
            ? AppColors.emerald.withValues(alpha: 0.35)
            : AppColors.forestMedium.withValues(alpha: 0.15),
        borderColor: isSelected ? AppColors.emerald : AppColors.forestDark,
        borderStrokeWidth: isSelected ? 3.0 : 1.5,
      );
    }).toList();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(
              currentArea.centerLatitude,
              currentArea.centerLongitude,
            ),
            initialZoom: 7.0,
            minZoom: 3.0,
            maxZoom: 16.0,
            onTap: (tapPosition, point) {
              // Check if tapped point is outside supported demo bounds
              _showArbitraryLocationNotice(context);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.prithvilabs.ecosystem_rewind',
            ),
            PolygonLayer(polygons: polygons),
            MarkerLayer(
              markers: allAreas.map((area) {
                final isSelected = area.areaId == _selectedId;
                return Marker(
                  point: LatLng(area.centerLatitude, area.centerLongitude),
                  width: 50,
                  height: 50,
                  child: GestureDetector(
                    onTap: () {
                      _selectArea(area);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.forestDark : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.emerald
                              : AppColors.forestMedium,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        area.areaId.contains('forest')
                            ? Icons.forest_rounded
                            : Icons.water_rounded,
                        color: isSelected
                            ? AppColors.emeraldLight
                            : AppColors.forestMedium,
                        size: 24,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        // Zoom & Map Controls
        Positioned(
          right: 20,
          bottom: 40,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'zoom_in',
                backgroundColor: Colors.white,
                foregroundColor: AppColors.forestDark,
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
                heroTag: 'zoom_out',
                backgroundColor: Colors.white,
                foregroundColor: AppColors.forestDark,
                onPressed: () {
                  _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom - 1,
                  );
                },
                child: const Icon(Icons.remove),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'recenter',
                backgroundColor: Colors.white,
                foregroundColor: AppColors.forestDark,
                onPressed: () {
                  _mapController.move(
                    LatLng(
                      currentArea.centerLatitude,
                      currentArea.centerLongitude,
                    ),
                    8.5,
                  );
                },
                child: const Icon(Icons.my_location),
              ),
            ],
          ),
        ),

        // Map Attribution
        Positioned(
          left: 12,
          bottom: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: const Text(
              '© OpenStreetMap contributors • PRITHVI LABS Spatial Boundary Demo',
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarPanel(
    BuildContext context,
    List<EcosystemAreaModel> allAreas,
    List<EcosystemAreaModel> filteredAreas,
    EcosystemAreaModel currentArea,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Input
          TextField(
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search study areas or ecosystem types...',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: AppColors.surfaceBackground,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Area Chips / Switcher
          const Text(
            'SUPPORTED STUDY AREAS (2 DEMO ECOSYSTEMS)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),

          // List of Supported Study Areas
          ...allAreas.map((area) {
            final isSelected = area.areaId == _selectedId;
            final isForest = area.areaId.contains('forest');

            return InkWell(
              onTap: () => _selectArea(area),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.emeraldSubtle.withValues(alpha: 0.4)
                      : AppColors.surfaceBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.emerald
                        : AppColors.borderSubtle,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isForest
                            ? AppColors.forestMedium.withValues(alpha: 0.12)
                            : AppColors.oceanBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isForest ? Icons.forest : Icons.water,
                        color: isForest
                            ? AppColors.forestMedium
                            : AppColors.oceanBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            area.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            area.ecosystemType,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.emerald,
                        size: 20,
                      ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 12),
          const Divider(color: AppColors.borderSubtle),
          const SizedBox(height: 12),

          // Selected Area Info Card
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.forestDark,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'DATA COVERAGE: COMPLETE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.emeraldLight,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'v${currentArea.datasetVersion}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentArea.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.forestDeep,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentArea.ecosystemType,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.forestMedium,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentArea.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow(
                    'Spatial Extent',
                    '${currentArea.areaSize.toStringAsFixed(0)} ${currentArea.areaSizeUnit}',
                  ),
                  _buildStatRow('Climate Zone', currentArea.climateZone),
                  _buildStatRow(
                    'Coordinates',
                    '${currentArea.centerLatitude.toStringAsFixed(2)}° N, ${currentArea.centerLongitude.toStringAsFixed(2)}° E',
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.warning,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            currentArea.vulnerabilityNotes,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textPrimary,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Primary Action: Analyze This Area
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ref.read(selectedAreaIdProvider.notifier).state = _selectedId;
                context.go('/workspace/$_selectedId/dashboard');
              },
              icon: const Icon(Icons.analytics_rounded),
              label: const Text('Analyze This Area'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectArea(EcosystemAreaModel area) {
    setState(() {
      _selectedId = area.areaId;
    });
    ref.read(selectedAreaIdProvider.notifier).state = area.areaId;
    _mapController.move(LatLng(area.centerLatitude, area.centerLongitude), 8.0);
  }

  void _showArbitraryLocationNotice(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Notice: The required ecological dataset is not available yet for this arbitrary location. Please choose one of the supported study areas.',
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.forestDark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: AppColors.emeraldLight,
          onPressed: () {},
        ),
      ),
    );
  }
}
