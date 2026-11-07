import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/ecosystem_providers.dart';
import 'area_switcher_dialog.dart';

class AppHeader extends ConsumerWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuPressed;
  final bool showSidebarToggle;

  const AppHeader({
    super.key,
    this.onMenuPressed,
    this.showSidebarToggle = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final areaAsync = ref.watch(selectedAreaProvider);

    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (showSidebarToggle) ...[
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.forestDark),
              onPressed: onMenuPressed,
            ),
            const SizedBox(width: 8),
          ],
          // Brand Logo & Title
          InkWell(
            onTap: () => context.go('/'),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.forestDark,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.eco_rounded,
                      color: AppColors.emerald,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'ECOSYSTEM REWIND',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: AppColors.forestDeep,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.forestDark,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'PRITHVI LABS',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.emerald,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'AI Restoration Intelligence',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          // Active Area Selector Pill
          areaAsync.when(
            data: (area) {
              final name = area?.name ?? 'Select Area';
              return InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AreaSwitcherDialog(
                      onAreaChanged: (newId) {
                        // Keep current sub-route when switching area
                        final location = GoRouterState.of(context).uri
                            .toString();
                        if (location.contains('/workspace/')) {
                          final parts = location.split('/');
                          if (parts.length >= 4) {
                            final feature = parts[3];
                            context.go('/workspace/$newId/$feature');
                          } else {
                            context.go('/workspace/$newId/dashboard');
                          }
                        }
                      },
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.forestMedium,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SizedBox(
              width: 140,
              height: 32,
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (err, stack) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 12),
          // Map exploration shortcut button
          OutlinedButton.icon(
            onPressed: () => context.go('/areas'),
            icon: const Icon(Icons.map_rounded, size: 16),
            label: const Text('Map Explorer'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
