// ignore_for_file: avoid_redundant_argument_values

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/models/area_model.dart';
import 'package:frontend/models/species_model.dart';
import 'package:frontend/models/network_model.dart';
import 'package:frontend/models/domino_model.dart';
import 'package:frontend/repositories/ecosystem_api_repository.dart';
import 'package:frontend/providers/ecosystem_providers.dart';
import 'package:frontend/features/area_selection/area_selection_page.dart';
import 'package:frontend/features/ecosystem_network/ecosystem_network_page.dart';
import 'package:frontend/features/ecosystem_network/species_details_sheet.dart';
import 'package:frontend/features/domino_simulator/domino_simulator_page.dart';

// ---------------------------------------------------------------------------
// Shared minimal stub data
// ---------------------------------------------------------------------------

final _westernGhats = EcosystemAreaModel(
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
  description: 'Biodiversity hotspot in the southern Western Ghats.',
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
);

final _sundarbans = EcosystemAreaModel(
  areaId: 'sundarbans_wetland',
  name: 'Sundarbans Mangrove Delta',
  ecosystemType: 'Mangrove Tidal Wetland',
  centerLatitude: 21.9,
  centerLongitude: 89.1,
  areaSize: 10200,
  areaSizeUnit: 'sq km',
  datasetVersion: '1.0.0',
  dataMode: 'DEMO_DATASET',
  supportedFeatures: ['health_dashboard', 'species_network'],
  description: 'World\'s largest mangrove forest and UNESCO World Heritage Site.',
  climateZone: 'Tropical Humid / Tidal',
  vulnerabilityNotes: 'Threatened by cyclone surges and salinity intrusion.',
  boundaryGeojson: {
    'type': 'Polygon',
    'coordinates': [
      [
        [88.0, 21.0],
        [90.0, 21.0],
        [90.0, 23.0],
        [88.0, 23.0],
        [88.0, 21.0],
      ],
    ],
  },
);

final _hornbillSpecies = SpeciesModel(
  speciesId: 'wg_sp_01',
  areaId: 'western_ghats_forest',
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
);

final _frogSpecies = SpeciesModel(
  speciesId: 'wg_sp_02',
  areaId: 'western_ghats_forest',
  scientificName: 'Nyctibatrachus major',
  commonName: 'Malabar Night Frog',
  group: 'Amphibians',
  description: 'Indicator species for stream health.',
  observationStatus: 'Endangered',
  trophicLevel: 'Insectivore',
  source: 'Demo Survey Data',
  dataMode: 'DEMO_ILLUSTRATIVE',
  populationTrend: 'Decreasing',
  dependencyCriticality: 0.62,
);

final _stubNetworkGraph = NetworkGraphModel(
  areaId: 'western_ghats_forest',
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
    NetworkNodeModel(
      id: 'wg_sp_02',
      label: 'Malabar Night Frog',
      scientificName: 'Nyctibatrachus major',
      group: 'Amphibians',
      status: 'EN',
      trophicLevel: 'Insectivore',
      degree: 4,
      inDegree: 2,
      outDegree: 2,
      pagerank: 0.07,
      betweenness: 0.10,
      isKeystone: false,
      description: 'Stream health indicator.',
    ),
  ],
  edges: [
    NetworkEdgeModel(
      id: 'wg_edge_01',
      source: 'wg_sp_01',
      target: 'wg_sp_02',
      interactionType: 'food_web',
      strength: 0.6,
      dependencyWeight: 0.6,
      direction: 'directed',
    ),
  ],
  metrics: NetworkMetricsModel(
    totalNodes: 2,
    totalEdges: 1,
    graphDensity: 0.5,
    averageClustering: 0.3,
    connectedComponents: 1,
  ),
  groups: ['Birds', 'Amphibians'],
  interactionTypes: ['food_web'],
);

