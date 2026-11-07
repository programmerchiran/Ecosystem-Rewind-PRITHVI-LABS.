import pytest
from fastapi.testclient import TestClient
from backend.app.main import app
from backend.app.repositories.ecosystem_repository import ecosystem_repo
from backend.app.schemas.models import DominoSimulationRequest, ScenarioRequest

client = TestClient(app)

# -----------------------------------------------------------------
# 1. System Health Tests
# -----------------------------------------------------------------
def test_health_check():
    response = client.get("/api/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "PRITHVI LABS" in data["organization"]

def test_root_endpoint():
    response = client.get("/")
    assert response.status_code == 200
    assert "documentation" in response.json()

# -----------------------------------------------------------------
# 2. Ecosystem Areas Tests
# -----------------------------------------------------------------
def test_list_areas():
    response = client.get("/api/areas")
    assert response.status_code == 200
    areas = response.json()
    assert len(areas) >= 2
    area_ids = [a["area_id"] for a in areas]
    assert "western_ghats_forest" in area_ids
    assert "sundarbans_wetland" in area_ids

def test_get_valid_area():
    response = client.get("/api/areas/western_ghats_forest")
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "Western Ghats Evergreen Corridor"
    assert data["ecosystem_type"] == "Tropical Montane Evergreen Forest"
    assert data["center_latitude"] > 0
    assert "boundary_geojson" in data

def test_get_invalid_area():
    response = client.get("/api/areas/non_existent_area_id_999")
    assert response.status_code == 404
    assert "not found" in response.json()["detail"].lower()

# -----------------------------------------------------------------
# 3. Health Summary & Indicator Tests
# -----------------------------------------------------------------
def test_get_area_health_summary():
    response = client.get("/api/areas/western_ghats_forest/summary")
    assert response.status_code == 200
    summary = response.json()
    assert summary["area_id"] == "western_ghats_forest"
    assert 0.0 <= summary["overall_health_score"] <= 100.0
    assert len(summary["indicators"]) >= 5
    assert "score_calculation_formula" in summary
    assert len(summary["methodology_limitations"]) > 0

def test_wetland_health_summary():
    response = client.get("/api/areas/sundarbans_wetland/summary")
    assert response.status_code == 200
    summary = response.json()
    assert summary["area_id"] == "sundarbans_wetland"
    assert summary["overall_health_score"] > 0
    # Check that wetland indicator exists
    indicator_names = [i["name"] for i in summary["indicators"]]
    assert any("Benthic" in n or "Plant" in n for n in indicator_names)

# -----------------------------------------------------------------
# 4. Species & Network Tests
# -----------------------------------------------------------------
def test_get_species_list():
    response = client.get("/api/areas/western_ghats_forest/species")
    assert response.status_code == 200
    species = response.json()
    assert len(species) >= 10
    assert any(s["common_name"] == "Great Hornbill" for s in species)

def test_get_species_filter_by_group():
    response = client.get("/api/areas/western_ghats_forest/species?group=Plants")
    assert response.status_code == 200
    species = response.json()
    assert len(species) > 0
    assert all(s["group"] == "Plants" for s in species)

def test_get_network_graph():
    response = client.get("/api/areas/western_ghats_forest/network")
    assert response.status_code == 200
    data = response.json()
    assert len(data["nodes"]) >= 10
    assert len(data["edges"]) >= 10
    assert "metrics" in data
    assert data["metrics"]["graph_density"] > 0
    assert data["metrics"]["connected_components"] >= 1
    # Check node attributes
    node = data["nodes"][0]
    assert "pagerank" in node
    assert "betweenness" in node
    assert "group" in node

# -----------------------------------------------------------------
# 5. Domino Simulator Tests & Repeatability & Graph Isolation
# -----------------------------------------------------------------
def test_domino_simulation_repeatability_and_isolation():
    # Capture original network metrics
    orig_res = client.get("/api/areas/western_ghats_forest/network")
    orig_nodes_count = len(orig_res.json()["nodes"])
    orig_edges_count = len(orig_res.json()["edges"])

    # Simulate removal of keystone species Cullenia exarillata (wg_sp_01)
    req_body = {
        "species_id": "wg_sp_01",
        "propagation_depth": 2,
        "cascade_threshold": 0.5
    }
    sim_res1 = client.post("/api/areas/western_ghats_forest/simulate", json=req_body)
    assert sim_res1.status_code == 200
    result1 = sim_res1.json()

    assert result1["removed_species"]["species_id"] == "wg_sp_01"
    assert result1["direct_relationships_removed"] > 0
    assert len(result1["potentially_affected_species"]) > 0
    assert result1["domino_impact_score"] > 0
    assert len(result1["applied_rules_and_assumptions"]) >= 3

    # Repeat exact same simulation -> must produce exact identical numbers (deterministic)
    sim_res2 = client.post("/api/areas/western_ghats_forest/simulate", json=req_body)
    assert sim_res2.status_code == 200
    result2 = sim_res2.json()
    assert result1["domino_impact_score"] == result2["domino_impact_score"]
    assert result1["direct_relationships_removed"] == result2["direct_relationships_removed"]

    # Verify original master graph in memory was NOT mutated
    after_res = client.get("/api/areas/western_ghats_forest/network")
    assert len(after_res.json()["nodes"]) == orig_nodes_count
    assert len(after_res.json()["edges"]) == orig_edges_count

def test_domino_simulation_invalid_species():
    req_body = {"species_id": "invalid_fake_species_999"}
    res = client.post("/api/areas/western_ghats_forest/simulate", json=req_body)
    assert res.status_code == 404

# -----------------------------------------------------------------
# 6. Restoration Recommendations Tests
# -----------------------------------------------------------------
def test_recommendations_area_specificity():
    # Western Ghats recommendations
    wg_res = client.get("/api/areas/western_ghats_forest/recommendations")
    assert wg_res.status_code == 200
    wg_recs = wg_res.json()["recommendations"]
    assert len(wg_recs) >= 2
    # Verify ranking descending
    for i in range(len(wg_recs) - 1):
        assert wg_recs[i]["ranking_score"] >= wg_recs[i+1]["ranking_score"]
    # Verify canopy corridor action is present
    assert any("Canopy" in r["name"] or "Pollinator" in r["name"] for r in wg_recs)

    # Sundarbans recommendations
    sb_res = client.get("/api/areas/sundarbans_wetland/recommendations")
    assert sb_res.status_code == 200
    sb_recs = sb_res.json()["recommendations"]
    assert len(sb_recs) >= 2
    # Verify Sundari / Rhizophora action is present
    assert any("Sundari" in r["name"] or "Rhizophora" in r["name"] or "Benthic" in r["name"] for r in sb_recs)

    # Recommendations differ between the two ecosystems
    wg_action_ids = [r["action_id"] for r in wg_recs]
    sb_action_ids = [r["action_id"] for r in sb_recs]
    assert wg_action_ids != sb_action_ids

# -----------------------------------------------------------------
# 7. Restoration Time Machine Scenario Tests
# -----------------------------------------------------------------
def test_time_machine_scenario_calculation():
    req = {
        "scenario_name": "Active Corridors and Pollinator Buffer",
        "action_ids": ["wg_act_01", "wg_act_02"],
        "budget_usd": 250000.0,
        "target_years": [2030, 2040, 2045]
    }
    res = client.post("/api/areas/western_ghats_forest/scenarios", json=req)
    assert res.status_code == 200
    data = res.json()
    assert data["area_id"] == "western_ghats_forest"
    assert len(data["selected_actions"]) == 2
    
    baseline_pts = data["baseline_trajectory"]["projections"]
    restoration_pts = data["restoration_trajectory"]["projections"]
    assert len(baseline_pts) == 4  # 2025, 2030, 2040, 2045
    assert len(restoration_pts) == 4

    # Check non-linear progression
    p_2025 = restoration_pts[0]
    p_2045 = restoration_pts[-1]
    assert p_2045["overall_health"] > p_2025["overall_health"]
    assert data["net_improvement_2045"]["overall_health_delta"] > 0

    # Ensure bounds (0 to 100)
    for p in restoration_pts + baseline_pts:
        assert 0.0 <= p["overall_health"] <= 100.0
        assert 0.0 <= p["plant_diversity"] <= 100.0
        assert 0.0 <= p["habitat_connectivity"] <= 100.0

# -----------------------------------------------------------------
# 8. Executive Report Test
# -----------------------------------------------------------------
def test_executive_report():
    res = client.post("/api/areas/western_ghats_forest/report")
    assert res.status_code == 200
    report = res.json()
    assert "PRITHVI LABS" in report["markdown_content"]
    assert report["key_metrics_summary"]["overall_health"] > 0
