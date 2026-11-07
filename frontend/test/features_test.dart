import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/area_model.dart';
import 'package:frontend/models/indicator_model.dart';
import 'package:frontend/models/network_model.dart';
import 'package:frontend/models/species_model.dart';
import 'package:frontend/models/recommendation_model.dart';
import 'package:frontend/models/scenario_model.dart';
import 'package:frontend/repositories/ecosystem_api_repository.dart';
import 'package:frontend/providers/ecosystem_providers.dart';
import 'package:frontend/features/health_dashboard/health_dashboard_page.dart';
import 'package:frontend/features/recommendations/recommendations_page.dart';
import 'package:frontend/features/time_machine/time_machine_page.dart';
import 'package:frontend/features/report/executive_report_page.dart';

class StubEcosystemRepository extends EcosystemApiRepository {
  @override
  Future<List<EcosystemAreaModel>> fetchAreas() async {
    return [
      EcosystemAreaModel(
        areaId: 'western_ghats_forest',
        name: 'Western Ghats Evergreen Corridor',
        ecosystemType: 'Tropical Montane Evergreen Forest',
        centerLatitude: 11.9,
        centerLongitude: 75.8,
        areaSize: 160000,
        areaSizeUnit: 'sq km',
        datasetVersion: '1.0.0',
        dataMode: 'DEMO_DATASET',
        supportedFeatures: ['health_dashboard', 'species_network'],
        description: 'Biodiversity hotspot.',
        climateZone: 'Tropical Wet / Montane',
        vulnerabilityNotes: 'Fragmented by linear infrastructure.',
        boundaryGeojson: {
          'type': 'Polygon',
          'coordinates': [
            [
              [75.0, 11.0],
              [76.0, 11.0],
              [76.0, 12.0],
              [75.0, 12.0],
              [75.0, 11.0],
            ],
          ],
        },
      ),
    ];
  }

  @override
  Future<EcosystemAreaModel> fetchArea(String areaId) async {
    final areas = await fetchAreas();
    return areas.first;
  }

  @override
  Future<AreaSummaryModel> fetchAreaSummary(String areaId) async {
    return AreaSummaryModel(
      areaId: areaId,
      areaName: 'Western Ghats Evergreen Corridor',
      ecosystemType: 'Tropical Montane Evergreen Forest',
      overallHealthScore: 68.4,
      healthStatus: 'Vulnerable',
      scoreCalculationFormula:
          'Weighted harmonic mean of normalized indicators.',
      indicators: [
        IndicatorModel(
          indicatorId: 'ind_01',
          areaId: areaId,
          name: 'Plant Diversity Index',
          value: 72.0,
          baselineValue: 60.0,
          targetValue: 85.0,
          unit: 'Index (0-100)',
          calculationMethod: 'Shannon diversity index over 1ha plots',
          observationPeriod: '2020-2025',
          source: 'Demo Dataset',
          dataMode: 'DEMO_ILLUSTRATIVE',
          category: 'Biodiversity',
          interpretation: 'Diverse canopy with localized gaps.',
        ),
        IndicatorModel(
          indicatorId: 'ind_02',
          areaId: areaId,
          name: 'Habitat Connectivity',
          value: 54.0,
          baselineValue: 50.0,
          targetValue: 80.0,
          unit: 'Index (0-100)',
          calculationMethod: 'Graph percolation threshold',
          observationPeriod: '2020-2025',
          source: 'Demo Dataset',
          dataMode: 'DEMO_ILLUSTRATIVE',
          category: 'Connectivity',
          interpretation: 'Fragmented by road networks.',
        ),
      ],
      dataCoverage: 'High (Documented Demo Baseline)',
      datasetVersion: '1.0.0',
      observationPeriod: '2020-2025',
      methodologyLimitations: ['Illustrative baseline values.'],
    );
  }

  @override
  Future<List<SpeciesModel>> fetchSpecies(
    String areaId, {
    String? group,
  }) async {
    return [
      SpeciesModel(
        speciesId: 'wg_sp_01',
        areaId: areaId,
        scientificName: 'Buceros bicornis',
        commonName: 'Great Hornbill',
        group: 'Birds',
        description: 'Crucial seed disperser for heavy seeds.',
        observationStatus: 'Vulnerable',
        trophicLevel: 'Frugivore',
        source: 'Demo Survey Data',
        dataMode: 'DEMO_ILLUSTRATIVE',
        populationTrend: 'Decreasing',
        dependencyCriticality: 0.85,
      ),
    ];
  }

  @override
  Future<NetworkGraphModel> fetchNetworkGraph(String areaId) async {
    return NetworkGraphModel(
      areaId: areaId,
      ecosystemName: 'Western Ghats Corridor',
      nodes: [
        NetworkNodeModel(
          id: 'wg_sp_01',
          label: 'Great Hornbill',
          scientificName: 'Buceros bicornis',
          group: 'Birds',
          status: 'VU',
          trophicLevel: 'Frugivore',
          degree: 8,
          inDegree: 4,
          outDegree: 4,
          pagerank: 0.12,
          betweenness: 0.25,
          isKeystone: true,
          description: 'Key seed disperser.',
        ),
      ],
      edges: [],
      metrics: NetworkMetricsModel(
        totalNodes: 1,
        totalEdges: 0,
        graphDensity: 0.1,
        averageClustering: 0.2,
        connectedComponents: 1,
      ),
      groups: ['Birds', 'Plants'],
      interactionTypes: ['mutualism_pollination', 'seed_dispersal'],
    );
  }

