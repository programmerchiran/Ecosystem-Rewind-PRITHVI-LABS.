import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/ecosystem_providers.dart';
import '../../models/species_model.dart';
import '../../models/domino_model.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/error_display.dart';
import '../../shared/widgets/empty_state_view.dart';

class DominoSimulatorPage extends ConsumerStatefulWidget {
  final String areaId;

  const DominoSimulatorPage({super.key, required this.areaId});

  @override
  ConsumerState<DominoSimulatorPage> createState() =>
      _DominoSimulatorPageState();
}

class _DominoSimulatorPageState extends ConsumerState<DominoSimulatorPage> {
  String? _selectedSpeciesId;

  @override
  void didUpdateWidget(covariant DominoSimulatorPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.areaId != widget.areaId) {
      setState(() {
        _selectedSpeciesId = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(dominoNotifierProvider.notifier).reset();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final speciesAsync = ref.watch(speciesListProvider(widget.areaId));
    final dominoState = ref.watch(dominoNotifierProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 1000;

    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      body: speciesAsync.when(
        data: (speciesList) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 36 : 18,
              vertical: 28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header
                _buildHeader(context),
                const SizedBox(height: 24),

                // Species Selection & Action Bar
                _buildControlBar(context, speciesList, dominoState),
                const SizedBox(height: 28),

                // Simulation Results or Empty Prompt
                if (dominoState.isLoading) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Simulating removal and propagating trophic dependency shocks...',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else if (dominoState.errorMessage != null) ...[
                  ErrorDisplay(
                    title: 'Simulation Error',
                    message: dominoState.errorMessage!,
                    onRetry: () {
                      if (_selectedSpeciesId != null) {
                        ref
                            .read(dominoNotifierProvider.notifier)
                            .runSimulation(widget.areaId, _selectedSpeciesId!);
                      }
                    },
                  ),
                ] else if (dominoState.result != null) ...[
                  _buildSimulationResults(
                    context,
                    dominoState.result!,
                    isDesktop,
                  ),
                ] else ...[
                  EmptyStateView(
                    icon: Icons.scatter_plot_rounded,
                    title: 'Select a Keystone Species to Simulate Removal',
                    description: 'The Domino Simulator executes a real-time graph percolation analysis using NetworkX on an independent deepcopy of the ecosystem. Witness how the loss of pollinators or keystone mast trees ripples through the food web.',
                    actionLabel: 'Quick Select Keystone Tree',
                    onAction: () {
                      final keystone = speciesList.firstWhere(
                        (s) => s.observationStatus.toLowerCase() == 'keystone',
                        orElse: () => speciesList.first,
                      );
                      setState(() {
                        _selectedSpeciesId = keystone.speciesId;
                      });
                      ref
                          .read(dominoNotifierProvider.notifier)
                          .runSimulation(widget.areaId, keystone.speciesId);
                    },
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorDisplay(
          title: 'Unable to Load Species Catalog',
          message: err.toString(),
          onRetry: () => ref.refresh(speciesListProvider(widget.areaId)),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ecological Domino Simulator',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.forestDeep,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'NetworkX-backed dependency cascade analysis & extinction percolation modeling',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildControlBar(
    BuildContext context,
    List<SpeciesModel> speciesList,
    DominoState state,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              key: ValueKey(_selectedSpeciesId),
              initialValue: _selectedSpeciesId,
              isExpanded: true,
              hint: const Text('Choose a species or component to remove...'),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                filled: true,
                fillColor: AppColors.surfaceBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
              ),
              items: speciesList.map((sp) {
                return DropdownMenuItem<String>(
                  value: sp.speciesId,
                  child: Row(
                    children: [
                      Text(
                        sp.commonName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${sp.scientificName})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const Spacer(),
                      StatusBadge(label: sp.observationStatus),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedSpeciesId = val;
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _selectedSpeciesId != null
                ? () {
                    ref
                        .read(dominoNotifierProvider.notifier)
                        .runSimulation(widget.areaId, _selectedSpeciesId!);
                  }
                : null,
            icon: const Icon(Icons.flash_on_rounded, size: 18),
            label: const Text('Simulate Removal'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            ),
          ),
          if (state.result != null) ...[
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedSpeciesId = null;
                });
                ref.read(dominoNotifierProvider.notifier).reset();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reset'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSimulationResults(
    BuildContext context,
    DominoSimulationResultModel result,
    bool isDesktop,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Shock Score Hero Card
        _buildShockHero(result),
        const SizedBox(height: 24),

        // 2. Metrics Comparison (Before vs After)
        _buildMetricsComparisonGrid(result, isDesktop),
        const SizedBox(height: 24),

        // 3. Trophic Cascades & Affected Species List
        _buildAffectedSpeciesCard(result),
        const SizedBox(height: 24),

        // 4. Documented Assumptions & Transparent Rules
        _buildRulesCard(result),
      ],
    );
  }

  Widget _buildShockHero(DominoSimulationResultModel result) {
    final score = result.dominoImpactScore;
    final color = score >= 70
        ? AppColors.danger
        : (score >= 40 ? AppColors.warning : AppColors.emerald);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
              border: Border.all(color: color, width: 3),
            ),
            child: Center(
              child: Text(
                score.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
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
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'DOMINO IMPACT SHOCK',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: color,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Removed: ${result.removedSpecies.commonName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  result.explanation,
                  style: const TextStyle(
                    color: AppColors.sageLight,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsComparisonGrid(
    DominoSimulationResultModel result,
    bool isDesktop,
  ) {
    final before = result.beforeMetrics;
    final after = result.afterMetrics;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Structural Network Degradation (Master Baseline vs. Simulated Copy)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildDiffColumn(
                'Active Species',
                '${before.totalNodes}',
                '${after.totalNodes}',
                '-1',
              ),
              const VerticalDivider(width: 24),
              _buildDiffColumn(
                'Ecological Edges',
                '${before.totalEdges}',
                '${after.totalEdges}',
                '-${result.directRelationshipsRemoved}',
              ),
              const VerticalDivider(width: 24),
              _buildDiffColumn(
                'Graph Density',
                '${before.graphDensity}',
                '${after.graphDensity}',
                '',
              ),
              const VerticalDivider(width: 24),
              _buildDiffColumn(
                'Connected Comp.',
                '${before.connectedComponents}',
                '${after.connectedComponents}',
                '',
              ),
              const VerticalDivider(width: 24),
              _buildDiffColumn(
                'Isolated Taxa',
                '0',
                '${result.isolatedSpecies.length}',
                result.isolatedSpecies.isNotEmpty
                    ? '+${result.isolatedSpecies.length}'
                    : '0',
                isWarning: result.isolatedSpecies.isNotEmpty,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiffColumn(
    String label,
    String beforeVal,
    String afterVal,
    String delta, {
    bool isWarning = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isWarning
              ? AppColors.danger.withValues(alpha: 0.08)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  beforeVal,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textMuted,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  afterVal,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isWarning ? AppColors.danger : AppColors.forestDark,
                  ),
                ),
              ],
            ),
            if (delta.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Delta: $delta',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isWarning ? AppColors.danger : AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAffectedSpeciesCard(DominoSimulationResultModel result) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Directly Impacted & Dependent Species (${result.potentiallyAffectedSpecies.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (result.isolatedSpecies.isNotEmpty)
                StatusBadge(
                  label: 'Isolated: ${result.isolatedSpecies.join(", ")}',
                  color: AppColors.danger,
                ),
            ],
          ),
          const SizedBox(height: 16),
          ...result.potentiallyAffectedSpecies.map((aff) {
            Color levelColor = AppColors.sage;
            if (aff.impactLevel == 'Critical') levelColor = AppColors.danger;
            if (aff.impactLevel == 'High') levelColor = AppColors.warning;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: levelColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: levelColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: levelColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      aff.impactLevel.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${aff.commonName} (${aff.scientificName}) - ${aff.group}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          aff.impactRationale,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRulesCard(DominoSimulationResultModel result) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.rule_rounded, color: AppColors.forestMedium, size: 20),
              SizedBox(width: 8),
              Text(
                'Documented Dependency Rules Applied in Simulation',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...result.appliedRulesAndAssumptions.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 14,
                    color: AppColors.emerald,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
