class NetworkNodeModel {
  final String id;
  final String label;
  final String scientificName;
  final String group;
  final String status;
  final String trophicLevel;
  final int degree;
  final int inDegree;
  final int outDegree;
  final double pagerank;
  final double betweenness;
  final bool isKeystone;
  final String description;

  NetworkNodeModel({
    required this.id,
    required this.label,
    required this.scientificName,
    required this.group,
    required this.status,
    required this.trophicLevel,
    required this.degree,
    required this.inDegree,
    required this.outDegree,
    required this.pagerank,
    required this.betweenness,
    required this.isKeystone,
    required this.description,
  });

  factory NetworkNodeModel.fromJson(Map<String, dynamic> json) {
    return NetworkNodeModel(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      scientificName: json['scientific_name'] ?? '',
      group: json['group'] ?? 'General',
      status: json['status'] ?? 'Common',
      trophicLevel: json['trophic_level'] ?? 'Consumer',
      degree: (json['degree'] as num?)?.toInt() ?? 0,
      inDegree: (json['in_degree'] as num?)?.toInt() ?? 0,
      outDegree: (json['out_degree'] as num?)?.toInt() ?? 0,
      pagerank: (json['pagerank'] as num?)?.toDouble() ?? 0.0,
      betweenness: (json['betweenness'] as num?)?.toDouble() ?? 0.0,
      isKeystone: json['is_keystone'] ?? false,
      description: json['description'] ?? '',
    );
  }
}

class NetworkEdgeModel {
  final String id;
  final String source;
  final String target;
  final String interactionType;
  final double strength;
  final double dependencyWeight;
  final String direction;

  NetworkEdgeModel({
    required this.id,
    required this.source,
    required this.target,
    required this.interactionType,
    required this.strength,
    required this.dependencyWeight,
    required this.direction,
  });

  factory NetworkEdgeModel.fromJson(Map<String, dynamic> json) {
    return NetworkEdgeModel(
      id: json['id'] ?? '',
      source: json['source'] ?? '',
      target: json['target'] ?? '',
      interactionType: json['interaction_type'] ?? 'trophic',
      strength: (json['strength'] as num?)?.toDouble() ?? 0.5,
      dependencyWeight: (json['dependency_weight'] as num?)?.toDouble() ?? 0.5,
      direction: json['direction'] ?? 'directed',
    );
  }
}

class NetworkMetricsModel {
  final int totalNodes;
  final int totalEdges;
  final double graphDensity;
  final double averageClustering;
  final int connectedComponents;

  NetworkMetricsModel({
    required this.totalNodes,
    required this.totalEdges,
    required this.graphDensity,
    required this.averageClustering,
    required this.connectedComponents,
  });

  factory NetworkMetricsModel.fromJson(Map<String, dynamic> json) {
    return NetworkMetricsModel(
      totalNodes: (json['total_nodes'] as num?)?.toInt() ?? 0,
      totalEdges: (json['total_edges'] as num?)?.toInt() ?? 0,
      graphDensity: (json['graph_density'] as num?)?.toDouble() ?? 0.0,
      averageClustering:
          (json['average_clustering'] as num?)?.toDouble() ?? 0.0,
      connectedComponents: (json['connected_components'] as num?)?.toInt() ?? 1,
    );
  }
}

class NetworkGraphModel {
  final String areaId;
  final String ecosystemName;
  final List<NetworkNodeModel> nodes;
  final List<NetworkEdgeModel> edges;
  final NetworkMetricsModel metrics;
  final List<String> groups;
  final List<String> interactionTypes;

  NetworkGraphModel({
    required this.areaId,
    required this.ecosystemName,
    required this.nodes,
    required this.edges,
    required this.metrics,
    required this.groups,
    required this.interactionTypes,
  });

  factory NetworkGraphModel.fromJson(Map<String, dynamic> json) {
    return NetworkGraphModel(
      areaId: json['area_id'] ?? '',
      ecosystemName: json['ecosystem_name'] ?? '',
      nodes:
          (json['nodes'] as List<dynamic>?)
              ?.map((e) => NetworkNodeModel.fromJson(e))
              .toList() ??
          [],
      edges:
          (json['edges'] as List<dynamic>?)
              ?.map((e) => NetworkEdgeModel.fromJson(e))
              .toList() ??
          [],
      metrics: json['metrics'] != null
          ? NetworkMetricsModel.fromJson(json['metrics'])
          : NetworkMetricsModel(
              totalNodes: 0,
              totalEdges: 0,
              graphDensity: 0,
              averageClustering: 0,
              connectedComponents: 0,
            ),
      groups:
          (json['groups'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      interactionTypes:
          (json['interaction_types'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
