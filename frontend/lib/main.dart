import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'features/landing/landing_page.dart';
import 'features/area_selection/area_selection_page.dart';
import 'features/workspace/workspace_shell.dart';
import 'features/health_dashboard/health_dashboard_page.dart';
import 'features/ecosystem_network/ecosystem_network_page.dart';
import 'features/domino_simulator/domino_simulator_page.dart';
import 'features/recommendations/recommendations_page.dart';
import 'features/time_machine/time_machine_page.dart';
import 'features/report/executive_report_page.dart';
import 'features/habitat/habitat_page.dart';
import 'features/ai_chat/ai_chat_page.dart';

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    // 1. Landing Page
    GoRoute(
      path: '/',
      name: 'landing',
      builder: (context, state) => const LandingPage(),
    ),

    // 2. Geographic Area Selection Map
    GoRoute(
      path: '/areas',
      name: 'areas',
      builder: (context, state) => const AreaSelectionPage(),
    ),
    GoRoute(
      path: '/explore',
      redirect: (context, state) => '/areas',
    ),

    // 3. Workspace Shell with Nested Feature Pages
    GoRoute(
      path: '/workspace/:areaId',
      redirect: (context, state) {
        final areaId = state.pathParameters['areaId'] ?? 'western_ghats_forest';
        return '/workspace/$areaId/dashboard';
      },
    ),

    // Feature A: Health Dashboard
    GoRoute(
      path: '/workspace/:areaId/dashboard',
      name: 'dashboard',
      builder: (context, state) {
        final areaId = state.pathParameters['areaId'] ?? 'western_ghats_forest';
        return WorkspaceShell(
          areaId: areaId,
          child: HealthDashboardPage(areaId: areaId),
        );
      },
    ),

    // Feature: Teak Habitat Suitability
    GoRoute(
      path: '/workspace/:areaId/habitat',
      name: 'habitat',
      builder: (context, state) {
        final areaId =
            state.pathParameters['areaId'] ?? 'western_ghats_forest';

        return WorkspaceShell(
          areaId: areaId,
          child: const HabitatPage(),
        );
      },
    ),

    // Feature: EcoMind AI Assistant
    GoRoute(
      path: '/workspace/:areaId/ai-chat',
      name: 'ai-chat',
      builder: (context, state) {
        final areaId =
            state.pathParameters['areaId'] ?? 'western_ghats_forest';
    
        return WorkspaceShell(
          areaId: areaId,
          child: const AiChatPage(),
        );
      },
    ),
    // Feature B: Species Network Graph
    GoRoute(
      path: '/workspace/:areaId/network',
      name: 'network',
      builder: (context, state) {
        final areaId = state.pathParameters['areaId'] ?? 'western_ghats_forest';
        return WorkspaceShell(
          areaId: areaId,
          child: EcosystemNetworkPage(areaId: areaId),
        );
      },
    ),

    // Feature C: Domino Simulator
    GoRoute(
      path: '/workspace/:areaId/domino',
      name: 'domino',
      builder: (context, state) {
        final areaId = state.pathParameters['areaId'] ?? 'western_ghats_forest';
        return WorkspaceShell(
          areaId: areaId,
          child: DominoSimulatorPage(areaId: areaId),
        );
      },
    ),

    // Feature D: Restoration Recommendations
    GoRoute(
      path: '/workspace/:areaId/recommendations',
      name: 'recommendations',
      builder: (context, state) {
        final areaId = state.pathParameters['areaId'] ?? 'western_ghats_forest';
        return WorkspaceShell(
          areaId: areaId,
          child: RecommendationsPage(areaId: areaId),
        );
      },
    ),

    // Feature E: Restoration Time Machine
    GoRoute(
      path: '/workspace/:areaId/time-machine',
      name: 'time-machine',
      builder: (context, state) {
        final areaId = state.pathParameters['areaId'] ?? 'western_ghats_forest';
        return WorkspaceShell(
          areaId: areaId,
          child: TimeMachinePage(areaId: areaId),
        );
      },
    ),

    // Executive Report
    GoRoute(
      path: '/workspace/:areaId/report',
      name: 'report',
      builder: (context, state) {
        final areaId = state.pathParameters['areaId'] ?? 'western_ghats_forest';
        return WorkspaceShell(
          areaId: areaId,
          child: ExecutiveReportPage(areaId: areaId),
        );
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Page Not Found (404)',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(state.uri.toString()),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text('Return to Home'),
          ),
        ],
      ),
    ),
  ),
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: EcosystemRewindApp()));
}

class EcosystemRewindApp extends StatelessWidget {
  const EcosystemRewindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}
