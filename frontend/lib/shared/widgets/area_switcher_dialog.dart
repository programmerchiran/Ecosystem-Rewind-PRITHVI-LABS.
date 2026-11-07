import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/ecosystem_providers.dart';
import '../../models/area_model.dart';

class AreaSwitcherDialog extends ConsumerWidget {
  final Function(String newAreaId)? onAreaChanged;

  const AreaSwitcherDialog({super.key, this.onAreaChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final areasAsync = ref.watch(areasListProvider);
    final currentAreaId = ref.watch(selectedAreaIdProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.public, color: AppColors.forestMedium),
                    SizedBox(width: 10),
                    Text(
                      'Switch Study Area',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Select an ecosystem to load its dedicated indicators, interaction network, and restoration model.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            areasAsync.when(
              data: (areas) {
                return Column(
                  children: areas.map((area) {
                    final isSelected = area.areaId == currentAreaId;
                    return _buildAreaCard(context, ref, area, isSelected);
                  }).toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error loading areas: $err'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAreaCard(
    BuildContext context,
    WidgetRef ref,
    EcosystemAreaModel area,
    bool isSelected,
  ) {
    final isForest = area.areaId.contains('forest');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.emeraldSubtle.withValues(alpha: 0.5)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? AppColors.emerald : AppColors.borderSubtle,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isForest
                ? AppColors.forestMedium.withValues(alpha: 0.12)
                : AppColors.oceanBlue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isForest ? Icons.forest_rounded : Icons.water_rounded,
            color: isForest ? AppColors.forestMedium : AppColors.oceanBlue,
          ),
        ),
        title: Text(
          area.name,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              area.ecosystemType,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${area.areaSize.toStringAsFixed(0)} ${area.areaSizeUnit} • Lat ${area.centerLatitude.toStringAsFixed(2)}°, Long ${area.centerLongitude.toStringAsFixed(2)}°',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: AppColors.emerald)
            : const Icon(Icons.arrow_forward_ios_rounded, size: 14),
        onTap: () {
          ref.read(selectedAreaIdProvider.notifier).state = area.areaId;
          ref.read(dominoNotifierProvider.notifier).reset();
          ref.read(scenarioNotifierProvider.notifier).reset();
          Navigator.of(context).pop();
          if (onAreaChanged != null) {
            onAreaChanged!(area.areaId);
          }
        },
      ),
    );
  }
}
