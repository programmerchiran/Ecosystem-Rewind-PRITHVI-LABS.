
class HabitatSummaryModel {
  final String species;
  final String model;
  final String predictionType;
  final int totalCells;
  final double meanScore;
  final double minScore;
  final double maxScore;
  final Map<String, int> classDistribution;
  final String gridResolution;
  final String disclaimer;

  const HabitatSummaryModel({
    required this.species,
    required this.model,
    required this.predictionType,
    required this.totalCells,
    required this.meanScore,
    required this.minScore,
    required this.maxScore,
    required this.classDistribution,
    required this.gridResolution,
    required this.disclaimer,
  });

  factory HabitatSummaryModel.fromJson(Map<String, dynamic> json) {
    return HabitatSummaryModel(
      species: json['species'] as String? ?? 'Tectona grandis',
      model: json['model'] as String? ?? 'Unknown',
      predictionType:
          json['prediction_type'] as String? ?? 'Unknown',
      totalCells:
          (json['total_predicted_cells'] as num?)?.toInt() ?? 0,
      meanScore:
          (json['mean_suitability_score'] as num?)?.toDouble() ?? 0,
      minScore:
          (json['min_suitability_score'] as num?)?.toDouble() ?? 0,
      maxScore:
          (json['max_suitability_score'] as num?)?.toDouble() ?? 0,
      classDistribution:
          (json['class_distribution'] as Map<String, dynamic>? ?? {})
              .map((key, value) =>
                  MapEntry(key, (value as num).toInt())),
      gridResolution:
          '${((json['grid_resolution_m'] as num?) ?? 0) / 1000} km',
      disclaimer: json['disclaimer'] as String? ?? '',
    );
  }
}

class HabitatCellModel {
  final int row;
  final int col;
  final double latitude;
  final double longitude;
  final double score;
  final double index;
  final String suitabilityClass;

  const HabitatCellModel({
    required this.row,
    required this.col,
    required this.latitude,
    required this.longitude,
    required this.score,
    required this.index,
    required this.suitabilityClass,
  });

  factory HabitatCellModel.fromJson(Map<String, dynamic> json) {
    return HabitatCellModel(
      row: (json['row'] as num).toInt(),
      col: (json['col'] as num).toInt(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      score: (json['teak_suitability_score'] as num).toDouble(),
      index: (json['teak_suitability_index'] as num).toDouble(),
      suitabilityClass: json['suitability_class'] as String,
    );
  }
}

class HabitatCellsResponseModel {
  final int total;
  final int limit;
  final int offset;
  final List<HabitatCellModel> cells;

  const HabitatCellsResponseModel({
    required this.total,
    required this.limit,
    required this.offset,
    required this.cells,
  });

  factory HabitatCellsResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return HabitatCellsResponseModel(
      total: (json['total'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      offset: (json['offset'] as num).toInt(),
      cells: (json['cells'] as List<dynamic>)
          .map(
            (item) => HabitatCellModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}
