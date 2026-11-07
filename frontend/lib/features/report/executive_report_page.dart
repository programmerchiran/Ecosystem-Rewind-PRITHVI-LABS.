import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/ecosystem_providers.dart';
import '../../shared/widgets/error_display.dart';

class ExecutiveReportPage extends ConsumerWidget {
  final String areaId;

  const ExecutiveReportPage({super.key, required this.areaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(executiveReportProvider(areaId));
    final isDesktop = MediaQuery.of(context).size.width >= 1000;
    final isMobile = MediaQuery.of(context).size.width < 650;

    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      body: reportAsync.when(
        data: (report) {
          final markdownContent = report['markdown_content'] as String? ?? '';
          final areaName = report['area_name'] as String? ?? 'Ecosystem';
          final generatedAt = report['generated_at'] as String? ?? '';
          final metrics =
              report['key_metrics_summary'] as Map<String, dynamic>? ?? {};
          final overallHealth =
              (metrics['overall_health'] as num?)?.toDouble() ?? 0.0;
          final healthStatus =
              metrics['health_status'] as String? ?? 'Degraded';
          final totalIndicators = metrics['total_indicators'] as num? ?? 0;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 48 : (isMobile ? 16 : 24),
              vertical: 28,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Action Bar
                    _buildTopActionBar(context, markdownContent, isMobile),
                    const SizedBox(height: 20),

                    // Metrics Banner
                    _buildMetricsBanner(
                      overallHealth,
                      healthStatus,
                      totalIndicators,
                      isMobile,
                    ),
                    const SizedBox(height: 24),

                    // Document Card
                    _buildReportDocument(
                      areaName,
                      generatedAt,
                      markdownContent,
                      isMobile,
                    ),
                  ],
                ),
              ),
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
                'Compiling Executive Ecological Report...',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        error: (err, _) => ErrorDisplay(
          title: 'Unable to Generate Executive Report',
          message: err.toString(),
          onRetry: () => ref.refresh(executiveReportProvider(areaId)),
        ),
      ),
    );
  }

  Widget _buildTopActionBar(
    BuildContext context,
    String content,
    bool isMobile,
  ) {
    if (isMobile) {
      return Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.forestMedium.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'EXECUTIVE BRIEFING',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.forestDark,
                letterSpacing: 0.6,
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: content));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report copied to clipboard!'),
                  backgroundColor: AppColors.forestDark,
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy Markdown'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.borderSubtle),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.forestMedium.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'EXECUTIVE BRIEFING',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.forestDark,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: content));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Report copied to clipboard!'),
                    backgroundColor: AppColors.forestDark,
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Copy Markdown'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.borderSubtle),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricsBanner(
    double health,
    String status,
    num indicators,
    bool isMobile,
  ) {
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
            _buildMetricCol(
              'Overall Health',
              '${health.toStringAsFixed(1)} / 100',
              AppColors.forestDeep,
            ),
            const Divider(height: 20),
            _buildMetricCol('Ecological Status', status, AppColors.emerald),
            const Divider(height: 20),
            _buildMetricCol(
              'Evaluated Indicators',
              '$indicators Dimensions',
              AppColors.forestDark,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricCol(
            'Overall Health',
            '${health.toStringAsFixed(1)} / 100',
            AppColors.forestDeep,
          ),
          Container(width: 1, height: 36, color: AppColors.borderSubtle),
          _buildMetricCol('Ecological Status', status, AppColors.emerald),
          Container(width: 1, height: 36, color: AppColors.borderSubtle),
          _buildMetricCol(
            'Evaluated Indicators',
            '$indicators Dimensions',
            AppColors.forestDark,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildReportDocument(
    String areaName,
    String generatedAt,
    String markdown,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Letterhead
          if (isMobile) ...[
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRITHVI LABS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: AppColors.forestDark,
                  ),
                ),
                Text(
                  'Ecosystem Rewind Intelligence Platform',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              generatedAt.length > 10
                  ? generatedAt.substring(0, 10)
                  : generatedAt,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PRITHVI LABS',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: AppColors.forestDark,
                      ),
                    ),
                    Text(
                      'Ecosystem Rewind Intelligence Platform',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  generatedAt.length > 10
                      ? generatedAt.substring(0, 10)
                      : generatedAt,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          const Divider(height: 32),

          // Render formatted markdown sections
          ..._parseSimpleMarkdown(markdown),
        ],
      ),
    );
  }

  List<Widget> _parseSimpleMarkdown(String markdown) {
    final lines = markdown.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 8));
      } else if (trimmed.startsWith('# ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 8),
            child: Text(
              trimmed.substring(2),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.forestDeep,
              ),
            ),
          ),
        );
      } else if (trimmed.startsWith('## ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              trimmed.substring(3),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.forestDark,
              ),
            ),
          ),
        );
      } else if (trimmed.startsWith('### ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Text(
              trimmed.substring(4),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        );
      } else if (trimmed.startsWith('- ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 8),
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
                    trimmed
                        .substring(2)
                        .replaceAll('**', '')
                        .replaceAll('*', ''),
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (trimmed.startsWith('---')) {
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              trimmed.replaceAll('**', '').replaceAll('*', ''),
              style: const TextStyle(
                fontSize: 13,
                height: 1.6,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }
}
