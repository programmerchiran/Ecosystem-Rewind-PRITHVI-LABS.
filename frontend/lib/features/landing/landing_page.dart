import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1000;

    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 64 : (size.width < 360 ? 12 : 20),
            vertical: 14,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
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
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ECOSYSTEM REWIND',
                      style: TextStyle(
                        fontSize: size.width < 380 ? 13 : 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppColors.forestDeep,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (size.width >= 380)
                      const Text(
                        'PRITHVI LABS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.emerald,
                          letterSpacing: 1.0,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (size.width >= 560) ...[
                TextButton(
                  onPressed: () => context.go('/areas'),
                  child: const Text('Study Areas'),
                ),
                const SizedBox(width: 8),
              ],
              ElevatedButton(
                onPressed: () =>
                    context.go('/workspace/western_ghats_forest/dashboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forestDark,
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width < 400 ? 12 : 18,
                    vertical: 10,
                  ),
                ),
                child: Text(size.width < 400 ? 'Demo' : 'Launch Demo'),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 64 : (size.width < 360 ? 16 : 24),
                vertical: isDesktop ? 80 : 40,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    AppColors.sageBackground.withValues(alpha: 0.5),
                  ],
                ),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: isDesktop
                    ? _buildDesktopHero(context)
                    : _buildMobileHero(context),
              ),
            ),

            const SizedBox(height: 40),

            // 5 Features Grid
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 64 : 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldSubtle,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'INTELLIGENCE SUITE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.forestDark,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Five Pillars of Ecological Intelligence',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forestDeep,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Deterministic Network Analysis & Restoration Decision Support for Fragile Ecosystems',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    _buildFeaturesGrid(context, isDesktop),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 80),

            // About / Purpose Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 64 : 24,
                vertical: 60,
              ),
              color: AppColors.forestDark,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  children: [
                    const Icon(
                      Icons.public,
                      color: AppColors.emeraldLight,
                      size: 44,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'About PRITHVI LABS',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'PRITHVI LABS engineers computational tools at the intersection of network ecology, remote sensing, and biodiversity restoration. Ecosystem Rewind enables conservation planners, land managers, and policy makers to see the hidden dependencies of nature, simulate the cascading impacts of species extinction, and prioritize cost-effective intervention corridors before irreversible thresholds are crossed.',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.sageLight,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildFeaturePill(
                          Icons.lock_outline,
                          'Transparent Rule Sets',
                        ),
                        _buildFeaturePill(
                          Icons.account_tree_outlined,
                          'NetworkX Graph Engine',
                        ),
                        _buildFeaturePill(
                          Icons.bolt_outlined,
                          'Zero Cloud Credential Dependency',
                        ),
                        _buildFeaturePill(
                          Icons.dataset_outlined,
                          'Reproducible Baseline Lineage',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              color: AppColors.forestDeep,
              child: const Center(
                child: Text(
                  '© 2026 PRITHVI LABS • ECOSYSTEM REWIND • Phase 1 + 2 Implementation',
                  style: TextStyle(color: AppColors.sage, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturePill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.emeraldLight),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopHero(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.emeraldSubtle,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.hub, size: 14, color: AppColors.forestMedium),
                    SizedBox(width: 8),
                    Text(
                      'ECOSYSTEM RESTORATION PLATFORM',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forestDark,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Understand the Domino.\nRestore the Future.',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  letterSpacing: -1.2,
                  color: AppColors.forestDeep,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Explore ecological relationships, identify potential ecosystem risks, and compare restoration strategies through data-driven analysis.',
                style: TextStyle(
                  fontSize: 17,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => context.go('/areas'),
                    icon: const Icon(Icons.explore_rounded),
                    label: const Text('Analyze an Ecosystem'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.go('/workspace/western_ghats_forest/dashboard'),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Explore Demo'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 36),
        Expanded(flex: 5, child: _buildHeroVisualCard(context)),
      ],
    );
  }

  Widget _buildMobileHero(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Understand the Domino.\nRestore the Future.',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            height: 1.15,
            color: AppColors.forestDeep,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Explore ecological relationships, identify potential ecosystem risks, and compare restoration strategies through data-driven analysis.',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton(
              onPressed: () => context.go('/areas'),
              child: const Text('Analyze an Ecosystem'),
            ),
            OutlinedButton(
              onPressed: () =>
                  context.go('/workspace/western_ghats_forest/dashboard'),
              child: const Text('Explore Demo'),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildHeroVisualCard(context),
      ],
    );
  }

  Widget _buildHeroVisualCard(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardPadding = screenWidth < 450 ? 16.0 : 26.0;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: AppColors.forestDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'INTERACTION NETWORK SAMPLE',
                    style: TextStyle(
                      color: AppColors.emeraldLight,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.scatter_plot, color: AppColors.emeraldLight),
            ],
          ),
          const SizedBox(height: 20),
          _buildNetworkSimulationPreview(),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Simulate species removal to witness trophic cascade shocks and isolation warnings in real time.',
                    style: TextStyle(
                      color: AppColors.sageLight,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkSimulationPreview() {
    return Column(
      children: [
        _buildVisualNodeRow(
          'Canopy Mast Tree',
          'Keystone Producer',
          Icons.park_rounded,
          AppColors.emeraldLight,
        ),
        const SizedBox(height: 10),
        _buildVisualLink(
          Icons.sync_alt,
          'Pollination / Seed Dispersal Mutualism',
        ),
        const SizedBox(height: 10),
        _buildVisualNodeRow(
          'Giant Honey Bee',
          'Canopy Pollinator Guild',
          Icons.pest_control_rounded,
          AppColors.warning,
        ),
        const SizedBox(height: 10),
        _buildVisualLink(Icons.south, 'Downstream Trophic Dependency'),
        const SizedBox(height: 10),
        _buildVisualNodeRow(
          'Lion-tailed Macaque',
          'Endangered Frugivore',
          Icons.pets_rounded,
          AppColors.oceanBlue,
        ),
      ],
    );
  }

  Widget _buildVisualNodeRow(
    String title,
    String role,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  role,
                  style: const TextStyle(
                    color: AppColors.sageLight,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualLink(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: AppColors.sageLight),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.sageLight, fontSize: 10),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesGrid(BuildContext context, bool isDesktop) {
    final features = [
      _FeatureCardData(
        title: 'Ecosystem Health Dashboard',
        description: 'Multi-dimensional composite scoring tracking plant diversity, habitat connectivity, pollinator networks, and avian dispersal.',
        icon: Icons.speed_rounded,
        route: '/workspace/western_ghats_forest/dashboard',
      ),
      _FeatureCardData(
        title: 'Interactive Ecosystem Network',
        description: 'Explore species nodes and ecological edges (pollination, seed dispersal, food web, symbiosis) with drag, zoom, and centrality metrics.',
        icon: Icons.hub_rounded,
        route: '/workspace/western_ghats_forest/network',
      ),
      _FeatureCardData(
        title: 'Ecological Domino Simulator',
        description: 'Remove a species to calculate cascading trophic stress, lost links, newly isolated components, and community shock scores.',
        icon: Icons.scatter_plot_rounded,
        route: '/workspace/western_ghats_forest/domino',
      ),
      _FeatureCardData(
        title: 'Rule-Based Restoration Engine',
        description: 'Transparent multi-criteria utility ranking that pairs identified ecosystem deficits with feasible restoration interventions.',
        icon: Icons.volunteer_activism_rounded,
        route: '/workspace/western_ghats_forest/recommendations',
      ),
      _FeatureCardData(
        title: 'Restoration Time Machine',
        description: 'Project ecosystem trajectory to 2030, 2040, and 2045 comparing business-as-usual degradation with active restoration.',
        icon: Icons.auto_graph_rounded,
        route: '/workspace/western_ghats_forest/time-machine',
      ),
    ];

    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: features.map((f) {
        final cardWidth = isDesktop ? 360.0 : double.infinity;
        return SizedBox(width: cardWidth, child: _buildFeatureCard(context, f));
      }).toList(),
    );
  }

  Widget _buildFeatureCard(BuildContext context, _FeatureCardData f) {
    return InkWell(
      onTap: () => context.go(f.route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.forestMedium.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(f.icon, color: AppColors.forestMedium, size: 26),
            ),
            const SizedBox(height: 16),
            Text(
              f.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              f.description,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Text(
                  'Launch Feature',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.forestDark,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: AppColors.forestDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCardData {
  final String title;
  final String description;
  final IconData icon;
  final String route;

  _FeatureCardData({
    required this.title,
    required this.description,
    required this.icon,
    required this.route,
  });
}
