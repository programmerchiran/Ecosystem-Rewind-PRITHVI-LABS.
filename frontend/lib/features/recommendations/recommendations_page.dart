import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/ecosystem_providers.dart';
import '../../models/recommendation_model.dart';
import '../../shared/widgets/error_display.dart';

class RecommendationsPage extends ConsumerStatefulWidget {
  final String areaId;

  const RecommendationsPage({super.key, required this.areaId});

  @override
  ConsumerState<RecommendationsPage> createState() =>
      _RecommendationsPageState();
}

class _RecommendationsPageState extends ConsumerState<RecommendationsPage> {
  String _selectedUrgency = 'All';
  String _selectedProblem = 'All';
  double? _maxBudget;

  @override
  Widget build(BuildContext context) {
    final recommendationsAsync = ref.watch(
      recommendationsProvider(widget.areaId),
    );
    final isDesktop = MediaQuery.of(context).size.width >= 1000;
    final isMobile = MediaQuery.of(context).size.width < 650;

    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      body: recommendationsAsync.when(
        data: (data) {
          // Extract unique problem types for filtering
          final allProblems = <String>{'All'};
          for (final r in data.recommendations) {
            allProblems.addAll(r.targetProblems);
          }

          // Apply filters
          final filtered = data.recommendations.where((r) {
            if (_selectedUrgency != 'All' &&
                r.urgencyLevel.toLowerCase() !=
                    _selectedUrgency.toLowerCase()) {
              return false;
            }
            if (_selectedProblem != 'All' &&
                !r.targetProblems.contains(_selectedProblem)) {
              return false;
            }
            if (_maxBudget != null && r.totalEstimatedBudgetUsd > _maxBudget!) {
              return false;
            }
            return true;
          }).toList();

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 36 : (isMobile ? 16 : 24),
              vertical: 28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(context, data, isMobile),
                const SizedBox(height: 24),

                // Top KPI summary strip
                _buildSummaryBanner(data, isDesktop, isMobile),
                const SizedBox(height: 24),

                // Filters
                _buildFilterBar(allProblems.toList(), isMobile),
                const SizedBox(height: 24),

                // Action cards
                if (filtered.isEmpty)
                  _buildEmptyFilterState()
                else
                  _buildRecommendationsList(filtered, isDesktop, isMobile),
                const SizedBox(height: 32),

                // Scientific Methodology & Transparent Assumptions
                _buildMethodologyCard(data),
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
              Text(
                'Synthesizing rule-based restoration actions...',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        error: (err, _) => ErrorDisplay(
          title: 'Unable to Load Recommendations',
          message: err.toString(),
          onRetry: () => ref.refresh(recommendationsProvider(widget.areaId)),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    RecommendationResponseModel data,
    bool isMobile,
  ) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.forestMedium.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'PRIORITIZED ACTION PLAN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.forestDark,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              Text(
                '${data.totalRecommendations} Actions Available',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data.ecosystemName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.forestDeep,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () =>
                context.go('/workspace/${widget.areaId}/time-machine'),
            icon: const Icon(Icons.auto_graph_rounded, size: 16),
            label: const Text('Simulate in Time Machine'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.forestMedium.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'PRIORITIZED ACTION PLAN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forestDark,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  Text(
                    '${data.totalRecommendations} Actions Evaluated',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                data.ecosystemName,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.forestDeep,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Actions ranked by ecological urgency, connectivity deficit recovery, and cost feasibility.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () =>
              context.go('/workspace/${widget.areaId}/time-machine'),
          icon: const Icon(Icons.auto_graph_rounded, size: 16),
          label: const Text('Simulate in Time Machine'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.emerald,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryBanner(
    RecommendationResponseModel data,
    bool isDesktop,
    bool isMobile,
  ) {
    final topAction = data.recommendations.isNotEmpty
        ? data.recommendations.first
        : null;
    final totalBudget = data.recommendations.fold<double>(
      0,
      (sum, r) => sum + r.totalEstimatedBudgetUsd,
    );

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          children: [
            _buildStatItem(
              'Recommended Actions',
              '${data.recommendations.length}',
              Icons.fact_check_rounded,
              AppColors.forestDark,
            ),
            const Divider(height: 20),
            _buildStatItem(
              'Top Priority Action',
              topAction?.name ?? 'N/A',
              Icons.star_rounded,
              AppColors.emerald,
            ),
            const Divider(height: 20),
            _buildStatItem(
              'Combined Investment',
              '\$${(totalBudget / 1000).toStringAsFixed(0)}k USD',
              Icons.payments_rounded,
              AppColors.warning,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _buildStatItem(
              'Recommended Actions',
              '${data.recommendations.length}',
              Icons.fact_check_rounded,
              AppColors.forestDark,
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.borderSubtle),
          Expanded(
            child: _buildStatItem(
              'Top Priority Action',
              topAction?.name ?? 'N/A',
              Icons.star_rounded,
              AppColors.emerald,
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.borderSubtle),
          Expanded(
            child: _buildStatItem(
              'Combined Investment',
              '\$${(totalBudget / 1000).toStringAsFixed(0)}k USD',
              Icons.payments_rounded,
              AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.forestDeep,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(List<String> problemTypes, bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.filter_list_rounded,
                          size: 18,
                          color: AppColors.forestDark,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Filters:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.forestDark,
                          ),
                        ),
                      ],
                    ),
                    if (_selectedUrgency != 'All' ||
                        _selectedProblem != 'All' ||
                        _maxBudget != null)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedUrgency = 'All';
                            _selectedProblem = 'All';
                            _maxBudget = null;
                          });
                        },
                        icon: const Icon(Icons.clear_rounded, size: 14),
                        label: const Text('Reset', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: _selectedUrgency,
                  isExpanded: true,
                  underline: const SizedBox(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.forestDeep,
                    fontWeight: FontWeight.w600,
                  ),
                  items: ['All', 'Critical', 'High', 'Medium'].map((u) {
                    return DropdownMenuItem(value: u, child: Text('Urgency: $u'));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedUrgency = val);
                  },
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: _selectedProblem,
                  isExpanded: true,
                  underline: const SizedBox(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.forestDeep,
                    fontWeight: FontWeight.w600,
                  ),
                  items: problemTypes.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text(
                        'Problem: ${p.length > 25 ? "${p.substring(0, 22)}..." : p}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedProblem = val);
                  },
                ),
              ],
            )
          : Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_list_rounded,
                      size: 18,
                      color: AppColors.forestDark,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Filters:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.forestDark,
                      ),
                    ),
                  ],
                ),
                // Urgency Filter
                DropdownButton<String>(
                  value: _selectedUrgency,
                  underline: const SizedBox(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.forestDeep,
                    fontWeight: FontWeight.w600,
                  ),
                  items: ['All', 'Critical', 'High', 'Medium'].map((u) {
                    return DropdownMenuItem(value: u, child: Text('Urgency: $u'));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedUrgency = val);
                  },
                ),
                // Problem Type Filter
                DropdownButton<String>(
                  value: _selectedProblem,
                  underline: const SizedBox(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.forestDeep,
                    fontWeight: FontWeight.w600,
                  ),
                  items: problemTypes.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text(
                        'Problem: ${p.length > 25 ? "${p.substring(0, 22)}..." : p}',
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedProblem = val);
                  },
                ),
                // Reset button
                if (_selectedUrgency != 'All' ||
                    _selectedProblem != 'All' ||
                    _maxBudget != null)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedUrgency = 'All';
                        _selectedProblem = 'All';
                        _maxBudget = null;
                      });
                    },
                    icon: const Icon(Icons.clear_rounded, size: 14),
                    label: const Text('Reset', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildRecommendationsList(
    List<RestorationActionModel> actions,
    bool isDesktop,
    bool isMobile,
  ) {
    final scenarioState = ref.watch(scenarioNotifierProvider);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final action = actions[index];
        final isSelectedInScenario = scenarioState.selectedActionIds.contains(
          action.actionId,
        );

        return _buildActionCard(
          action,
          index + 1,
          isSelectedInScenario,
          isMobile,
        );
      },
    );
  }

  Widget _buildActionCard(
    RestorationActionModel action,
    int rank,
    bool isSelected,
    bool isMobile,
  ) {
    Color urgencyColor;
    switch (action.urgencyLevel.toLowerCase()) {
      case 'critical':
        urgencyColor = AppColors.danger;
        break;
      case 'high':
        urgencyColor = AppColors.warning;
        break;
      default:
        urgencyColor = AppColors.emerald;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.emerald : AppColors.borderSubtle,
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Rank, Action Name, Urgency, Ranking Score
          if (isMobile) ...[
            Row(
              children: [
                // Rank badge
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.forestMedium.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '#$rank',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.forestDark,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    action.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.forestDeep,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: urgencyColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${action.urgencyLevel.toUpperCase()} URGENCY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: urgencyColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.speed_rounded,
                      size: 14,
                      color: AppColors.emerald,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Score: ${action.rankingScore.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.forestDark,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Targets: ${action.problemAddressed}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rank badge
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.forestMedium.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '#$rank',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.forestDark,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.forestDeep,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Targets: ${action.problemAddressed}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Urgency and Score
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: urgencyColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${action.urgencyLevel.toUpperCase()} URGENCY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: urgencyColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.speed_rounded,
                          size: 14,
                          color: AppColors.emerald,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Score: ${action.rankingScore.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.forestDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),

          // Description
          Text(
            action.description,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),

          // Cost & Feasibility strip
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.attach_money_rounded,
                  size: 16,
                  color: AppColors.forestMedium,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Estimated Budget: \$${action.totalEstimatedBudgetUsd.toStringAsFixed(0)} (${action.costEstimateUsd.toStringAsFixed(0)} ${action.costUnit})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.forestDeep,
                    ),
                  ),
                ),
                if (action.dataMode.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    action.dataMode,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Beneficiary species chips
          if (action.beneficiarySpecies.isNotEmpty) ...[
            const Text(
              'Beneficiary Keystone & Indicator Species:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: action.beneficiarySpecies.map((s) {
                return Chip(
                  label: Text(s),
                  labelStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.forestDeep,
                  ),
                  backgroundColor: AppColors.emerald.withValues(alpha: 0.08),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: BorderSide.none,
                  ),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Ranking factors & Action button
          if (isMobile) ...[
            Text(
              action.rankingFactors.isNotEmpty
                  ? 'Decision rationale: ${action.rankingFactors.join(' • ')}'
                  : action.feasibilityNotes,
              style: const TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ref
                      .read(scenarioNotifierProvider.notifier)
                      .toggleAction(action.actionId);
                },
                icon: Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.add_circle_outline_rounded,
                  size: 16,
                  color: isSelected ? AppColors.emerald : AppColors.forestDark,
                ),
                label: Text(
                  isSelected ? 'Selected for Scenario' : 'Add to Time Machine',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? AppColors.emerald
                        : AppColors.forestDark,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.emerald
                        : AppColors.borderSubtle,
                  ),
                  backgroundColor: isSelected
                      ? AppColors.emerald.withValues(alpha: 0.08)
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    action.rankingFactors.isNotEmpty
                        ? 'Decision rationale: ${action.rankingFactors.join(' • ')}'
                        : action.feasibilityNotes,
                    style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    ref
                        .read(scenarioNotifierProvider.notifier)
                        .toggleAction(action.actionId);
                  },
                  icon: Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.add_circle_outline_rounded,
                    size: 16,
                    color: isSelected ? AppColors.emerald : AppColors.forestDark,
                  ),
                  label: Text(
                    isSelected ? 'Selected for Scenario' : 'Add to Time Machine',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.emerald
                          : AppColors.forestDark,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.emerald
                          : AppColors.borderSubtle,
                    ),
                    backgroundColor: isSelected
                        ? AppColors.emerald.withValues(alpha: 0.08)
                        : Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyFilterState() {
    return Container(
      padding: const EdgeInsets.all(36),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 12),
          const Text(
            'No restoration actions match your filter criteria',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.forestDeep,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try widening your problem or urgency filter.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedUrgency = 'All';
                _selectedProblem = 'All';
                _maxBudget = null;
              });
            },
            child: const Text('Reset All Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodologyCard(RecommendationResponseModel data) {
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
                  Icons.rule_folder_rounded,
                  color: AppColors.forestDark,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Transparent Recommendation Methodology & Limitations',
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
          Text(
            data.rankingMethodology,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ...data.limitationsAndAssumptions.map((limitation) {
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
                      limitation,
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