DominoSimulationResultModel _buildDominoResult() {
  final beforeMetrics = NetworkMetricsModel(
    totalNodes: 2,
    totalEdges: 1,
    graphDensity: 0.5,
    averageClustering: 0.3,
    connectedComponents: 1,
  );
  final afterMetrics = NetworkMetricsModel(
    totalNodes: 1,
    totalEdges: 0,
    graphDensity: 0.0,
    averageClustering: 0.0,
    connectedComponents: 1,
  );
  final modifiedNetwork = NetworkGraphModel(
    areaId: 'western_ghats_forest',
    ecosystemName: 'Western Ghats Corridor (Simulated)',
    nodes: [
      NetworkNodeModel(
        id: 'wg_sp_02',
        label: 'Malabar Night Frog',
        scientificName: 'Nyctibatrachus major',
        group: 'Amphibians',
        status: 'EN',
        trophicLevel: 'Insectivore',
        degree: 0,
        inDegree: 0,
        outDegree: 0,
        pagerank: 0.0,
        betweenness: 0.0,
        isKeystone: false,
        description: 'Now isolated.',
      ),
    ],
    edges: [],
    metrics: afterMetrics,
    groups: ['Amphibians'],
    interactionTypes: [],
  );
  return DominoSimulationResultModel(
    areaId: 'western_ghats_forest',
    removedSpecies: _hornbillSpecies,
    directRelationshipsRemoved: 1,
    potentiallyAffectedSpecies: [
      AffectedNodeInfoModel(
        speciesId: 'wg_sp_02',
        commonName: 'Malabar Night Frog',
        scientificName: 'Nyctibatrachus major',
        group: 'Amphibians',
        impactLevel: 'High',
        impactRationale: 'Loss of key food-web link from Great Hornbill.',
        lostDependencies: ['wg_sp_01'],
      ),
    ],
    isolatedSpecies: ['Malabar Night Frog'],
    dominoImpactScore: 74.5,
    beforeMetrics: beforeMetrics,
    afterMetrics: afterMetrics,
    appliedRulesAndAssumptions: [
      'NetworkX deepcopy isolation prevents modification of master graph.',
      'All direct edges of removed node are deleted in simulation copy.',
    ],
    explanation:
        'Removal of Great Hornbill severs critical seed-dispersal pathways, '
        'causing downstream trophic collapse.',
    modifiedNetwork: modifiedNetwork,
  );
}

// ---------------------------------------------------------------------------
// Comprehensive stub repository for all three new features
// ---------------------------------------------------------------------------

class _NewFeaturesStubRepository extends EcosystemApiRepository {
  final bool throwOnFetchAreas;
  final bool throwOnFetchSpecies;
  final bool throwOnFetchNetwork;
  final bool throwOnSimulate;

  _NewFeaturesStubRepository({
    this.throwOnFetchAreas = false,
    this.throwOnFetchSpecies = false,
    this.throwOnFetchNetwork = false,
    this.throwOnSimulate = false,
  });

  @override
  Future<List<EcosystemAreaModel>> fetchAreas() async {
    if (throwOnFetchAreas) throw Exception('Network unavailable');
    return [_westernGhats, _sundarbans];
  }

  @override
  Future<EcosystemAreaModel> fetchArea(String areaId) async {
    return areaId == 'sundarbans_wetland' ? _sundarbans : _westernGhats;
  }

  @override
  Future<List<SpeciesModel>> fetchSpecies(
    String areaId, {
    String? group,
  }) async {
    if (throwOnFetchSpecies) throw Exception('Species data unavailable');
    return [_hornbillSpecies, _frogSpecies];
  }

  @override
  Future<NetworkGraphModel> fetchNetworkGraph(String areaId) async {
    if (throwOnFetchNetwork) throw Exception('Graph database unavailable');
    return _stubNetworkGraph;
  }

  @override
  Future<DominoSimulationResultModel> simulateSpeciesRemoval(
    String areaId,
    String speciesId, {
    double cascadeThreshold = 0.5,
  }) async {
    if (throwOnSimulate) throw Exception('Simulation service error');
    return _buildDominoResult();
  }
}

// Convenience widget wrapper: wraps a page in MaterialApp + ProviderScope
// with the stub repo override and a fixed 1280×800 viewport.
Widget _wrapPage(
  Widget page,
  EcosystemApiRepository stub,
) {
  return ProviderScope(
    overrides: [
      ecosystemRepoProvider.overrideWithValue(stub),
    ],
    child: MaterialApp(home: page),
  );
}

