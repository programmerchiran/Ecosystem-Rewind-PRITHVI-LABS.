import 'recommendation_model.dart';

class YearPointModel {
  final int year;
  final double overallHealth;
  final double plantDiversity;
  final double habitatConnectivity;
  final double pollinatorNetwork;
  final double birdNetwork;

  YearPointModel({
    required this.year,
    required this.overallHealth,
    required this.plantDiversity,
    required this.habitatConnectivity,
    required this.pollinatorNetwork,
    required this.birdNetwork,
  });

  factory YearPointModel.fromJson(Map<String, dynamic> json) {
    return YearPointModel(
      year: (json['year'] as num?)?.toInt() ?? 2025,
      overallHealth: (json['overall_health'] as num?)?.toDouble() ?? 0.0,
      plantDiversity: (json['plant_diversity'] as num?)?.toDouble() ?? 0.0,
      habitatConnectivity:
          (json['habitat_connectivity'] as num?)?.toDouble() ?? 0.0,
      pollinatorNetwork:
          (json['pollinator_network'] as num?)?.toDouble() ?? 0.0,
      birdNetwork: (json['bird_network'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ScenarioTrajectoryModel {
  final String scenarioType;
  final String label;
  final String description;
  final List<YearPointModel> projections;

  ScenarioTrajectoryModel({
    required this.scenarioType,
    required this.label,
    required this.description,
    required this.projections,
  });

  factory ScenarioTrajectoryModel.fromJson(Map<String, dynamic> json) {
    return ScenarioTrajectoryModel(
      scenarioType: json['scenario_type'] ?? 'baseline',
      label: json['label'] ?? '',
      description: json['description'] ?? '',
      projections:
          (json['projections'] as List<dynamic>?)
              ?.map((e) => YearPointModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class ScenarioResponseModel {
  final String areaId;
  final String ecosystemName;
  final String scenarioName;
  final List<RestorationActionModel> selectedActions;
  final double totalBudgetUsd;
  final ScenarioTrajectoryModel baselineTrajectory;
  final ScenarioTrajectoryModel restorationTrajectory;
  final Map<String, double> netImprovement2045;
  final List<String> assumptionsAndLimitations;

  ScenarioResponseModel({
    required this.areaId,
    required this.ecosystemName,
    required this.scenarioName,
    required this.selectedActions,
    required this.totalBudgetUsd,
    required this.baselineTrajectory,
    required this.restorationTrajectory,
    required this.netImprovement2045,
    required this.assumptionsAndLimitations,
  });

  factory ScenarioResponseModel.fromJson(Map<String, dynamic> json) {
    final Map<String, double> deltas = {};
    if (json['net_improvement_2045'] is Map) {
      (json['net_improvement_2045'] as Map).forEach((k, v) {
        deltas[k.toString()] = (v as num).toDouble();
      });
    }

    return ScenarioResponseModel(
      areaId: json['area_id'] ?? '',
      ecosystemName: json['ecosystem_name'] ?? '',
      scenarioName: json['scenario_name'] ?? '',
      selectedActions:
          (json['selected_actions'] as List<dynamic>?)
              ?.map((e) => RestorationActionModel.fromJson(e))
              .toList() ??
          [],
      totalBudgetUsd: (json['total_budget_usd'] as num?)?.toDouble() ?? 0.0,
      baselineTrajectory: ScenarioTrajectoryModel.fromJson(
        json['baseline_trajectory'] ?? {},
      ),
      restorationTrajectory: ScenarioTrajectoryModel.fromJson(
        json['restoration_trajectory'] ?? {},
      ),
      netImprovement2045: deltas,
      assumptionsAndLimitations:
          (json['assumptions_and_limitations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
