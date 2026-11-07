class RestorationActionModel {
  final String actionId;
  final String name;
  final String description;
  final List<String> applicableEcosystemTypes;
  final List<String> targetProblems;
  final String problemAddressed;
  final String urgencyLevel;
  final double costEstimateUsd;
  final String costUnit;
  final double totalEstimatedBudgetUsd;
  final String feasibilityNotes;
  final List<String> beneficiarySpecies;
  final Map<String, double> impactAssumptions;
  final double rankingScore;
  final List<String> rankingFactors;
  final String source;
  final String dataMode;

  RestorationActionModel({
    required this.actionId,
    required this.name,
    required this.description,
    required this.applicableEcosystemTypes,
    required this.targetProblems,
    required this.problemAddressed,
    required this.urgencyLevel,
    required this.costEstimateUsd,
    required this.costUnit,
    required this.totalEstimatedBudgetUsd,
    required this.feasibilityNotes,
    required this.beneficiarySpecies,
    required this.impactAssumptions,
    required this.rankingScore,
    required this.rankingFactors,
    required this.source,
    required this.dataMode,
  });

  factory RestorationActionModel.fromJson(Map<String, dynamic> json) {
    final Map<String, double> impacts = {};
    if (json['impact_assumptions'] is Map) {
      (json['impact_assumptions'] as Map).forEach((k, v) {
        impacts[k.toString()] = (v as num).toDouble();
      });
    }

    return RestorationActionModel(
      actionId: json['action_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      applicableEcosystemTypes:
          (json['applicable_ecosystem_types'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      targetProblems:
          (json['target_problems'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      problemAddressed: json['problem_addressed'] ?? '',
      urgencyLevel: json['urgency_level'] ?? 'Medium',
      costEstimateUsd: (json['cost_estimate_usd'] as num?)?.toDouble() ?? 0.0,
      costUnit: json['cost_unit'] ?? 'USD/ha',
      totalEstimatedBudgetUsd:
          (json['total_estimated_budget_usd'] as num?)?.toDouble() ?? 0.0,
      feasibilityNotes: json['feasibility_notes'] ?? '',
      beneficiarySpecies:
          (json['beneficiary_species'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      impactAssumptions: impacts,
      rankingScore: (json['ranking_score'] as num?)?.toDouble() ?? 0.0,
      rankingFactors:
          (json['ranking_factors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      source: json['source'] ?? '',
      dataMode: json['data_mode'] ?? 'DEMO_ILLUSTRATIVE',
    );
  }
}

class RecommendationResponseModel {
  final String areaId;
  final String ecosystemName;
  final int totalRecommendations;
  final List<RestorationActionModel> recommendations;
  final String rankingMethodology;
  final List<String> limitationsAndAssumptions;

  RecommendationResponseModel({
    required this.areaId,
    required this.ecosystemName,
    required this.totalRecommendations,
    required this.recommendations,
    required this.rankingMethodology,
    required this.limitationsAndAssumptions,
  });

  factory RecommendationResponseModel.fromJson(Map<String, dynamic> json) {
    return RecommendationResponseModel(
      areaId: json['area_id'] ?? '',
      ecosystemName: json['ecosystem_name'] ?? '',
      totalRecommendations:
          (json['total_recommendations'] as num?)?.toInt() ?? 0,
      recommendations:
          (json['recommendations'] as List<dynamic>?)
              ?.map((e) => RestorationActionModel.fromJson(e))
              .toList() ??
          [],
      rankingMethodology: json['ranking_methodology'] ?? '',
      limitationsAndAssumptions:
          (json['limitations_and_assumptions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
