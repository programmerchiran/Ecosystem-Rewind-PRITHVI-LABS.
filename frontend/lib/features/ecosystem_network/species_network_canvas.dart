import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/network_model.dart';

class SpeciesNetworkCanvas extends StatefulWidget {
  final NetworkGraphModel graph;
  final String? selectedNodeId;
  final String? filterGroup;
  final String searchQuery;
  final Function(NetworkNodeModel node) onNodeSelected;

  const SpeciesNetworkCanvas({
    super.key,
    required this.graph,
    this.selectedNodeId,
    this.filterGroup,
    this.searchQuery = '',
    required this.onNodeSelected,
  });

  @override
  State<SpeciesNetworkCanvas> createState() => _SpeciesNetworkCanvasState();
}

class _SpeciesNetworkCanvasState extends State<SpeciesNetworkCanvas> {
  final TransformationController _transformController =
      TransformationController();
  final Map<String, Offset> _nodePositions = {};
  final double canvasWidth = 1400;
  final double canvasHeight = 900;
  String? _draggedNodeId;

  @override
  void initState() {
    super.initState();
    _layoutNodes();
  }

  @override
  void didUpdateWidget(covariant SpeciesNetworkCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.graph.areaId != widget.graph.areaId ||
        oldWidget.graph.nodes.length != widget.graph.nodes.length) {
      _layoutNodes();
    }
  }

  void _layoutNodes() {
    _nodePositions.clear();
    final nodes = widget.graph.nodes;
    if (nodes.isEmpty) return;

    final center = Offset(canvasWidth / 2, canvasHeight / 2);
    final count = nodes.length;

    // Organic circular radial layout grouped by trophic level / species group
    for (int i = 0; i < count; i++) {
      final node = nodes[i];
      // Trophic radii: producers inner ring, consumers outer ring
      double radius;
      if (node.isKeystone) {
        radius = 160 + (i % 2) * 50;
      } else if (node.trophicLevel.contains('Producer')) {
        radius = 240;
      } else if (node.group == 'Pollinators') {
        radius = 320;
      } else {
        radius = 390;
      }

      final angle = (i * 2 * pi / count) - (pi / 2);
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      _nodePositions[node.id] = Offset(x, y);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InteractiveViewer(
          transformationController: _transformController,
          boundaryMargin: const EdgeInsets.all(500),
          minScale: 0.3,
          maxScale: 3.0,
          constrained: false,
          child: GestureDetector(
            onPanStart: (details) {
              final local = details.localPosition;
              for (final entry in _nodePositions.entries) {
                if ((entry.value - local).distance <= 30) {
                  setState(() {
                    _draggedNodeId = entry.key;
                  });
                  break;
                }
              }
            },
            onPanUpdate: (details) {
              if (_draggedNodeId != null) {
                setState(() {
                  _nodePositions[_draggedNodeId!] = details.localPosition;
                });
              }
            },
            onPanEnd: (_) {
              setState(() {
                _draggedNodeId = null;
              });
            },
            onTapUp: (details) {
              final local = details.localPosition;
              for (final node in widget.graph.nodes) {
                final pos = _nodePositions[node.id];
                if (pos != null && (pos - local).distance <= 30) {
                  widget.onNodeSelected(node);
                  return;
                }
              }
            },
            child: CustomPaint(
              size: Size(canvasWidth, canvasHeight),
              painter: _NetworkPainter(
                graph: widget.graph,
                nodePositions: _nodePositions,
                selectedNodeId: widget.selectedNodeId,
                filterGroup: widget.filterGroup,
                searchQuery: widget.searchQuery,
              ),
            ),
          ),
        ),

        // Floating Canvas Zoom & Reset Controls
        Positioned(
          left: 20,
          bottom: 20,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Zoom In',
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () {
                    final matrix = _transformController.value.clone();
                    // Uniform 2D zoom: scale X and Y equally, leave Z and W unchanged.
                    matrix.scaleByDouble(1.2, 1.2, 1.0, 1.0);
                    _transformController.value = matrix;
                  },
                ),
                IconButton(
                  tooltip: 'Zoom Out',
                  icon: const Icon(Icons.remove, size: 20),
                  onPressed: () {
                    final matrix = _transformController.value.clone();
                    // Uniform 2D zoom: scale X and Y equally, leave Z and W unchanged.
                    matrix.scaleByDouble(0.8, 0.8, 1.0, 1.0);
                    _transformController.value = matrix;
                  },
                ),
                IconButton(
                  tooltip: 'Reset Layout',
                  icon: const Icon(Icons.center_focus_strong, size: 20),
                  onPressed: () {
                    _layoutNodes();
                    _transformController.value = Matrix4.identity();
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NetworkPainter extends CustomPainter {
  final NetworkGraphModel graph;
  final Map<String, Offset> nodePositions;
  final String? selectedNodeId;
  final String? filterGroup;
  final String searchQuery;

  _NetworkPainter({
    required this.graph,
    required this.nodePositions,
    this.selectedNodeId,
    this.filterGroup,
    required this.searchQuery,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw subtle grid background
    final gridPaint = Paint()
      ..color = AppColors.borderSubtle.withValues(alpha: 0.4)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 60) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 60) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Set of directly connected neighbor node IDs if a node is selected
    final connectedNodeIds = <String>{};
    if (selectedNodeId != null) {
      connectedNodeIds.add(selectedNodeId!);
      for (final edge in graph.edges) {
        if (edge.source == selectedNodeId) {
          connectedNodeIds.add(edge.target);
        } else if (edge.target == selectedNodeId) {
          connectedNodeIds.add(edge.source);
        }
      }
    }

    // 2. Draw Edges
    for (final edge in graph.edges) {
      final p1 = nodePositions[edge.source];
      final p2 = nodePositions[edge.target];
      if (p1 == null || p2 == null) continue;

      final isIncident =
          selectedNodeId != null &&
          (edge.source == selectedNodeId || edge.target == selectedNodeId);

      final isDimmed = selectedNodeId != null && !isIncident;

      final edgeColor = _getEdgeColor(edge.interactionType);
      final edgePaint = Paint()
        ..color = isIncident
            ? edgeColor.withValues(alpha: 0.9)
            : (isDimmed
                  ? AppColors.borderSubtle.withValues(alpha: 0.2)
                  : edgeColor.withValues(alpha: 0.45))
        ..strokeWidth = isIncident ? 2.8 : (edge.strength * 1.8).clamp(1.0, 3.0)
        ..style = PaintingStyle.stroke;

      // Draw quadratic bezier curved connection
      final midPoint = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      final normal = Offset(-(p2.dy - p1.dy), p2.dx - p1.dx);
      final normalLen = normal.distance;
      final offsetDist = normalLen > 0 ? (edge.strength * 25) / normalLen : 0;
      final controlPoint = Offset(
        midPoint.dx + normal.dx * offsetDist * 0.15,
        midPoint.dy + normal.dy * offsetDist * 0.15,
      );

      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..quadraticBezierTo(controlPoint.dx, controlPoint.dy, p2.dx, p2.dy);

      canvas.drawPath(path, edgePaint);
    }

    // 3. Draw Nodes
    for (final node in graph.nodes) {
      final pos = nodePositions[node.id];
      if (pos == null) continue;

      final isSelected = node.id == selectedNodeId;
      final isConnected =
          connectedNodeIds.isEmpty || connectedNodeIds.contains(node.id);

      final matchesSearch =
          searchQuery.isEmpty ||
          node.label.toLowerCase().contains(searchQuery.toLowerCase()) ||
          node.scientificName.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesGroup =
          filterGroup == null ||
          filterGroup == 'All' ||
          node.group.toLowerCase() == filterGroup!.toLowerCase();

      final isHighlighted = isConnected && matchesSearch && matchesGroup;
      final isDimmed = !isHighlighted;

      final baseColor = _getNodeColor(node.group);
      final radius = node.isKeystone
          ? 24.0
          : 18.0 + (node.degree * 0.8).clamp(0, 10);

      // Node shadow
      if (!isDimmed) {
        canvas.drawCircle(
          pos.translate(0, 4),
          radius,
          Paint()
            ..color = Colors.black.withValues(alpha: 0.12)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }

      // Outer halo for selected or keystone node
      if (isSelected) {
        canvas.drawCircle(
          pos,
          radius + 8,
          Paint()
            ..color = AppColors.emerald.withValues(alpha: 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      } else if (node.isKeystone && !isDimmed) {
        canvas.drawCircle(
          pos,
          radius + 4,
          Paint()
            ..color = AppColors.warning.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }

      // Main Node Circle
      final nodePaint = Paint()
        ..color = isDimmed ? AppColors.borderSubtle.withValues(alpha: 0.4) : baseColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, radius, nodePaint);

      // Node Inner Border
      final borderPaint = Paint()
        ..color = isSelected ? Colors.white : Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3.0 : 1.8;
      canvas.drawCircle(pos, radius, borderPaint);

      // Node Label Text
      final textSpan = TextSpan(
        text: node.label,
        style: TextStyle(
          color: isDimmed ? AppColors.textMuted : AppColors.textPrimary,
          fontSize: isSelected ? 13 : 11,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          backgroundColor: Colors.white.withValues(alpha: 0.75),
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(pos.dx - (textPainter.width / 2), pos.dy + radius + 4),
      );
    }
  }

  Color _getNodeColor(String group) {
    switch (group.toLowerCase()) {
      case 'plants':
        return AppColors.emerald;
      case 'pollinators':
        return const Color(0xFFF59E0B);
      case 'birds':
        return const Color(0xFF3B82F6);
      case 'mammals':
        return const Color(0xFF1E293B);
      case 'aquatic':
        return const Color(0xFF06B6D4);
      case 'invertebrates':
        return const Color(0xFF8B5CF6);
      case 'decomposers':
        return const Color(0xFF854D0E);
      default:
        return AppColors.forestMedium;
    }
  }

  Color _getEdgeColor(String type) {
    switch (type.toLowerCase()) {
      case 'pollination':
        return const Color(0xFFF59E0B);
      case 'seed_dispersal':
        return const Color(0xFF10B981);
      case 'food_web':
        return const Color(0xFFEF4444);
      case 'habitat_dependency':
        return const Color(0xFF3B82F6);
      case 'symbiosis':
        return const Color(0xFF8B5CF6);
      default:
        return AppColors.sage;
    }
  }

  @override
  bool shouldRepaint(covariant _NetworkPainter oldDelegate) {
    return true;
  }
}
