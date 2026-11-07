import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/ecosystem_providers.dart';
import '../../models/scenario_model.dart';
import '../../models/recommendation_model.dart';
import '../../shared/widgets/error_display.dart';

class TimeMachinePage extends ConsumerStatefulWidget {
  final String areaId;

  const TimeMachinePage({super.key, required this.areaId});

  @override
  ConsumerState<TimeMachinePage> createState() => _TimeMachinePageState();
}

class _TimeMachinePageState extends ConsumerState<TimeMachinePage> {
  String _selectedMetric =
      'overall'; // 'overall', 'diversity', 'connectivity', 'pollinator', 'bird'
  final TextEditingController _budgetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Auto-calculate standard scenario if empty
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scenarioState = ref.read(scenarioNotifierProvider);
      if (scenarioState.result == null && !scenarioState.isLoading) {
        _initializeDefaultScenario();
      }
    });
  }

  @override
  void didUpdateWidget(covariant TimeMachinePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.areaId != widget.areaId) {
      _budgetController.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(scenarioNotifierProvider.notifier).reset();
        _initializeDefaultScenario();
      });
    }
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  void _initializeDefaultScenario() async {
    final recs = await ref.read(recommendationsProvider(widget.areaId).future);
    if (recs.recommendations.isNotEmpty) {
      final firstTwo = recs.recommendations
          .take(2)
          .map((r) => r.actionId)
          .toList();
      for (final id in firstTwo) {
        if (!ref
            .read(scenarioNotifierProvider)
            .selectedActionIds
            .contains(id)) {
          ref.read(scenarioNotifierProvider.notifier).toggleAction(id);
        }
      }
      ref
          .read(scenarioNotifierProvider.notifier)
          .calculateScenario(widget.areaId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scenarioState = ref.watch(scenarioNotifierProvider);
    final recommendationsAsync = ref.watch(
      recommendationsProvider(widget.areaId),
    );
    final isDesktop = MediaQuery.of(context).size.width >= 1000;
    final isMobile = MediaQuery.of(context).size.width < 650;

    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      body: recommendationsAsync.when(
        data: (recData) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 36 : (isMobile ? 16 : 24),
              vertical: 28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(recData.ecosystemName, isMobile),
                const SizedBox(height: 24),

                // Interactive Scenario Configuration Panel
                _buildConfigurationCard(
                  recData.recommendations,
                  scenarioState,
                  isDesktop,
                  isMobile,
                ),
                const SizedBox(height: 28),

                // Error / Loading indicator
                if (scenarioState.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.danger,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            scenarioState.errorMessage!,
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                if (scenarioState.isLoading) ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Projecting ecological recovery trajectories (2025–2045)...',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else if (scenarioState.result != null) ...[
                  // 2045 Net Improvement Delta Banner
                  _buildNetImprovementDeltas(
                    scenarioState.result!,
                    isDesktop,
                    isMobile,
                  ),
                  const SizedBox(height: 28),

                  // Trajectory Chart Card
                  _buildTrajectoryChartCard(
                    scenarioState.result!,
                    isDesktop,
                    isMobile,
                  ),
                  const SizedBox(height: 28),

                  // Multi-Horizon Comparison Table
                  _buildHorizonTableCard(scenarioState.result!, isMobile),
                  const SizedBox(height: 28),

                  // Scientific Model Limitations & Assumptions
                  _buildAssumptionsCard(scenarioState.result!),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorDisplay(
          title: 'Unable to Load Actions for Time Machine',
          message: err.toString(),
          onRetry: () => ref.refresh(recommendationsProvider(widget.areaId)),
        ),
      ),
    );
  }

  Widget _buildHeader(String ecosystemName, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'MULTI-HORIZON PROJECTION ENGINE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.emerald,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'SCENARIO • NOT A FORECAST',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.warning,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Restoration Time Machine: $ecosystemName',
          style: TextStyle(
            fontSize: isMobile ? 22 : 26,
            fontWeight: FontWeight.w800,
            color: AppColors.forestDeep,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Compare business-as-usual baseline degradation against active restoration interventions across 2030, 2040, and 2045.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildConfigurationCard(
    List<RestorationActionModel> availableActions,
    ScenarioState state,
    bool isDesktop,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.forestDark.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.forestDark,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Configure Intervention Strategy',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.forestDeep,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Select restoration actions to include in the simulation:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.forestDark,
            ),
          ),
          const SizedBox(height: 10),
          // Action chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableActions.map((action) {
              final isSelected = state.selectedActionIds.contains(
                action.actionId,
              );
              return FilterChip(
                label: Text(
                  '${action.name} (\$${(action.totalEstimatedBudgetUsd / 1000).toStringAsFixed(0)}k)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.forestDeep,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.forestDark,
                checkmarkColor: Colors.white,
                backgroundColor: AppColors.surfaceBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.forestDark
                        : AppColors.borderSubtle,
                  ),
                ),
                onSelected: (_) {
                  ref
                      .read(scenarioNotifierProvider.notifier)
                      .toggleAction(action.actionId);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Budget input & Run button
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 48,
                  child: TextField(
                    controller: _budgetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Investment Budget Cap (USD, Optional)',
                      hintText: 'e.g. 250000',
                      prefixIcon: const Icon(Icons.payments_rounded, size: 18),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.borderSubtle,
                        ),
                      ),
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      ref
                          .read(scenarioNotifierProvider.notifier)
                          .setBudget(parsed);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: state.isLoading || state.selectedActionIds.isEmpty
                      ? null
                      : () {
                          ref
                              .read(scenarioNotifierProvider.notifier)
                              .calculateScenario(widget.areaId);
                        },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    state.isLoading ? 'Calculating...' : 'Run Projection',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forestDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Investment Budget Cap (USD, Optional)',
                        hintText: 'e.g. 250000',
                        prefixIcon: const Icon(Icons.payments_rounded, size: 18),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppColors.borderSubtle,
                          ),
                        ),
                      ),
                      onChanged: (val) {
                        final parsed = double.tryParse(val);
                        ref
                            .read(scenarioNotifierProvider.notifier)
                            .setBudget(parsed);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                ElevatedButton.icon(
                  onPressed: state.isLoading || state.selectedActionIds.isEmpty
                      ? null
                      : () {
                          ref
                              .read(scenarioNotifierProvider.notifier)
                              .calculateScenario(widget.areaId);
                        },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    state.isLoading ? 'Calculating...' : 'Run Projection',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forestDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildNetImprovementDeltas(
    ScenarioResponseModel scenario,
    bool isDesktop,
    bool isMobile,
  ) {
    final overallDelta =
        scenario.netImprovement2045['overall_health_delta'] ?? 0.0;
    final plantDelta =
        scenario.netImprovement2045['plant_diversity_delta'] ?? 0.0;
    final connDelta =
        scenario.netImprovement2045['habitat_connectivity_delta'] ?? 0.0;
    final pollDelta =
        scenario.netImprovement2045['pollinator_network_delta'] ?? 0.0;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      decoration: BoxDecoration(
        color: AppColors.forestDark,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.forestDark.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              const Text(
                'Projected Net Gain by 2045 vs Baseline',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                'Total Strategy Budget: \$${(scenario.totalBudgetUsd / 1000).toStringAsFixed(0)}k USD',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.emeraldLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 16,
            runSpacing: 14,
            children: [
              _buildDeltaBadge('Overall Health', overallDelta),
              _buildDeltaBadge('Plant Diversity', plantDelta),
              _buildDeltaBadge('Habitat Connectivity', connDelta),
              _buildDeltaBadge('Pollinator Network', pollDelta),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeltaBadge(String label, double delta) {
    final isPos = delta >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${isPos ? "+" : ""}${delta.toStringAsFixed(1)} pts',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isPos ? AppColors.emeraldLight : AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrajectoryChartCard(
    ScenarioResponseModel scenario,
    bool isDesktop,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Multi-Horizon Trajectory (2025–2045)',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.forestDeep,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Solid Emerald: Restoration Intervention • Dashed Amber: Baseline Degradation',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButton<String>(
                  value: _selectedMetric,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                      value: 'overall',
                      child: Text('Overall Health'),
                    ),
                    DropdownMenuItem(
                      value: 'diversity',
                      child: Text('Plant Diversity'),
                    ),
                    DropdownMenuItem(
                      value: 'connectivity',
                      child: Text('Habitat Connectivity'),
                    ),
                    DropdownMenuItem(
                      value: 'pollinator',
                      child: Text('Pollinator Network'),
                    ),
                    DropdownMenuItem(
                      value: 'bird',
                      child: Text('Bird Network'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedMetric = val);
                  },
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Multi-Horizon Trajectory (2025–2045)',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.forestDeep,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Solid Emerald: Restoration Intervention • Dashed Amber: Baseline Degradation',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Metric switcher
                DropdownButton<String>(
                  value: _selectedMetric,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                      value: 'overall',
                      child: Text('Overall Health'),
                    ),
                    DropdownMenuItem(
                      value: 'diversity',
                      child: Text('Plant Diversity'),
                    ),
                    DropdownMenuItem(
                      value: 'connectivity',
                      child: Text('Habitat Connectivity'),
                    ),
                    DropdownMenuItem(
                      value: 'pollinator',
                      child: Text('Pollinator Network'),
                    ),
                    DropdownMenuItem(
                      value: 'bird',
                      child: Text('Bird Network'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedMetric = val);
                  },
                ),
              ],
            ),
          const SizedBox(height: 24),

          // Chart
          SizedBox(
            height: isMobile ? 260 : 320,
            child: LineChart(
              LineChartData(
                minX: 2025,
                maxX: 2045,
                minY: 0,
                maxY: 100,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: AppColors.borderSubtle,
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => const FlLine(
                    color: AppColors.borderSubtle,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.forestDark,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: 20,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                lineBarsData: [
                  // Baseline trajectory line (Amber dashed)
                  LineChartBarData(
                    spots: scenario.baselineTrajectory.projections.map((p) {
                      return FlSpot(p.year.toDouble(), _getMetricValue(p));
                    }).toList(),
                    isCurved: true,
                    color: AppColors.warning,
                    barWidth: 3,
                    dashArray: [6, 4],
                    dotData: const FlDotData(show: true),
                  ),
                  // Restoration trajectory line (Emerald solid)
                  LineChartBarData(
                    spots: scenario.restorationTrajectory.projections.map((p) {
                      return FlSpot(p.year.toDouble(), _getMetricValue(p));
                    }).toList(),
                    isCurved: true,
                    color: AppColors.emerald,
                    barWidth: 3.5,
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.emerald.withValues(alpha: 0.12),
                    ),
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getMetricValue(YearPointModel point) {
    switch (_selectedMetric) {
      case 'diversity':
        return point.plantDiversity;
      case 'connectivity':
        return point.habitatConnectivity;
      case 'pollinator':
        return point.pollinatorNetwork;
      case 'bird':
        return point.birdNetwork;
      default:
        return point.overallHealth;
    }
  }

  Widget _buildHorizonTableCard(ScenarioResponseModel scenario, bool isMobile) {
    final basePts = scenario.baselineTrajectory.projections;
    final restPts = scenario.restorationTrajectory.projections;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Temporal Milestone Matrix (Scores out of 100)',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.forestDeep,
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                AppColors.surfaceBackground,
              ),
              columns: const [
                DataColumn(
                  label: Text(
                    'Year',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Baseline (Degrading)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Restoration Plan',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Net Difference',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: List.generate(basePts.length, (i) {
                final b = basePts[i];
                final r = restPts[i];
                final diff = r.overallHealth - b.overallHealth;
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        b.year.toString(),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${b.overallHealth.toStringAsFixed(1)} / 100',
                        style: const TextStyle(color: AppColors.warning),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${r.overallHealth.toStringAsFixed(1)} / 100',
                        style: const TextStyle(
                          color: AppColors.emerald,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${diff >= 0 ? "+" : ""}${diff.toStringAsFixed(1)} pts',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: diff >= 0
                              ? AppColors.emerald
                              : AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssumptionsCard(ScenarioResponseModel scenario) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.forestDark.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.forestDark,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Simulation Modeling Assumptions & Ecological Lag Disclosures',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.forestDeep,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Projections represent deterministic multi-criteria scenarios based on observed biological recovery rates, structural lag, and diminishing marginal returns. They do not constitute deterministic or verified physical forecasts.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ...scenario.assumptionsAndLimitations.map((assump) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      color: AppColors.emerald,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      assump,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
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
}
