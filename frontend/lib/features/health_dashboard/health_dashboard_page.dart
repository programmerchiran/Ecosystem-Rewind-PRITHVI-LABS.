import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/ecosystem_providers.dart';
import '../../models/indicator_model.dart';
import '../../shared/widgets/kpi_card.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/error_display.dart';

class HealthDashboardPage extends ConsumerWidget {
  final String areaId;

  const HealthDashboardPage({super.key, required this.areaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(healthSummaryProvider(areaId));
    final isDesktop = MediaQuery.of(context).size.width >= 1000;

    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      body: summaryAsync.when(
        data: (summary) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 36 : 18,
              vertical: 28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Page Title & Ecosystem Status Bar
                _buildHeader(context, summary, isDesktop),
                const SizedBox(height: 28),

                // Composite Score Hero Banner
                _buildOverallScoreHero(context, summary, isDesktop),
                const SizedBox(height: 28),

                // Indicator Cards Grid (5 Dimensions)
                _buildIndicatorCardsGrid(context, summary, isDesktop),
                const SizedBox(height: 28),

                // Multi-Indicator Visual Breakdown Chart (fl_chart)
                _buildVisualChartCard(context, summary, isDesktop),
                const SizedBox(height: 28),

                // Scientific Limitations & Lineage Notice
                _buildDataLineageCard(summary),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Calculating ecosystem health indices...'),
            ],
          ),
        ),
        error: (err, _) => ErrorDisplay(
          title: 'Unable to Load Health Dashboard',
          message: err.toString(),
          onRetry: () => ref.refresh(healthSummaryProvider(areaId)),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AreaSummaryModel summary,
    bool isDesktop,
  ) {
    if (!isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                summary.areaName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.forestDeep,
                ),
              ),
              StatusBadge(label: summary.healthStatus),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${summary.ecosystemType} • Data Coverage: ${summary.dataCoverage}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => context.go('/workspace/$areaId/network'),
            icon: const Icon(Icons.hub_rounded, size: 16),
            label: const Text('Explore Network'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forestDark,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    summary.areaName,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.forestDeep,
                    ),
                  ),
                  StatusBadge(label: summary.healthStatus),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${summary.ecosystemType} • Data Coverage: ${summary.dataCoverage}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () => context.go('/workspace/$areaId/network'),
          icon: const Icon(Icons.hub_rounded, size: 16),
          label: const Text('Explore Network'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.forestDark,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildOverallScoreHero(
    BuildContext context,
    AreaSummaryModel summary,
    bool isDesktop,
  ) {
    final score = summary.overallHealthScore;
    final scoreColor = score >= 75
        ? AppColors.emerald
        : (score >= 50 ? AppColors.warning : AppColors.danger);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.forestDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: isDesktop
          ? Row(
              children: [
                _buildScoreDial(score, scoreColor),
                const SizedBox(width: 32),
                Expanded(child: _buildScoreDetails(summary)),
              ],
            )
          : Column(
              children: [
                _buildScoreDial(score, scoreColor),
                const SizedBox(height: 20),
                _buildScoreDetails(summary),
              ],
            ),
    );
  }

  Widget _buildScoreDial(double score, Color color) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.cardDark,
        border: Border.all(color: color.withValues(alpha: 0.5), width: 6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            score.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const Text(
            'HEALTH INDEX',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: AppColors.sageLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDetails(AreaSummaryModel summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'PROJECT-DEFINED COMPOSITE INDICATOR',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.emeraldLight,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const Text(
              'Observation Period: 2023-2025',
              style: TextStyle(color: AppColors.sageLight, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Integrated Ecosystem Integrity Assessment',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          summary.scoreCalculationFormula,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.sageLight,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Notice: This composite score is a modeled evaluation benchmark synthesizing normalized biodiversity, structural connectivity, and trophic interaction robustness; it is not a universally standardized scientific constant.',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.sage,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildIndicatorCardsGrid(
    BuildContext context,
    AreaSummaryModel summary,
    bool isDesktop,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1100
            ? 3
            : (constraints.maxWidth > 700 ? 2 : 1);
        final width =
            (constraints.maxWidth - ((crossAxisCount - 1) * 20)) /
            crossAxisCount;

        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: summary.indicators.map((ind) {
            final icon = _getIndicatorIcon(ind.name);
            return SizedBox(
              width: width,
              child: KpiCard(
                title: ind.name,
                score: ind.value,
                targetScore: ind.targetValue,
                subtitle: ind.interpretation,
                icon: icon,
                category: ind.category,
                onTap: () {
                  // Navigate to species network filtered by related group
                  final group = _inferGroupFromIndicator(ind.name);
                  context.go('/workspace/$areaId/network?group=$group');
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildVisualChartCard(
    BuildContext context,
    AreaSummaryModel summary,
    bool isDesktop,
  ) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isDesktop) ...[
            const Text(
              'Indicator Comparison & Targets',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Observed baseline score vs. ecological target threshold (0-100)',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: 16,
                    color: AppColors.forestMedium,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Normalized Index',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ] else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Indicator Comparison & Targets',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Observed baseline score vs. ecological target threshold (0-100)',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bar_chart,
                        size: 16,
                        color: AppColors.forestMedium,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Normalized Index',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(height: 32),
          SizedBox(
            height: 240,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.forestDark,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final ind = summary.indicators[groupIndex];
                      return BarTooltipItem(
                        '${ind.name}\nScore: ${rod.toY.toStringAsFixed(1)} / 100',
                        const TextStyle(color: Colors.white, fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: 20,
                      getTitlesWidget: (val, _) => Text(
                        val.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (val, _) {
                        final index = val.toInt();
                        if (index < 0 || index >= summary.indicators.length) {
                          return const SizedBox.shrink();
                        }
                        final name = summary.indicators[index].name;
                        final shortName = name
                            .replaceAll(' Index', '')
                            .replaceAll(' Robustness', '')
                            .replaceAll(' & Seed Dispersal', '');
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            shortName,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppColors.borderSubtle,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: summary.indicators.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final ind = entry.value;
                  final color = ind.value >= 75
                      ? AppColors.emerald
                      : (ind.value >= 55
                            ? AppColors.warning
                            : AppColors.danger);

                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: ind.value,
                        color: color,
                        width: 28,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataLineageCard(AreaSummaryModel summary) {
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
              Icon(
                Icons.shield_outlined,
                color: AppColors.forestMedium,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Data Provenance & Calculation Limitations',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...summary.methodologyLimitations.map(
            (lim) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      color: AppColors.forestMedium,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      lim,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
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

  IconData _getIndicatorIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('plant')) return Icons.local_florist_rounded;
    if (lower.contains('connectivity')) return Icons.alt_route_rounded;
    if (lower.contains('pollinator')) return Icons.bug_report_rounded;
    if (lower.contains('bird')) return Icons.flutter_dash_rounded;
    if (lower.contains('benthic') || lower.contains('aquatic')) {
      return Icons.water_rounded;
    }
    return Icons.eco_rounded;
  }

  String _inferGroupFromIndicator(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('plant')) return 'Plants';
    if (lower.contains('pollinator')) return 'Pollinators';
    if (lower.contains('bird')) return 'Birds';
    if (lower.contains('benthic') || lower.contains('aquatic')) {
      return 'Aquatic';
    }
    return 'All';
  }
}
