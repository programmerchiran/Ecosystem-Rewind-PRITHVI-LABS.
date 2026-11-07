import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/area_model.dart';
import '../models/indicator_model.dart';
import '../models/species_model.dart';
import '../models/network_model.dart';
import '../models/domino_model.dart';
import '../models/recommendation_model.dart';
import '../models/scenario_model.dart';
import '../repositories/ecosystem_api_repository.dart';
import '../models/habitat_model.dart';

// Repository provider
final ecosystemRepoProvider = Provider<EcosystemApiRepository>((ref) {
  return ecosystemApiRepository;
});

// Currently selected area ID
class SelectedAreaIdNotifier extends Notifier<String> {
  @override
  String build() => 'western_ghats_forest';

  @override
  set state(String value) => super.state = value;
}

final selectedAreaIdProvider = NotifierProvider<SelectedAreaIdNotifier, String>(
  SelectedAreaIdNotifier.new,
);

// All available study areas
final areasListProvider = FutureProvider<List<EcosystemAreaModel>>((ref) async {
  final repo = ref.watch(ecosystemRepoProvider);
  return repo.fetchAreas();
});

// Selected area details
final selectedAreaProvider = FutureProvider<EcosystemAreaModel?>((ref) async {
  final areaId = ref.watch(selectedAreaIdProvider);
  final repo = ref.watch(ecosystemRepoProvider);
  try {
    return await repo.fetchArea(areaId);
  } catch (e) {
    return null;
  }
});

// Health Summary Provider for an area
final healthSummaryProvider = FutureProvider.family<AreaSummaryModel, String>((
  ref,
  areaId,
) async {
  final repo = ref.watch(ecosystemRepoProvider);
  return repo.fetchAreaSummary(areaId);
});

// Species List Provider
final speciesListProvider = FutureProvider.family<List<SpeciesModel>, String>((
  ref,
  areaId,
) async {
  final repo = ref.watch(ecosystemRepoProvider);
  return repo.fetchSpecies(areaId);
});

// Interactive Network Graph Provider
final networkGraphProvider = FutureProvider.family<NetworkGraphModel, String>((
  ref,
  areaId,
) async {
  final repo = ref.watch(ecosystemRepoProvider);
  return repo.fetchNetworkGraph(areaId);
});

// Recommendations Provider
final recommendationsProvider =
    FutureProvider.family<RecommendationResponseModel, String>((
      ref,
      areaId,
    ) async {
      final repo = ref.watch(ecosystemRepoProvider);
      return repo.fetchRecommendations(areaId);
    });

// Executive Report Provider
final executiveReportProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, areaId) async {
      final repo = ref.watch(ecosystemRepoProvider);
      return repo.fetchExecutiveReport(areaId);
    });

// -------------------------------------------------------------
// Domino Simulator State Notifier
// -------------------------------------------------------------
class DominoState {
  final bool isLoading;
  final String? selectedSpeciesId;
  final DominoSimulationResultModel? result;
  final String? errorMessage;

  const DominoState({
    this.isLoading = false,
    this.selectedSpeciesId,
    this.result,
    this.errorMessage,
  });

  DominoState copyWith({
    bool? isLoading,
    String? selectedSpeciesId,
    DominoSimulationResultModel? result,
    String? errorMessage,
    bool clearResult = false,
  }) {
    return DominoState(
      isLoading: isLoading ?? this.isLoading,
      selectedSpeciesId: selectedSpeciesId ?? this.selectedSpeciesId,
      result: clearResult ? null : (result ?? this.result),
      errorMessage: errorMessage,
    );
  }
}

class DominoNotifier extends Notifier<DominoState> {
  @override
  DominoState build() => const DominoState();

  void selectSpecies(String speciesId) {
    state = state.copyWith(selectedSpeciesId: speciesId, clearResult: true);
  }

  Future<void> runSimulation(String areaId, String speciesId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(ecosystemRepoProvider);
      final res = await repo.simulateSpeciesRemoval(areaId, speciesId);
      state = state.copyWith(
        isLoading: false,
        selectedSpeciesId: speciesId,
        result: res,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Simulation failed: ${e.toString()}',
      );
    }
  }

  void reset() {
    state = const DominoState();
  }
}

final dominoNotifierProvider = NotifierProvider<DominoNotifier, DominoState>(
  DominoNotifier.new,
);

// -------------------------------------------------------------
// Restoration Time Machine Scenario Notifier
// -------------------------------------------------------------
class ScenarioState {
  final bool isLoading;
  final List<String> selectedActionIds;
  final double? budget;
  final ScenarioResponseModel? result;
  final String? errorMessage;

  const ScenarioState({
    this.isLoading = false,
    this.selectedActionIds = const [],
    this.budget,
    this.result,
    this.errorMessage,
  });

  ScenarioState copyWith({
    bool? isLoading,
    List<String>? selectedActionIds,
    double? budget,
    ScenarioResponseModel? result,
    String? errorMessage,
    bool clearResult = false,
  }) {
    return ScenarioState(
      isLoading: isLoading ?? this.isLoading,
      selectedActionIds: selectedActionIds ?? this.selectedActionIds,
      budget: budget ?? this.budget,
      result: clearResult ? null : (result ?? this.result),
      errorMessage: errorMessage,
    );
  }
}

class ScenarioNotifier extends Notifier<ScenarioState> {
  @override
  ScenarioState build() => const ScenarioState();

  void toggleAction(String actionId) {
    final list = List<String>.from(state.selectedActionIds);
    if (list.contains(actionId)) {
      list.remove(actionId);
    } else {
      list.add(actionId);
    }
    state = state.copyWith(selectedActionIds: list, clearResult: true);
  }

  void setBudget(double? budget) {
    state = state.copyWith(budget: budget, clearResult: true);
  }

  Future<void> calculateScenario(String areaId) async {
    if (state.selectedActionIds.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Please select at least one restoration action.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(ecosystemRepoProvider);
      final res = await repo.calculateScenario(
        areaId,
        actionIds: state.selectedActionIds,
        budgetUsd: state.budget,
      );
      state = state.copyWith(isLoading: false, result: res);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Scenario projection failed: ${e.toString()}',
      );
    }
  }

  void reset() {
    state = const ScenarioState();
  }

}

final scenarioNotifierProvider =
    NotifierProvider<ScenarioNotifier, ScenarioState>(ScenarioNotifier.new);

// -------------------------------------------------------------
// Teak Habitat Suitability Providers
// -------------------------------------------------------------

final habitatSummaryProvider = FutureProvider<HabitatSummaryModel>((
  ref,
) async {
  final repo = ref.watch(ecosystemRepoProvider);
  return repo.fetchHabitatSummary();
});

final habitatCellsProvider =
    FutureProvider.family<HabitatCellsResponseModel, String?>(
  (ref, suitabilityClass) async {
    final repo = ref.watch(ecosystemRepoProvider);

    return repo.fetchHabitatCells(
      suitabilityClass: suitabilityClass,
      limit: 1000,
      offset: 0,
    );
  },
);

final habitatMapCellsProvider =
    FutureProvider.family<List<HabitatCellModel>, HabitatMapBounds>(
  (ref, bounds) async {
    final repo = ref.watch(ecosystemRepoProvider);

    final response = await repo.fetchHabitatCells(
      limit: 5000,
      offset: 0,
      minLat: bounds.minLat,
      maxLat: bounds.maxLat,
      minLon: bounds.minLon,
      maxLon: bounds.maxLon,
    );

    return response.cells;
  },
);

class HabitatMapBounds {
  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;

  const HabitatMapBounds({
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
  });
}