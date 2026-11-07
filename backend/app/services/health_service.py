from typing import Optional
from backend.app.repositories.ecosystem_repository import EcosystemRepository, ecosystem_repo
from backend.app.schemas.models import AreaSummary, Indicator

class HealthService:
    def __init__(self, repo: EcosystemRepository = ecosystem_repo):
        self.repo = repo

    def get_area_health_summary(self, area_id: str) -> Optional[AreaSummary]:
        area = self.repo.get_area(area_id)
        if not area:
            return None

        indicators = self.repo.list_indicators(area_id)
        if not indicators:
            return None

        # Transparent rule-based weighted composite calculation
        # Weights vary predictably based on ecosystem type focus:
        if "Wetland" in area.ecosystem_type or "Mangrove" in area.ecosystem_type:
            weight_map = {
                "Plant Diversity Index": 0.20,
                "Habitat Connectivity Index": 0.20,
                "Pollinator Network Robustness": 0.15,
                "Bird Network & Seed Dispersal": 0.20,
                "Benthic/Aquatic Health Index": 0.25,
            }
            formula_desc = "Composite Health Score = 0.20*(Plant Diversity) + 0.20*(Hydrological Connectivity) + 0.15*(Pollinator Robustness) + 0.20*(Avian Index) + 0.25*(Benthic Aquatic Integrity)"
        else:
            weight_map = {
                "Plant Diversity Index": 0.25,
                "Habitat Connectivity Index": 0.25,
                "Pollinator Network Robustness": 0.20,
                "Bird Network & Seed Dispersal": 0.15,
                "Keystone Stability Index": 0.15,
            }
            formula_desc = "Composite Health Score = 0.25*(Plant Diversity) + 0.25*(Canopy Corridor Connectivity) + 0.20*(Pollinator Network) + 0.15*(Bird Seed Dispersal) + 0.15*(Keystone Stability)"

        weighted_sum = 0.0
        total_weight = 0.0
        for ind in indicators:
            w = weight_map.get(ind.name, 1.0 / len(indicators))
            weighted_sum += ind.value * w
            total_weight += w

        overall_score = round(weighted_sum / total_weight, 1) if total_weight > 0 else 0.0

        if overall_score >= 80.0:
            status = "Pristine / Resilient"
        elif overall_score >= 65.0:
            status = "Healthy with Localized Stress"
        elif overall_score >= 50.0:
            status = "Moderately Degraded"
        elif overall_score >= 35.0:
            status = "Vulnerable / High Risk"
        else:
            status = "Critical Ecosystem Collapse Warning"

        limitations = [
            "Project-defined composite indicator normalized on a 0-100 scale for comparative analysis; not a universal scientific constant.",
            "Based on curated baseline observations and remote-sensing proxies.",
            "Weights reflect ecosystem-type sensitivity (e.g., benthic health in estuaries, canopy connectivity in rainforests)."
        ]

        return AreaSummary(
            area_id=area.area_id,
            area_name=area.name,
            ecosystem_type=area.ecosystem_type,
            overall_health_score=overall_score,
            health_status=status,
            score_calculation_formula=formula_desc,
            indicators=indicators,
            data_coverage="Comprehensive 5-Dimension Indicator Suite (Biodiversity, Connectivity, Function, Stability, Structure)",
            dataset_version=area.dataset_version,
            observation_period="2023-2025 Multi-Sensor Satellite & Transect Window",
            methodology_limitations=limitations
        )

health_service = HealthService()
