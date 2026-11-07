import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/network_model.dart';
import '../../shared/widgets/status_badge.dart';

class SpeciesDetailsSheet extends StatelessWidget {
  final NetworkNodeModel node;
  final List<NetworkEdgeModel> incidentEdges;
  final Map<String, NetworkNodeModel> allNodesMap;
  final VoidCallback onClose;
  final Function(String targetId)? onSelectNeighbor;

  const SpeciesDetailsSheet({
    super.key,
    required this.node,
    required this.incidentEdges,
    required this.allNodesMap,
    required this.onClose,
    this.onSelectNeighbor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusBadge(label: node.status),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            node.label,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.forestDeep,
            ),
          ),
          Text(
            node.scientificName,
            style: const TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Taxa: ${node.group}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  node.trophicLevel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            node.description,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.borderSubtle),
          const SizedBox(height: 12),
          const Text(
            'Centrality & Network Metrics',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildMetricChip('Total Degree', node.degree.toString()),
              const SizedBox(width: 8),
              _buildMetricChip('PageRank', node.pagerank.toStringAsFixed(3)),
              const SizedBox(width: 8),
              _buildMetricChip(
                'Betweenness',
                node.betweenness.toStringAsFixed(3),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.borderSubtle),
          const SizedBox(height: 12),
          Text(
            'Known Ecological Relationships (${incidentEdges.length})',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: incidentEdges.length,
              separatorBuilder: (context, index) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final edge = incidentEdges[index];
                final isSource = edge.source == node.id;
                final partnerId = isSource ? edge.target : edge.source;
                final partnerNode = allNodesMap[partnerId];

                return InkWell(
                  onTap: () {
                    if (onSelectNeighbor != null) {
                      onSelectNeighbor!(partnerId);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getInteractionIcon(edge.interactionType),
                          size: 16,
                          color: AppColors.forestMedium,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                partnerNode?.label ?? partnerId,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${edge.interactionType.toUpperCase()} • Weight: ${edge.dependencyWeight}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.forestDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getInteractionIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pollination':
        return Icons.local_florist_rounded;
      case 'seed_dispersal':
        return Icons.grain_rounded;
      case 'food_web':
        return Icons.restaurant_rounded;
      case 'habitat_dependency':
        return Icons.holiday_village_rounded;
      default:
        return Icons.sync_alt_rounded;
    }
  }
}
