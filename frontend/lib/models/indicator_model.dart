class IndicatorModel {
  final String indicatorId;
  final String areaId;
  final String name;
  final double value;
  final double baselineValue;
  final double targetValue;
  final String unit;
  final String calculationMethod;
  final String observationPeriod;
  final String source;
  final String dataMode;
  final String category;
  final String interpretation;

  IndicatorModel({
    required this.indicatorId,
    required this.areaId,
    required this.name,
    required this.value,
    required this.baselineValue,
    required this.targetValue,
    required this.unit,
    required this.calculationMethod,
    required this.observationPeriod,
    required this.source,
    required this.dataMode,
    required this.category,
    required this.interpretation,
  });

  factory IndicatorModel.fromJson(Map<String, dynamic> json) {
    return IndicatorModel(
      indicatorId: json['indicator_id'] ?? '',
      areaId: json['area_id'] ?? '',
      name: json['name'] ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      baselineValue: (json['baseline_value'] as num?)?.toDouble() ?? 0.0,
      targetValue: (json['target_value'] as num?)?.toDouble() ?? 90.0,
      unit: json['unit'] ?? '',
      calculationMethod: json['calculation_method'] ?? '',
      observationPeriod: json['observation_period'] ?? '',
      source: json['source'] ?? '',
      dataMode: json['data_mode'] ?? 'DEMO_ILLUSTRATIVE',
      category: json['category'] ?? 'general',
      interpretation: json['interpretation'] ?? '',
    );
  }
}

class AreaSummaryModel {
  final String areaId;
  final String areaName;
  final String ecosystemType;
  final double overallHealthScore;
  final String healthStatus;
  final String scoreCalculationFormula;
  final List<IndicatorModel> indicators;
  final String dataCoverage;
  final String datasetVersion;
  final String observationPeriod;
  final List<String> methodologyLimitations;

  AreaSummaryModel({
    required this.areaId,
    required this.areaName,
    required this.ecosystemType,
    required this.overallHealthScore,
    required this.healthStatus,
    required this.scoreCalculationFormula,
    required this.indicators,
    required this.dataCoverage,
    required this.datasetVersion,
    required this.observationPeriod,
    required this.methodologyLimitations,
  });

  factory AreaSummaryModel.fromJson(Map<String, dynamic> json) {
    return AreaSummaryModel(
      areaId: json['area_id'] ?? '',
      areaName: json['area_name'] ?? '',
      ecosystemType: json['ecosystem_type'] ?? '',
      overallHealthScore:
          (json['overall_health_score'] as num?)?.toDouble() ?? 0.0,
      healthStatus: json['health_status'] ?? 'Unknown',
      scoreCalculationFormula: json['score_calculation_formula'] ?? '',
      indicators:
          (json['indicators'] as List<dynamic>?)
              ?.map((e) => IndicatorModel.fromJson(e))
              .toList() ??
          [],
      dataCoverage: json['data_coverage'] ?? '',
      datasetVersion: json['dataset_version'] ?? '1.0.0',
      observationPeriod: json['observation_period'] ?? '',
      methodologyLimitations:
          (json['methodology_limitations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
