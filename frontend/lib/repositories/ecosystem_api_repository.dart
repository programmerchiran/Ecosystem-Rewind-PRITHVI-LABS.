import '../core/networking/api_client.dart';
import '../models/area_model.dart';
import '../models/indicator_model.dart';
import '../models/species_model.dart';
import '../models/network_model.dart';
import '../models/domino_model.dart';
import '../models/recommendation_model.dart';
import '../models/scenario_model.dart';
import '../models/habitat_model.dart';

class EcosystemApiRepository {
  final ApiClient client;

  EcosystemApiRepository({ApiClient? client})
    : client = client ?? defaultApiClient;

  // 1. Areas
  Future<List<EcosystemAreaModel>> fetchAreas() async {
    final response = await client.get('/areas');
    final data = response.data as List<dynamic>;
    return data.map((json) => EcosystemAreaModel.fromJson(json)).toList();
  }

  Future<EcosystemAreaModel> fetchArea(String areaId) async {
    final response = await client.get('/areas/$areaId');
    return EcosystemAreaModel.fromJson(response.data);
  }

  // 2. Health Summary
  Future<AreaSummaryModel> fetchAreaSummary(String areaId) async {
    final response = await client.get('/areas/$areaId/summary');
    return AreaSummaryModel.fromJson(response.data);
  }

  // 3. Species
  Future<List<SpeciesModel>> fetchSpecies(
    String areaId, {
    String? group,
  }) async {
    final Map<String, dynamic> query = {};
    if (group != null && group.isNotEmpty && group != 'All') {
      query['group'] = group;
    }
    final response = await client.get(
      '/areas/$areaId/species',
      queryParameters: query,
    );
    final data = response.data as List<dynamic>;
    return data.map((json) => SpeciesModel.fromJson(json)).toList();
  }

  // 4. Species Network Graph
  Future<NetworkGraphModel> fetchNetworkGraph(String areaId) async {
    final response = await client.get('/areas/$areaId/network');
    return NetworkGraphModel.fromJson(response.data);
  }

  // 5. Domino Simulator
  Future<DominoSimulationResultModel> simulateSpeciesRemoval(
    String areaId,
    String speciesId, {
    double cascadeThreshold = 0.5,
  }) async {
    final response = await client.post(
      '/areas/$areaId/simulate',
      data: {
        'species_id': speciesId,
        'propagation_depth': 2,
        'cascade_threshold': cascadeThreshold,
      },
    );
    return DominoSimulationResultModel.fromJson(response.data);
  }

  // 6. Restoration Recommendations
  Future<RecommendationResponseModel> fetchRecommendations(
    String areaId, {
    double? maxBudget,
  }) async {
    final Map<String, dynamic> query = {};
    if (maxBudget != null && maxBudget > 0) {
      query['max_budget'] = maxBudget;
    }
    final response = await client.get(
      '/areas/$areaId/recommendations',
      queryParameters: query,
    );
    return RecommendationResponseModel.fromJson(response.data);
  }

  // 7. Restoration Time Machine / Scenarios
  Future<ScenarioResponseModel> calculateScenario(
    String areaId, {
    required List<String> actionIds,
    double? budgetUsd,
    List<int>? targetYears,
  }) async {
    final response = await client.post(
      '/areas/$areaId/scenarios',
      data: {
        'scenario_name': 'Multi-Horizon Ecosystem Rewind Strategy',
        'action_ids': actionIds,
        'budget_usd': budgetUsd,
        'target_years': targetYears ?? [2030, 2040, 2045],
      },
    );
    return ScenarioResponseModel.fromJson(response.data);
  }

  // 8. Executive Report
  Future<Map<String, dynamic>> fetchExecutiveReport(String areaId) async {
    final response = await client.post('/areas/$areaId/report');
    return response.data as Map<String, dynamic>;
  }
  // 9. Teak Habitat Suitability

  Future<HabitatSummaryModel> fetchHabitatSummary() async {
    final response = await client.get('/v1/habitat/summary');

    return HabitatSummaryModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<HabitatCellsResponseModel> fetchHabitatCells({
    String? suitabilityClass,
    int limit = 1000,
    int offset = 0,
    double? minLat,
    double? maxLat,
    double? minLon,
    double? maxLon,
  }) async {
    final query = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };

    if (suitabilityClass != null && suitabilityClass.isNotEmpty) {
      query['class'] = suitabilityClass;
    }

    if (minLat != null) query['min_lat'] = minLat;
    if (maxLat != null) query['max_lat'] = maxLat;
    if (minLon != null) query['min_lon'] = minLon;
    if (maxLon != null) query['max_lon'] = maxLon;

    final response = await client.get(
      '/v1/habitat/cells',
      queryParameters: query,
    );

    return HabitatCellsResponseModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
final ecosystemApiRepository = EcosystemApiRepository();
