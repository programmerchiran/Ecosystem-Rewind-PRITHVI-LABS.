class EcosystemAreaModel {
  final String areaId;
  final String name;
  final String ecosystemType;
  final double centerLatitude;
  final double centerLongitude;
  final double areaSize;
  final String areaSizeUnit;
  final String datasetVersion;
  final String dataMode;
  final List<String> supportedFeatures;
  final String description;
  final String climateZone;
  final String vulnerabilityNotes;
  final Map<String, dynamic> boundaryGeojson;

  EcosystemAreaModel({
    required this.areaId,
    required this.name,
    required this.ecosystemType,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.areaSize,
    required this.areaSizeUnit,
    required this.datasetVersion,
    required this.dataMode,
    required this.supportedFeatures,
    required this.description,
    required this.climateZone,
    required this.vulnerabilityNotes,
    required this.boundaryGeojson,
  });

  factory EcosystemAreaModel.fromJson(Map<String, dynamic> json) {
    return EcosystemAreaModel(
      areaId: json['area_id'] ?? '',
      name: json['name'] ?? '',
      ecosystemType: json['ecosystem_type'] ?? '',
      centerLatitude: (json['center_latitude'] as num?)?.toDouble() ?? 0.0,
      centerLongitude: (json['center_longitude'] as num?)?.toDouble() ?? 0.0,
      areaSize: (json['area_size'] as num?)?.toDouble() ?? 0.0,
      areaSizeUnit: json['area_size_unit'] ?? 'hectares',
      datasetVersion: json['dataset_version'] ?? '1.0.0',
      dataMode: json['data_mode'] ?? 'DEMO_ILLUSTRATIVE',
      supportedFeatures:
          (json['supported_features'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      description: json['description'] ?? '',
      climateZone: json['climate_zone'] ?? '',
      vulnerabilityNotes: json['vulnerability_notes'] ?? '',
      boundaryGeojson: json['boundary_geojson'] ?? {},
    );
  }
}
