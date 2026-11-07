import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/ecosystem_providers.dart';
import '../../models/network_model.dart';
import '../../shared/widgets/error_display.dart';
import 'species_network_canvas.dart';
import 'species_details_sheet.dart';

class EcosystemNetworkPage extends ConsumerStatefulWidget {
  final String areaId;

  const EcosystemNetworkPage({super.key, required this.areaId});

  @override
  ConsumerState<EcosystemNetworkPage> createState() =>
      _EcosystemNetworkPageState();
}

class _EcosystemNetworkPageState extends ConsumerState<EcosystemNetworkPage> {
  String _selectedGroup = 'All';
  String _searchQuery = '';
  NetworkNodeModel? _selectedNode;

  @override
  Widget build(BuildContext context) {
    final networkAsync = ref.watch(networkGraphProvider(widget.areaId));

    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      body: networkAsync.when(
        data: (graph) {
          final allNodesMap = {for (var n in graph.nodes) n.id: n};

          List<NetworkEdgeModel> incidentEdges = [];
          if (_selectedNode != null) {
            incidentEdges = graph.edges
                .where(
                  (e) =>
                      e.source == _selectedNode!.id ||
                      e.target == _selectedNode!.id,
                )
                .toList();
          }

          final allGroups = ['All', ...graph.groups];

          return Stack(
            children: [
              // 1. Full Canvas Viewport
              Positioned.fill(
                child: SpeciesNetworkCanvas(
                  graph: graph,
                  selectedNodeId: _selectedNode?.id,
                  filterGroup: _selectedGroup,
                  searchQuery: _searchQuery,
                  onNodeSelected: (node) {
                    setState(() {
                      _selectedNode = node;
                    });
                  },
                ),
              ),

              // 2. Top Control Toolbar (Search, Filter, Metrics Bar)
              Positioned(
                top: 20,
                left: 20,
                right: _selectedNode != null ? 390 : 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSubtle),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              onChanged: (val) {
                                setState(() {
                                  _searchQuery = val;
                                });
                              },
                              decoration: const InputDecoration(
                                hintText: 'Search species or component...',
                                prefixIcon: Icon(Icons.search, size: 18),
                                isDense: true,
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          const VerticalDivider(width: 24),
                          // Metrics Summary Chips
                          _buildMetricSummaryPill(
                            'Nodes',
                            graph.metrics.totalNodes.toString(),
                          ),
                          const SizedBox(width: 8),
                          _buildMetricSummaryPill(
                            'Interactions',
                            graph.metrics.totalEdges.toString(),
                          ),
                          const SizedBox(width: 8),
                          _buildMetricSummaryPill(
                            'Density',
                            graph.metrics.graphDensity.toStringAsFixed(2),
                          ),
                          const SizedBox(width: 8),
                          _buildMetricSummaryPill(
                            'Clustering',
                            graph.metrics.averageClustering.toStringAsFixed(2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Group Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: allGroups.map((g) {
                          final isSelected = _selectedGroup == g;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(g),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() {
                                  _selectedGroup = g;
                                });
                              },
                              selectedColor: AppColors.emeraldSubtle,
                              checkmarkColor: AppColors.forestDark,
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.forestDark
                                    : AppColors.textSecondary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Bottom Legend Overlay
              Positioned(
                left: 20,
                bottom: 80,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'INTERACTION LEGEND',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildLegendDot(
                            const Color(0xFFF59E0B),
                            'Pollination',
                          ),
                          const SizedBox(width: 10),
                          _buildLegendDot(
                            const Color(0xFF10B981),
                            'Seed Dispersal',
                          ),
                          const SizedBox(width: 10),
                          _buildLegendDot(const Color(0xFFEF4444), 'Food Web'),
                          const SizedBox(width: 10),
                          _buildLegendDot(
                            const Color(0xFF3B82F6),
                            'Habitat Dependency',
                          ),
                          const SizedBox(width: 10),
                          _buildLegendDot(const Color(0xFF8B5CF6), 'Symbiosis'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Slide-in Details Sheet when Node is selected
              if (_selectedNode != null)
                Positioned(
                  top: 20,
                  right: 20,
                  bottom: 20,
                  child: SpeciesDetailsSheet(
                    node: _selectedNode!,
                    incidentEdges: incidentEdges,
                    allNodesMap: allNodesMap,
                    onClose: () {
                      setState(() {
                        _selectedNode = null;
                      });
                    },
                    onSelectNeighbor: (partnerId) {
                      final n = allNodesMap[partnerId];
                      if (n != null) {
                        setState(() {
                          _selectedNode = n;
                        });
                      }
                    },
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
              Text(
                'Building species interaction network from graph database...',
              ),
            ],
          ),
        ),
        error: (err, _) => ErrorDisplay(
          title: 'Network Graph Unavailable',
          message: err.toString(),
          onRetry: () => ref.refresh(networkGraphProvider(widget.areaId)),
        ),
      ),
    );
  }

  Widget _buildMetricSummaryPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.forestDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
