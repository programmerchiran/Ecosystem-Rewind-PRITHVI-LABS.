import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/landing/landing_page.dart';
import 'package:frontend/features/health_dashboard/health_dashboard_page.dart';
import 'package:frontend/features/recommendations/recommendations_page.dart';
import 'package:frontend/features/time_machine/time_machine_page.dart';
import 'package:frontend/features/report/executive_report_page.dart';
import 'package:frontend/providers/ecosystem_providers.dart';
import 'features_test.dart';

void main() {
  final stubRepo = StubEcosystemRepository();

  const viewports = [
    Size(320, 568),   // Small Mobile
    Size(375, 667),   // Standard Mobile
    Size(430, 932),   // Large Mobile
    Size(768, 1024),  // Tablet
    Size(1366, 768),  // Laptop
    Size(1920, 1080), // Desktop
  ];

  for (final vp in viewports) {
    group('Viewport ${vp.width.toInt()}x${vp.height.toInt()}', () {
      testWidgets('Landing page renders without overflow', (tester) async {
        tester.view.physicalSize = vp;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ecosystemRepoProvider.overrideWithValue(stubRepo),
            ],
            child: const MaterialApp(home: LandingPage()),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('Health Dashboard renders without overflow', (tester) async {
        tester.view.physicalSize = vp;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ecosystemRepoProvider.overrideWithValue(stubRepo),
            ],
            child: const MaterialApp(home: HealthDashboardPage(areaId: 'western_ghats_forest')),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('Recommendations page renders without overflow', (tester) async {
        tester.view.physicalSize = vp;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ecosystemRepoProvider.overrideWithValue(stubRepo),
            ],
            child: const MaterialApp(home: RecommendationsPage(areaId: 'western_ghats_forest')),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('Time Machine page renders without overflow', (tester) async {
        tester.view.physicalSize = vp;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ecosystemRepoProvider.overrideWithValue(stubRepo),
            ],
            child: const MaterialApp(home: TimeMachinePage(areaId: 'western_ghats_forest')),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('Executive Report page renders without overflow', (tester) async {
        tester.view.physicalSize = vp;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ecosystemRepoProvider.overrideWithValue(stubRepo),
            ],
            child: const MaterialApp(home: ExecutiveReportPage(areaId: 'western_ghats_forest')),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    });
  }
}
