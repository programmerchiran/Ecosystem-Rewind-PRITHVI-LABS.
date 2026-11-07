from typing import Any, Optional
from pydantic import BaseModel, Field

# ---------------------------------------------------------
# 1. Ecosystem Area Models
# ---------------------------------------------------------
class EcosystemArea(BaseModel):
    area_id: str
    name: str
    ecosystem_type: str
    boundary_geojson: dict[str, Any]
    center_latitude: float
    center_longitude: float
    area_size: float
    area_size_unit: str = "hectares"
    dataset_version: str = "1.0.0"
    data_mode: str = "DEMO_ILLUSTRATIVE"
    supported_features: list[str] = Field(default_factory=lambda: [
        "health_dashboard",
        "ecosystem_network",
        "domino_simulator",
        "restoration_recommendations",
        "time_machine"
    ])
    description: str = ""
    climate_zone: str = ""
    vulnerability_notes: str = ""

# ---------------------------------------------------------
# 2. Species Models
# ---------------------------------------------------------
class Species(BaseModel):
    species_id: str
    area_id: str
    scientific_name: str
    common_name: str
    group: str  # e.g., Plants, Pollinators, Birds, Mammals, Invertebrates, Decomposers, Aquatic
    description: str
    observation_status: str  # e.g., Common, Vulnerable, Keystone, Endangered
    trophic_level: str  # Primary Producer, Primary Consumer, Secondary Consumer, Apex, Decomposer
    source: str = "PRITHVI LABS Curated Demo Baseline"
    data_mode: str = "DEMO_ILLUSTRATIVE"
    icon: Optional[str] = None
    population_trend: str = "Stable"
    dependency_criticality: float = 0.5  # 0.0 to 1.0 importance to community

# ---------------------------------------------------------
# 3. Ecological Interaction Models
# ---------------------------------------------------------
class EcologicalInteraction(BaseModel):
    interaction_id: str
    area_id: str
    source_species_id: str
    target_species_id: str
    interaction_type: str  # pollination, food_web, habitat_dependency, seed_dispersal, symbiosis
    direction: str = "directed"
    strength: float = 0.8  # 0.0 to 1.0 interaction weight
    dependency_weight: float = 0.7  # How critical this link is for the target
    source: str = "PRITHVI LABS Ecological Interaction Catalog"
    confidence: str = "High (Demo Parameterized)"

# ---------------------------------------------------------
# 4. Ecosystem Indicators & Summary
# ---------------------------------------------------------
class Indicator(BaseModel):
    indicator_id: str
    area_id: str
    name: str
    value: float  # Normalized 0 to 100
    baseline_value: float
    target_value: float = 90.0
    unit: str = "Score (0-100)"
    calculation_method: str
    observation_period: str = "2023-2025 Synthetic Observation Window"
    source: str = "PRITHVI LABS Ecological Monitor"
    data_mode: str = "DEMO_ILLUSTRATIVE"
    category: str  # biodiversity, connectivity, function, stability
    interpretation: str

class AreaSummary(BaseModel):
    area_id: str
    area_name: str
    ecosystem_type: str
    overall_health_score: float  # 0 to 100 composite score
    health_status: str  # e.g., Critical, Degraded, Moderate, Healthy, Pristine
    score_calculation_formula: str
    indicators: list[Indicator]
    data_coverage: str
    dataset_version: str
    observation_period: str
    methodology_limitations: list[str]

# ---------------------------------------------------------
# 5. Interactive Network Models
# ---------------------------------------------------------
class NetworkNode(BaseModel):
    id: str
    label: str
    scientific_name: str
    group: str
    status: str
    trophic_level: str
    degree: int
    in_degree: int = 0
    out_degree: int = 0
    pagerank: float = 0.0
    betweenness: float = 0.0
    is_keystone: bool = False
    description: str

class NetworkEdge(BaseModel):
    id: str
    source: str
    target: str
    interaction_type: str
    strength: float
    dependency_weight: float
    direction: str

