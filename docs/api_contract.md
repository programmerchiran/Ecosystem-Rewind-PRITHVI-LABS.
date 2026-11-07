# Ecosystem Rewind - REST API Contract

**Base URL**: `http://127.0.0.1:8000/api`  
**OpenAPI / Swagger UI**: `http://127.0.0.1:8000/docs`  

---

## Endpoints Summary

### 1. General & System
- `GET /health`
  - Response: `{"status": "ok", "service": "Ecosystem Rewind API", "version": "1.0.0"}`
- `GET /areas`
  - Returns list of supported `EcosystemArea` objects with boundaries, center coords, features.
- `GET /areas/{area_id}`
  - Returns metadata for the specified area or 404 if not found.

### 2. Ecosystem Health Dashboard
- `GET /areas/{area_id}/summary`
  - Returns overall project health score (0-100), composite indicators (`plant_diversity`, `habitat_connectivity`, `pollinator_network`, `bird_network`, etc.), methodology, observation window, and data provenance.

### 3. Species & Network
- `GET /areas/{area_id}/species`
  - Returns list of species with group, conservation status, description. Optional `?group=` query parameter.
- `GET /areas/{area_id}/network`
  - Returns Network Graph JSON:
    - `nodes`: `[{id, label, scientific_name, group, status, degree, pagerank, ...}]`
    - `edges`: `[{id, source, target, interaction_type, direction, strength, source_desc}]`
    - `summary`: total nodes, edges, density, clustering, modularity.

### 4. Ecological Domino Simulator
- `POST /areas/{area_id}/simulate`
  - Body: `{"species_id": "string", "propagation_depth": 2, "cascade_threshold": 0.4}`
  - Response:
    - `removed_node`: Species object
    - `direct_links_removed`: count
    - `cascade_affected_nodes`: list of affected species with impact rationale
    - `isolated_nodes`: newly orphaned species
    - `domino_impact_score`: 0-100 score indicating structural shock
    - `before_metrics` vs `after_metrics`: graph density, clustering, components
    - `assumptions_applied`: documented rules applied during propagation

### 5. Rule-Based Restoration Recommendations
- `GET /areas/{area_id}/recommendations`
  - Optional Query: `?max_budget=500000`
  - Response:
    - List of recommended actions ranked by score.
    - Each action contains: `action_id`, `name`, `target_problems`, `problem_addressed`, `urgency_level`, `estimated_cost_usd`, `projected_impacts`, `beneficiary_species`, `feasibility_notes`, `ranking_score`, `ranking_factors`.

### 6. Restoration Time Machine (Scenarios)
- `POST /areas/{area_id}/scenarios`
  - Body:
    ```json
    {
      "scenario_name": "Active Canopy & Pollinator Corridor Intervention",
      "action_ids": ["wg_corridor_reforestation", "wg_nectar_enrichment"],
      "investment_level": "medium",
      "target_years": [2030, 2040, 2045]
    }
    ```
  - Response:
    - Comparison between `baseline_trajectory` (business as usual / degradation) and `restoration_trajectory` for each indicator and overall health score across 2025, 2030, 2040, 2045.
    - Explanations of non-linear ecological lag assumptions, bounds, and limitations.

### 7. Executive Ecological Report
- `POST /areas/{area_id}/report`
  - Generates comprehensive synthesis of the ecosystem health, network vulnerability, keystone species, and prioritized action plan.
