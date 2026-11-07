import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/ecosystem_providers.dart';

class AppSidebar extends ConsumerWidget {
  final String activeAreaId;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;

  const AppSidebar({
    super.key,
    required this.activeAreaId,
    this.isCollapsed = false,
    this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final areaAsync = ref.watch(selectedAreaProvider);
    final routerState = GoRouterState.of(context);
    final currentPath = routerState.uri.toString();

    final navItems = [
      _NavItem(
        title: 'Health Dashboard',
        icon: Icons.dashboard_rounded,
        route: '/workspace/$activeAreaId/dashboard',
        featureKey: 'dashboard',
      ),
      _NavItem(
        title: 'EcoMind AI',
        icon: Icons.psychology_rounded,
        route: '/workspace/$activeAreaId/ai-chat',
        featureKey: 'ai-chat',
      ),
      _NavItem(
        title: 'Teak Habitat',
        icon: Icons.forest_rounded,
        route: '/workspace/$activeAreaId/habitat',
        featureKey: 'habitat',
      ),
      _NavItem(
        title: 'Species Network',
        icon: Icons.hub_rounded,
        route: '/workspace/$activeAreaId/network',
        featureKey: 'network',
      ),
      _NavItem(
        title: 'Domino Simulator',
        icon: Icons.scatter_plot_rounded,
        route: '/workspace/$activeAreaId/domino',
        featureKey: 'domino',
      ),
      _NavItem(
        title: 'Restoration Actions',
        icon: Icons.volunteer_activism_rounded,
        route: '/workspace/$activeAreaId/recommendations',
        featureKey: 'recommendations',
      ),
      _NavItem(
        title: 'Time Machine',
        icon: Icons.auto_graph_rounded,
        route: '/workspace/$activeAreaId/time-machine',
        featureKey: 'time-machine',
      ),
      _NavItem(
        title: 'Executive Report',
        icon: Icons.summarize_rounded,
        route: '/workspace/$activeAreaId/report',
        featureKey: 'report',
      ),
    ];

    return Container(
      width: isCollapsed ? 76 : 260,
      decoration: const BoxDecoration(
        color: AppColors.forestDark,
        border: Border(
          right: BorderSide(color: AppColors.borderDark, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar Top Area Banner
          if (!isCollapsed) ...[
            Padding(
              padding: const EdgeInsets.all(20),
              child: areaAsync.when(
                data: (area) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ACTIVE ECOSYSTEM',
                        style: TextStyle(
                          color: AppColors.emeraldLight,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      area?.name ?? 'Ecosystem Area',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      area?.ecosystemType ?? '',
                      style: const TextStyle(
                        color: AppColors.sageLight,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                loading: () => const SizedBox(height: 48),
                error: (error, stackTrace) => const SizedBox(height: 48),
              ),
            ),
            const Divider(color: AppColors.borderDark, height: 1),
          ] else ...[
            const SizedBox(height: 16),
            Center(
              child: IconButton(
                onPressed: onToggleCollapse,
                icon: const Icon(Icons.chevron_right, color: Colors.white),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Navigation Links
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: navItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isActive = currentPath.contains('/${item.featureKey}');

                return _SidebarTile(
                  item: item,
                  isActive: isActive,
                  isCollapsed: isCollapsed,
                  onTap: () => context.go(item.route),
                );
              },
            ),
          ),

          // Data Mode / Info Footer
          if (!isCollapsed) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          size: 14,
                          color: AppColors.emeraldLight,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'DATA LINEAGE',
                          style: TextStyle(
                            color: AppColors.emeraldLight,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Mode: DEMO_ILLUSTRATIVE\nDeterministic rule-based baseline.',
                      style: TextStyle(
                        color: AppColors.sageLight,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NavItem {
  final String title;
  final IconData icon;
  final String route;
  final String featureKey;

  _NavItem({
    required this.title,
    required this.icon,
    required this.route,
    required this.featureKey,
  });
}

class _SidebarTile extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.item,
    required this.isActive,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCollapsed ? 12 : 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.emerald.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? AppColors.emerald.withValues(alpha: 0.4)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: isCollapsed
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Icon(
              item.icon,
              size: 20,
              color: isActive ? AppColors.emeraldLight : AppColors.sageLight,
            ),
            if (!isCollapsed) ...[
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    color: isActive ? Colors.white : AppColors.sageLight,
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (isActive)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.emeraldLight,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
