class SpeciesModel {
  final String speciesId;
  final String areaId;
  final String scientificName;
  final String commonName;
  final String group;
  final String description;
  final String observationStatus;
  final String trophicLevel;
  final String source;
  final String dataMode;
  final String populationTrend;
  final double dependencyCriticality;

  SpeciesModel({
    required this.speciesId,
    required this.areaId,
    required this.scientificName,
    required this.commonName,
    required this.group,
    required this.description,
    required this.observationStatus,
    required this.trophicLevel,
    required this.source,
    required this.dataMode,
    required this.populationTrend,
    required this.dependencyCriticality,
  });

  factory SpeciesModel.fromJson(Map<String, dynamic> json) {
    return SpeciesModel(
      speciesId: json['species_id'] ?? '',
      areaId: json['area_id'] ?? '',
      scientificName: json['scientific_name'] ?? '',
      commonName: json['common_name'] ?? '',
      group: json['group'] ?? 'General',
      description: json['description'] ?? '',
      observationStatus: json['observation_status'] ?? 'Common',
      trophicLevel: json['trophic_level'] ?? 'Primary Consumer',
      source: json['source'] ?? '',
      dataMode: json['data_mode'] ?? 'DEMO_ILLUSTRATIVE',
      populationTrend: json['population_trend'] ?? 'Stable',
      dependencyCriticality:
          (json['dependency_criticality'] as num?)?.toDouble() ?? 0.5,
    );
  }
}
