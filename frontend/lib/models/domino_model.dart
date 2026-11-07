import 'species_model.dart';
import 'network_model.dart';

class AffectedNodeInfoModel {
  final String speciesId;
  final String commonName;
  final String scientificName;
  final String group;
  final String impactLevel;
  final String impactRationale;
  final List<String> lostDependencies;

  AffectedNodeInfoModel({
    required this.speciesId,
    required this.commonName,
    required this.scientificName,
    required this.group,
    required this.impactLevel,
    required this.impactRationale,
    required this.lostDependencies,
  });

  factory AffectedNodeInfoModel.fromJson(Map<String, dynamic> json) {
    return AffectedNodeInfoModel(
      speciesId: json['species_id'] ?? '',
      commonName: json['common_name'] ?? '',
      scientificName: json['scientific_name'] ?? '',
      group: json['group'] ?? '',
      impactLevel: json['impact_level'] ?? 'Moderate',
      impactRationale: json['impact_rationale'] ?? '',
      lostDependencies:
          (json['lost_dependencies'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class DominoSimulationResultModel {
  final String areaId;
  final SpeciesModel removedSpecies;
  final int directRelationshipsRemoved;
  final List<AffectedNodeInfoModel> potentiallyAffectedSpecies;
  final List<String> isolatedSpecies;
  final double dominoImpactScore;
  final NetworkMetricsModel beforeMetrics;
  final NetworkMetricsModel afterMetrics;
  final List<String> appliedRulesAndAssumptions;
  final String explanation;
  final NetworkGraphModel modifiedNetwork;

  DominoSimulationResultModel({
    required this.areaId,
    required this.removedSpecies,
    required this.directRelationshipsRemoved,
    required this.potentiallyAffectedSpecies,
    required this.isolatedSpecies,
    required this.dominoImpactScore,
    required this.beforeMetrics,
    required this.afterMetrics,
    required this.appliedRulesAndAssumptions,
    required this.explanation,
    required this.modifiedNetwork,
  });

  factory DominoSimulationResultModel.fromJson(Map<String, dynamic> json) {
    return DominoSimulationResultModel(
      areaId: json['area_id'] ?? '',
      removedSpecies: SpeciesModel.fromJson(json['removed_species'] ?? {}),
      directRelationshipsRemoved:
          (json['direct_relationships_removed'] as num?)?.toInt() ?? 0,
      potentiallyAffectedSpecies:
          (json['potentially_affected_species'] as List<dynamic>?)
              ?.map((e) => AffectedNodeInfoModel.fromJson(e))
              .toList() ??
          [],
      isolatedSpecies:
          (json['isolated_species'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      dominoImpactScore:
          (json['domino_impact_score'] as num?)?.toDouble() ?? 0.0,
      beforeMetrics: NetworkMetricsModel.fromJson(json['before_metrics'] ?? {}),
      afterMetrics: NetworkMetricsModel.fromJson(json['after_metrics'] ?? {}),
      appliedRulesAndAssumptions:
          (json['applied_rules_and_assumptions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      explanation: json['explanation'] ?? '',
      modifiedNetwork: NetworkGraphModel.fromJson(
        json['modified_network'] ?? {},
      ),
    );
  }
}
