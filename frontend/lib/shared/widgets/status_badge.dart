import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;

  const StatusBadge({super.key, required this.label, this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    Color badgeColor = color ?? _determineColor(label);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: badgeColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: badgeColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _determineColor(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('critical') ||
        lower.contains('danger') ||
        lower.contains('high risk')) {
      return AppColors.danger;
    } else if (lower.contains('vulnerable') ||
        lower.contains('medium') ||
        lower.contains('moderate')) {
      return AppColors.warning;
    } else if (lower.contains('keystone') ||
        lower.contains('healthy') ||
        lower.contains('pristine')) {
      return AppColors.emerald;
    } else if (lower.contains('aquatic') ||
        lower.contains('water') ||
        lower.contains('info')) {
      return AppColors.oceanBlue;
    }
    return AppColors.sage;
  }
}
