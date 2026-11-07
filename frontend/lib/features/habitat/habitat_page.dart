
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../models/habitat_model.dart';
import '../../providers/ecosystem_providers.dart';
import 'habitat_map_widget.dart';

class HabitatPage extends ConsumerWidget {
  const HabitatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(habitatSummaryProvider);
    final cellsAsync = ref.watch(habitatCellsProvider(null));

    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(habitatSummaryProvider);
            ref.invalidate(habitatCellsProvider(null));
            await ref.read(habitatSummaryProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
                _buildHeader(),
                const SizedBox(height: 24),
                
                const HabitatMapWidget(),
                const SizedBox(height: 24),

              summaryAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => _ErrorPanel(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(habitatSummaryProvider),
                ),
                data: (summary) => _SummarySection(summary: summary),
              ),

              const SizedBox(height: 24),

              _buildMapSection(cellsAsync),

              const SizedBox(height: 24),

              summaryAsync.when(
                data: (summary) => _DisclaimerCard(
                  disclaimer: summary.disclaimer,
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TEAK HABITAT INTELLIGENCE',
          style: TextStyle(
            color: AppColors.emerald,
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Habitat Suitability',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Explore model-estimated habitat suitability for '
          'Tectona grandis across mapped forest cells in India.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMapSection(
    AsyncValue<HabitatCellsResponseModel> cellsAsync,
  ) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.borderDark),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Suitability Grid',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Initial sample of predicted 5 km forest grid cells.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 18),
            cellsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Text(
                'Unable to load habitat cells: $error',
                style: const TextStyle(color: Colors.red),
              ),
              data: (response) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${response.cells.length} cells loaded '
                    'out of ${response.total} available cells.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  if (response.cells.isEmpty)
                    const Text('No habitat cells found.')
                  else
                    ...response.cells.take(8).map(
                      (cell) => _CellTile(cell),
                    ),
                  if (response.cells.length > 8)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Showing 8 sample cells in this preview.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final HabitatSummaryModel summary;

  const _SummarySection({required this.summary});

  @override
  Widget build(BuildContext context) {
    final high = (summary.classDistribution['High'] ?? 0) +
        (summary.classDistribution['Very High'] ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard(
              title: 'Forest Cells',
              value: summary.totalCells.toString(),
              subtitle: 'Modelled grid cells',
            ),
            _MetricCard(
              title: 'Mean Suitability',
              value: (summary.meanScore * 100).toStringAsFixed(1),
              subtitle: 'Relative index / 100',
            ),
            _MetricCard(
              title: 'High + Very High',
              value: high.toString(),
              subtitle: 'Cells in these classes',
            ),
            _MetricCard(
              title: 'Grid Resolution',
              value: summary.gridResolution,
              subtitle: 'Spatial resolution',
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Suitability Distribution',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...summary.classDistribution.entries.map(
          (entry) => _DistributionRow(
            label: entry.key,
            count: entry.value,
            total: summary.totalCells,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.borderDark),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DistributionRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;

  const _DistributionRow({
    required this.label,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = total > 0 ? count / total : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text('$count  (${(fraction * 100).toStringAsFixed(1)}%)'),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 9,
              backgroundColor: AppColors.surfaceBackground,
              color: AppColors.emerald,
            ),
          ),
        ],
      ),
    );
  }
}

class _CellTile extends StatelessWidget {
  final HabitatCellModel cell;

  const _CellTile(this.cell);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(
        Icons.forest_outlined,
        color: AppColors.emerald,
      ),
      title: Text(
        '${cell.suitabilityClass} suitability',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        'Lat ${cell.latitude.toStringAsFixed(3)}, '
        'Lon ${cell.longitude.toStringAsFixed(3)}',
      ),
      trailing: Text(
        cell.index.toStringAsFixed(1),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  final String disclaimer;

  const _DisclaimerCard({required this.disclaimer});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFFFF7E6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                disclaimer.isEmpty
                    ? 'This is an exploratory relative suitability index, '
                        'not a verified probability of wild teak occurrence.'
                    : disclaimer,
                style: const TextStyle(fontSize: 12, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorPanel({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.cloud_off, color: Colors.red, size: 32),
            const SizedBox(height: 8),
            const Text('Unable to load habitat summary'),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