class NetworkMetrics(BaseModel):
    total_nodes: int
    total_edges: int
    graph_density: float
    average_clustering: float
    connected_components: int
    diameter: Optional[int] = None

class NetworkGraphResponse(BaseModel):
    area_id: str
    ecosystem_name: str
    nodes: list[NetworkNode]
    edges: list[NetworkEdge]
    metrics: NetworkMetrics
    groups: list[str]
    interaction_types: list[str]

# ---------------------------------------------------------
# 6. Domino Simulation Models
# ---------------------------------------------------------
class DominoSimulationRequest(BaseModel):
    species_id: str
    propagation_depth: int = 2
    cascade_threshold: float = 0.5  # threshold of dependency lost to trigger secondary impact

class AffectedNodeInfo(BaseModel):
    species_id: str
    common_name: str
    scientific_name: str
    group: str
    impact_level: str  # Critical, High, Moderate, Low
    impact_rationale: str
    lost_dependencies: list[str]

class DominoSimulationResult(BaseModel):
    area_id: str
    removed_species: Species
    direct_relationships_removed: int
    potentially_affected_species: list[AffectedNodeInfo]
    isolated_species: list[str]
    domino_impact_score: float  # 0 to 100 rating of shock severity
    before_metrics: NetworkMetrics
    after_metrics: NetworkMetrics
    applied_rules_and_assumptions: list[str]
    explanation: str
    modified_network: NetworkGraphResponse

# ---------------------------------------------------------
# 7. Restoration Recommendation Models
# ---------------------------------------------------------
class RestorationAction(BaseModel):
    action_id: str
    name: str
    description: str
    applicable_ecosystem_types: list[str]
    target_problems: list[str]
    problem_addressed: str
    urgency_level: str  # High, Medium, Moderate
    cost_estimate_usd: float
    cost_unit: str = "USD/ha"
    total_estimated_budget_usd: float
    feasibility_notes: str
    beneficiary_species: list[str]
    impact_assumptions: dict[str, float]  # e.g., {"plant_diversity": +14.0, "connectivity": +22.0}
    ranking_score: float = 0.0
    ranking_factors: list[str] = Field(default_factory=list)
    source: str = "PRITHVI LABS Restoration Knowledge Base"
    data_mode: str = "DEMO_ILLUSTRATIVE"

class RecommendationResponse(BaseModel):
    area_id: str
    ecosystem_name: str
    total_recommendations: int
    recommendations: list[RestorationAction]
    ranking_methodology: str
    limitations_and_assumptions: list[str]

# ---------------------------------------------------------
# 8. Restoration Time Machine / Scenarios Models
# ---------------------------------------------------------
class ScenarioRequest(BaseModel):
    scenario_name: str = "Custom Ecological Restoration Strategy"
    action_ids: list[str]
    budget_usd: Optional[float] = None
    target_years: list[int] = Field(default_factory=lambda: [2030, 2040, 2045])

class YearPoint(BaseModel):
    year: int
    overall_health: float
    plant_diversity: float
    habitat_connectivity: float
    pollinator_network: float
    bird_network: float

class ScenarioTrajectory(BaseModel):
    scenario_type: str  # "baseline" (No intervention) vs "intervention"
    label: str
    description: str
    projections: list[YearPoint]

class ScenarioResponse(BaseModel):
    area_id: str
    ecosystem_name: str
    scenario_name: str
    selected_actions: list[RestorationAction]
    total_budget_usd: float
    baseline_trajectory: ScenarioTrajectory
    restoration_trajectory: ScenarioTrajectory
    net_improvement_2045: dict[str, float]
    assumptions_and_limitations: list[str]

# ---------------------------------------------------------
# 9. Report Models
# ---------------------------------------------------------
class ExecutiveReportResponse(BaseModel):
    area_id: str
    area_name: str
    generated_at: str
    markdown_content: str
    key_metrics_summary: dict[str, Any]