  @override
  Future<RecommendationResponseModel> fetchRecommendations(
    String areaId, {
    double? maxBudget,
  }) async {
    return RecommendationResponseModel(
      areaId: areaId,
      ecosystemName: 'Western Ghats Corridor',
      totalRecommendations: 1,
      recommendations: [
        RestorationActionModel(
          actionId: 'act_01',
          name: 'Canopy Bridge Corridor Installation',
          description: 'Construct arboreal crossings to restore connectivity.',
          applicableEcosystemTypes: ['Tropical Montane Evergreen Forest'],
          targetProblems: ['Canopy Fragmentation', 'Road Mortality'],
          problemAddressed: 'Canopy Fragmentation',
          urgencyLevel: 'High',
          costEstimateUsd: 12000,
          costUnit: 'USD/bridge',
          totalEstimatedBudgetUsd: 96000,
          feasibilityNotes: 'High community support.',
          beneficiarySpecies: ['Lion-tailed Macaque', 'Nilgiri Langur'],
          impactAssumptions: {'habitat_connectivity': 18.0},
          rankingScore: 92.5,
          rankingFactors: ['High connectivity deficit', 'Cost efficient'],
          source: 'Demo Restoration Matrix',
          dataMode: 'DEMO_ILLUSTRATIVE',
        ),
      ],
      rankingMethodology: 'Rule-based multi-criteria scoring.',
      limitationsAndAssumptions: ['Cost figures are illustrative benchmarks.'],
    );
  }

  @override
  Future<ScenarioResponseModel> calculateScenario(
    String areaId, {
    required List<String> actionIds,
    double? budgetUsd,
    List<int>? targetYears,
  }) async {
    final points = [
      YearPointModel(
        year: 2025,
        overallHealth: 68.4,
        plantDiversity: 72.0,
        habitatConnectivity: 54.0,
        pollinatorNetwork: 65.0,
        birdNetwork: 68.0,
      ),
      YearPointModel(
        year: 2030,
        overallHealth: 74.0,
        plantDiversity: 76.0,
        habitatConnectivity: 64.0,
        pollinatorNetwork: 70.0,
        birdNetwork: 73.0,
      ),
      YearPointModel(
        year: 2040,
        overallHealth: 82.0,
        plantDiversity: 82.0,
        habitatConnectivity: 78.0,
        pollinatorNetwork: 79.0,
        birdNetwork: 81.0,
      ),
      YearPointModel(
        year: 2045,
        overallHealth: 86.8,
        plantDiversity: 86.0,
        habitatConnectivity: 84.0,
        pollinatorNetwork: 83.0,
        birdNetwork: 85.0,
      ),
    ];

    return ScenarioResponseModel(
      areaId: areaId,
      ecosystemName: 'Western Ghats Corridor',
      scenarioName: 'Test Scenario',
      selectedActions: [],
      totalBudgetUsd: 96000,
      baselineTrajectory: ScenarioTrajectoryModel(
        scenarioType: 'baseline',
        label: 'Baseline Degradation',
        description: 'Business as usual.',
        projections: points,
      ),
      restorationTrajectory: ScenarioTrajectoryModel(
        scenarioType: 'restoration',
        label: 'Active Restoration Intervention',
        description: 'Targeted actions applied.',
        projections: points,
      ),
      netImprovement2045: {
        'overall_health_delta': 18.4,
        'habitat_connectivity_delta': 30.0,
      },
      assumptionsAndLimitations: ['Deterministic illustrative curves.'],
    );
  }

  @override
  Future<Map<String, dynamic>> fetchExecutiveReport(String areaId) async {
    return {
      'area_id': areaId,
      'area_name': 'Western Ghats Corridor',
      'generated_at': '2026-10-26T12:00:00Z',
      'markdown_content':
          '# PRITHVI LABS REPORT\n## Executive Summary\nTest report content.',
      'key_metrics_summary': {
        'overall_health': 68.4,
        'health_status': 'Vulnerable',
        'total_indicators': 5,
      },
    };
  }
}

void main() {
  final stubRepo = StubEcosystemRepository();

  testWidgets('Health Dashboard renders indicators and scores', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [ecosystemRepoProvider.overrideWithValue(stubRepo)],
        child: const MaterialApp(
          home: HealthDashboardPage(areaId: 'western_ghats_forest'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Western Ghats Evergreen Corridor'), findsOneWidget);
    expect(find.text('Plant Diversity Index'), findsOneWidget);
    expect(find.text('Habitat Connectivity'), findsWidgets);
  });

  testWidgets('Recommendations Page renders action cards and urgency badges', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [ecosystemRepoProvider.overrideWithValue(stubRepo)],
        child: const MaterialApp(
          home: RecommendationsPage(areaId: 'western_ghats_forest'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Canopy Bridge Corridor Installation'), findsWidgets);
    expect(find.text('HIGH URGENCY'), findsOneWidget);
    expect(find.text('Add to Time Machine'), findsOneWidget);
  });

  testWidgets('Time Machine Page renders scenario options', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [ecosystemRepoProvider.overrideWithValue(stubRepo)],
        child: const MaterialApp(
          home: TimeMachinePage(areaId: 'western_ghats_forest'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Restoration Time Machine'), findsOneWidget);
    expect(find.text('Run Projection'), findsOneWidget);
  });

  testWidgets('Executive Report Page renders markdown document', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [ecosystemRepoProvider.overrideWithValue(stubRepo)],
        child: const MaterialApp(
          home: ExecutiveReportPage(areaId: 'western_ghats_forest'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PRITHVI LABS'), findsOneWidget);
    expect(find.text('Executive Summary'), findsOneWidget);
    expect(find.text('Copy Markdown'), findsOneWidget);
  });
}