// ===========================================================================
// AREA SELECTION PAGE TESTS
// ===========================================================================

void main() {
  group('AreaSelectionPage', () {
    testWidgets(
      'renders app bar title and search field on desktop',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          _wrapPage(
            const AreaSelectionPage(),
            _NewFeaturesStubRepository(),
          ),
        );
        await tester.pumpAndSettle();

        // App bar title
        expect(find.text('Select Study Ecosystem'), findsOneWidget);
        // Back to Home action button
        expect(find.text('Back to Home'), findsOneWidget);
        // Search field hint
        expect(
          find.text('Search study areas or ecosystem types...'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'displays both demo study areas in the sidebar panel',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          _wrapPage(
            const AreaSelectionPage(),
            _NewFeaturesStubRepository(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Western Ghats Evergreen Corridor'), findsWidgets);
        expect(find.text('Sundarbans Mangrove Delta'), findsOneWidget);
        // Section label
        expect(
          find.text('SUPPORTED STUDY AREAS (2 DEMO ECOSYSTEMS)'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows ecosystem type subtitles for each study area',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          _wrapPage(
            const AreaSelectionPage(),
            _NewFeaturesStubRepository(),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Tropical Montane Evergreen Forest'),
          findsWidgets,
        );
        expect(find.text('Mangrove Tidal Wetland'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping a study area card selects it and shows its detail info',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          _wrapPage(
            const AreaSelectionPage(),
            _NewFeaturesStubRepository(),
          ),
        );
        await tester.pumpAndSettle();

        // Tap the Sundarbans card
        await tester.tap(find.text('Sundarbans Mangrove Delta'));
        await tester.pumpAndSettle();

        // The detail panel now shows Sundarbans name and its description
        expect(find.text('Sundarbans Mangrove Delta'), findsWidgets);
        expect(find.textContaining('World\'s largest mangrove'), findsOneWidget);
      },
    );

    testWidgets(
      'Analyze This Area button is present for the selected area',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          _wrapPage(
            const AreaSelectionPage(),
            _NewFeaturesStubRepository(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Analyze This Area'), findsOneWidget);
      },
    );

    testWidgets(
      'shows loading indicator while areas are being fetched',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        // Use a slow-resolving stub by delaying via FutureProvider override
        final stub = _SlowAreaStubRepository();
        await tester.pumpWidget(
          _wrapPage(const AreaSelectionPage(), stub),
        );
        // Only pump one frame — don't settle, so loading state is visible
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(
          find.text('Loading ecosystem boundaries and spatial registers...'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows error display when fetching areas fails',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final stub = _NewFeaturesStubRepository(throwOnFetchAreas: true);
        await tester.pumpWidget(
          _wrapPage(const AreaSelectionPage(), stub),
        );
        await tester.pumpAndSettle();

        expect(find.text('Failed to Load Study Areas'), findsOneWidget);
        expect(find.textContaining('Network unavailable'), findsOneWidget);
      },
    );

    testWidgets(
      'DATA COVERAGE badge is shown in the selected area detail panel',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          _wrapPage(
            const AreaSelectionPage(),
            _NewFeaturesStubRepository(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('DATA COVERAGE: COMPLETE'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Analyze This Area navigates to workspace dashboard route and preserves selected area',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer(
          overrides: [
            ecosystemRepoProvider.overrideWithValue(_NewFeaturesStubRepository()),
          ],
        );
        addTearDown(container.dispose);

        final router = GoRouter(
          initialLocation: '/areas',
          routes: [
            GoRoute(
              path: '/areas',
              builder: (context, state) => const AreaSelectionPage(),
            ),
            GoRoute(
              path: '/workspace/:areaId/dashboard',
              builder: (context, state) {
                final areaId = state.pathParameters['areaId'] ?? '';
                return Scaffold(
                  body: Text('Workspace Dashboard for: $areaId'),
                );
              },
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Verify page renders with supported ecosystem data
        expect(find.text('Select Study Ecosystem'), findsOneWidget);
        expect(find.text('Sundarbans Mangrove Delta'), findsOneWidget);

        // 2. Select a supported study area (Sundarbans)
        await tester.tap(find.text('Sundarbans Mangrove Delta'));
        await tester.pumpAndSettle();

        // 3. Click the "Analyze This Area" button
        final analyzeButton = find.widgetWithText(
          ElevatedButton,
          'Analyze This Area',
        );
        expect(analyzeButton, findsOneWidget);
        await tester.tap(analyzeButton);
        await tester.pumpAndSettle();

        // 4. Verify application navigated to the correct workspace dashboard route with selected area ID
        expect(
          find.text('Workspace Dashboard for: sundarbans_wetland'),
          findsOneWidget,
        );

        // 5. Verify the selected area state is preserved after navigation
        expect(container.read(selectedAreaIdProvider), 'sundarbans_wetland');
      },
    );
  });

  // ==========================================================================
  // ECOSYSTEM NETWORK PAGE TESTS
  // ==========================================================================

  group('EcosystemNetworkPage', () {
    testWidgets(
      'renders the network scaffold and INTERACTION LEGEND',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          _wrapPage(
            const EcosystemNetworkPage(areaId: 'western_ghats_forest'),
            _NewFeaturesStubRepository(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('INTERACTION LEGEND'), findsOneWidget);
      },
    );

    testWidgets(
      'displays node count and edge count in metric pills',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          _wrapPage(
            const EcosystemNetworkPage(areaId: 'western_ghats_forest'),
            _NewFeaturesStubRepository(),
          ),
        );
        await tester.pumpAndSettle();

        // The metric pills show "Nodes: 2" and "Interactions: 1"
        expect(find.textContaining('Nodes:'), findsOneWidget);
        expect(find.text('2'), findsWidgets); // node count value
        expect(find.textContaining('Interactions:'), findsOneWidget);
      },
    );

    testWidgets(
      'renders "All" filter chip along with group-specific chips',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          _wrapPage(
            const EcosystemNetworkPage(areaId: 'western_ghats_forest'),
            _NewFeaturesStubRepository(),
          ),
        );
        await tester.pumpAndSettle();

        // FilterChips for groups
        expect(find.text('All'), findsOneWidget);
        expect(find.text('Birds'), findsOneWidget);
        expect(find.text('Amphibians'), findsOneWidget);
      },
    );

    testWidgets(
      'renders legend interaction type labels',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          _wrapPage(
            const EcosystemNetworkPage(areaId: 'western_ghats_forest'),
            _NewFeaturesStubRepository(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Pollination'), findsOneWidget);
        expect(find.text('Seed Dispersal'), findsOneWidget);
        expect(find.text('Food Web'), findsOneWidget);
        expect(find.text('Habitat Dependency'), findsOneWidget);
        expect(find.text('Symbiosis'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping a group filter chip updates selection state without error',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          _wrapPage(
            const EcosystemNetworkPage(areaId: 'western_ghats_forest'),
            _NewFeaturesStubRepository(),
          ),
        );
        await tester.pumpAndSettle();

        // Tap the 'Birds' filter chip
        await tester.tap(find.text('Birds'));
        await tester.pumpAndSettle();

        // No exception and page still renders correctly
        expect(tester.takeException(), isNull);
        expect(find.text('INTERACTION LEGEND'), findsOneWidget);
      },
    );

    testWidgets(
      'search field is present and accepts input without error',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          _wrapPage(
            const EcosystemNetworkPage(areaId: 'western_ghats_forest'),
            _NewFeaturesStubRepository(),
          ),
        );
        await tester.pumpAndSettle();

        final searchField = find.widgetWithText(
          TextField,
          'Search species or component...',
        );
        expect(searchField, findsOneWidget);

        await tester.enterText(searchField, 'Hornbill');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'shows loading indicator while network graph is fetching',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final stub = _SlowNetworkStubRepository();
        await tester.pumpWidget(
          _wrapPage(
            const EcosystemNetworkPage(areaId: 'western_ghats_forest'),
            stub,
          ),
        );
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(
          find.text(
            'Building species interaction network from graph database...',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows error display when the network graph fails to load',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final stub = _NewFeaturesStubRepository(throwOnFetchNetwork: true);
        await tester.pumpWidget(
          _wrapPage(
            const EcosystemNetworkPage(areaId: 'western_ghats_forest'),
            stub,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Network Graph Unavailable'), findsOneWidget);
        expect(find.textContaining('Graph database unavailable'), findsOneWidget);
      },
    );

    testWidgets(
      'density and clustering metric pills display formatted values',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          _wrapPage(
            const EcosystemNetworkPage(areaId: 'western_ghats_forest'),
            _NewFeaturesStubRepository(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Density:'), findsOneWidget);
        expect(find.textContaining('Clustering:'), findsOneWidget);
        // Formatted to 2 decimal places from stub data
        expect(find.text('0.50'), findsOneWidget); // graphDensity
        expect(find.text('0.30'), findsOneWidget); // averageClustering
      },
    );
  });

  // ==========================================================================
  // DOMINO SIMULATOR PAGE TESTS
  // ==========================================================================

  group('DominoSimulatorPage', () {
    testWidgets(
      'renders header title and subtitle before any selection',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          _wrapPage(
            const DominoSimulatorPage(areaId: 'western_ghats_forest'),
            _NewFeaturesStubRepository(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Ecological Domino Simulator'), findsOneWidget);
        expect(
          find.textContaining('NetworkX-backed dependency cascade'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows species dropdown hint and disabled Simulate Removal button '
      'when no species is selected',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          _wrapPage(
            const DominoSimulatorPage(areaId: 'western_ghats_forest'),
            _NewFeaturesStubRepository(),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Choose a species or component to remove...'),
          findsOneWidget,
        );
        expect(find.text('Simulate Removal'), findsOneWidget);

        // Button is disabled when no species is selected
        final button = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Simulate Removal'),
        );
        expect(button.onPressed, isNull);
      },
    );

    testWidgets(
      'shows empty state prompt with Quick Select action before simulation',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          _wrapPage(
            const DominoSimulatorPage(areaId: 'western_ghats_forest'),
            _NewFeaturesStubRepository(),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Select a Keystone Species to Simulate Removal'),
          findsOneWidget,
        );
        expect(find.text('Quick Select Keystone Tree'), findsOneWidget);
      },
    );

    testWidgets(
      'triggering Quick Select runs simulation and shows results',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          _wrapPage(
            const DominoSimulatorPage(areaId: 'western_ghats_forest'),
            _NewFeaturesStubRepository(),
          ),
        );
        await tester.pumpAndSettle();

        // Tap the quick-select action
        await tester.tap(find.text('Quick Select Keystone Tree'));
        await tester.pumpAndSettle();

        // After simulation completes, the shock hero card should appear
        expect(find.text('DOMINO IMPACT SHOCK'), findsOneWidget);
        // The removed species name appears in the result
        expect(find.textContaining('Removed: Great Hornbill'), findsOneWidget);
      },
    );

    testWidgets(
      'simulation results show Before vs After network metrics',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          _wrapPage(
            const DominoSimulatorPage(areaId: 'western_ghats_forest'),
            _NewFeaturesStubRepository(),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Quick Select Keystone Tree'));
        await tester.pumpAndSettle();

        // The metrics comparison card
        expect(
          find.text(
            'Structural Network Degradation (Master Baseline vs. Simulated Copy)',
          ),
          findsOneWidget,
        );
        expect(find.text('Active Species'), findsOneWidget);
        expect(find.text('Ecological Edges'), findsOneWidget);
      },
    );

    testWidgets(
      'simulation results show affected species with impact level',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          _wrapPage(
            const DominoSimulatorPage(areaId: 'western_ghats_forest'),
            _NewFeaturesStubRepository(),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Quick Select Keystone Tree'));
        await tester.pumpAndSettle();

        // Affected species section
        expect(
          find.textContaining('Directly Impacted'),
          findsOneWidget,
        );
        expect(find.text('HIGH'), findsOneWidget);
        expect(
          find.textContaining('Malabar Night Frog'),
          findsWidgets,
        );
      },
    );

    testWidgets(
      'simulation results show applied rules and assumptions card',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          _wrapPage(
            const DominoSimulatorPage(areaId: 'western_ghats_forest'),
            _NewFeaturesStubRepository(),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Quick Select Keystone Tree'));
        await tester.pumpAndSettle();

        expect(
          find.text('Documented Dependency Rules Applied in Simulation'),
          findsOneWidget,
        );
        expect(
          find.textContaining('NetworkX deepcopy isolation'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Reset button appears after simulation and clears results when tapped',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          _wrapPage(
            const DominoSimulatorPage(areaId: 'western_ghats_forest'),
            _NewFeaturesStubRepository(),
          ),
        );
        await tester.pumpAndSettle();

        // Run simulation
        await tester.tap(find.text('Quick Select Keystone Tree'));
        await tester.pumpAndSettle();

        // Reset button should now be visible
        expect(find.text('Reset'), findsOneWidget);
        await tester.tap(find.text('Reset'));
        await tester.pumpAndSettle();

        // Empty state is restored
        expect(
          find.text('Select a Keystone Species to Simulate Removal'),
          findsOneWidget,
        );
        expect(find.text('DOMINO IMPACT SHOCK'), findsNothing);
      },
    );

    testWidgets(
      'shows error display when simulation fails',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final stub = _NewFeaturesStubRepository(throwOnSimulate: true);
        await tester.pumpWidget(
          _wrapPage(
            const DominoSimulatorPage(areaId: 'western_ghats_forest'),
            stub,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Quick Select Keystone Tree'));
        await tester.pumpAndSettle();

        expect(find.text('Simulation Error'), findsOneWidget);
        expect(
          find.textContaining('Simulation failed'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows error when species list cannot be loaded',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final stub = _NewFeaturesStubRepository(throwOnFetchSpecies: true);
        await tester.pumpWidget(
          _wrapPage(
            const DominoSimulatorPage(areaId: 'western_ghats_forest'),
            stub,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Unable to Load Species Catalog'), findsOneWidget);
        expect(find.textContaining('Species data unavailable'), findsOneWidget);
      },
    );

    testWidgets(
      'Domino impact score is displayed in the shock hero card',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          _wrapPage(
            const DominoSimulatorPage(areaId: 'western_ghats_forest'),
            _NewFeaturesStubRepository(),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Quick Select Keystone Tree'));
        await tester.pumpAndSettle();

        // Score value from stub: 74.5 → formatted as "74.5"
        expect(find.text('74.5'), findsOneWidget);
      },
    );
  });

  // ==========================================================================
  // SPECIES DETAILS SHEET TESTS
  // ==========================================================================

  group('SpeciesDetailsSheet', () {
    testWidgets(
      'renders species name, status, taxa, metrics, and incident relationships correctly',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        bool closed = false;
        String? selectedNeighborId;

        final node = _stubNetworkGraph.nodes.first; // Great Hornbill
        final incidentEdge = _stubNetworkGraph.edges.first;
        final allNodesMap = {
          for (final n in _stubNetworkGraph.nodes) n.id: n,
        };

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  height: 700,
                  width: 380,
                  child: SpeciesDetailsSheet(
                    node: node,
                    incidentEdges: [incidentEdge],
                    allNodesMap: allNodesMap,
                    onClose: () => closed = true,
                    onSelectNeighbor: (id) => selectedNeighborId = id,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Verify species title, scientific name, and description
        expect(find.text('Great Hornbill'), findsOneWidget);
        expect(find.text('Buceros bicornis'), findsOneWidget);
        expect(find.text('Key seed disperser.'), findsOneWidget);

        // 2. Verify status badge, taxa group, and trophic level
        expect(find.text('VU'), findsOneWidget);
        expect(find.text('Taxa: Birds'), findsOneWidget);
        expect(find.text('Frugivore'), findsOneWidget);

        // 3. Verify Centrality & Network Metrics
        expect(find.text('Centrality & Network Metrics'), findsOneWidget);
        expect(find.text('8'), findsOneWidget); // Total Degree
        expect(find.text('0.120'), findsOneWidget); // PageRank formatted (0.12)
        expect(find.text('0.250'), findsOneWidget); // Betweenness formatted (0.25)

        // 4. Verify incident ecological relationships
        expect(
          find.text('Known Ecological Relationships (1)'),
          findsOneWidget,
        );
        expect(find.text('Malabar Night Frog'), findsOneWidget);
        expect(
          find.textContaining('FOOD_WEB • Weight: 0.6'),
          findsOneWidget,
        );

        // 5. Test interaction: tap neighbor
        await tester.tap(find.text('Malabar Night Frog'));
        await tester.pumpAndSettle();
        expect(selectedNeighborId, 'wg_sp_02');

        // 6. Test interaction: tap close icon button
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
        expect(closed, isTrue);
      },
    );

    testWidgets(
      'renders gracefully with empty or sparse fields without throwing exceptions',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final sparseNode = NetworkNodeModel(
          id: 'sp_sparse',
          label: 'Sparse Lichen',
          scientificName: 'Parmotrema tinctorum',
          group: 'Lichens',
          status: 'NE',
          trophicLevel: 'Epiphyte',
          degree: 0,
          inDegree: 0,
          outDegree: 0,
          pagerank: 0.0,
          betweenness: 0.0,
          isKeystone: false,
          description: '',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  height: 700,
                  width: 380,
                  child: SpeciesDetailsSheet(
                    node: sparseNode,
                    incidentEdges: const [],
                    allNodesMap: const {},
                    onClose: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Sparse Lichen'), findsOneWidget);
        expect(find.text('Parmotrema tinctorum'), findsOneWidget);
        expect(find.text('Taxa: Lichens'), findsOneWidget);
        expect(find.text('Epiphyte'), findsOneWidget);
        expect(find.text('NE'), findsOneWidget);
        expect(
          find.text('Known Ecological Relationships (0)'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  });

  // ==========================================================================
  // ECOSYSTEM SWITCHING & STATE ISOLATION TESTS
  // ==========================================================================

  group('Ecosystem Switching & State Isolation', () {
    testWidgets(
      'DominoSimulatorPage resets simulation result and selection when areaId changes',
      (tester) async {
        final stub = _NewFeaturesStubRepository();
        final container = ProviderContainer(
          overrides: [
            ecosystemRepoProvider.overrideWithValue(stub),
          ],
        );
        addTearDown(container.dispose);

        // 1. Initial build with Western Ghats
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: DominoSimulatorPage(areaId: 'western_ghats_forest'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Run simulation via quick select
        await tester.tap(find.text('Quick Select Keystone Tree'));
        await tester.pumpAndSettle();

        // Verify simulation results are displayed
        expect(find.text('DOMINO IMPACT SHOCK'), findsOneWidget);
        expect(container.read(dominoNotifierProvider).result, isNotNull);

        // 2. Switch area to Sundarbans Wetland
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: DominoSimulatorPage(areaId: 'sundarbans_wetland'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 3. Verify old simulation results are cleared and empty state prompt returns
        expect(find.text('DOMINO IMPACT SHOCK'), findsNothing);
        expect(
          find.text('Select a Keystone Species to Simulate Removal'),
          findsOneWidget,
        );
        expect(container.read(dominoNotifierProvider).result, isNull);
      },
    );
  });
}

// ---------------------------------------------------------------------------
// Slow-resolving stubs that never complete during the test frame pump
// (used to test loading states)
// ---------------------------------------------------------------------------

class _SlowAreaStubRepository extends EcosystemApiRepository {
  @override
  Future<List<EcosystemAreaModel>> fetchAreas() {
    return Completer<List<EcosystemAreaModel>>().future;
  }
}

class _SlowNetworkStubRepository extends EcosystemApiRepository {
  @override
  Future<NetworkGraphModel> fetchNetworkGraph(String areaId) {
    return Completer<NetworkGraphModel>().future;
  }
}

