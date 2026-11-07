from typing import Optional
from backend.app.repositories.ecosystem_repository import EcosystemRepository, ecosystem_repo
from backend.app.schemas.models import (
    RestorationAction,
    RecommendationResponse,
)

class RecommendationService:
    def __init__(self, repo: EcosystemRepository = ecosystem_repo):
        self.repo = repo

    def get_recommendations_for_area(
        self,
        area_id: str,
        max_budget: Optional[float] = None
    ) -> Optional[RecommendationResponse]:
        area = self.repo.get_area(area_id)
        if not area:
            return None

        indicators = self.repo.list_indicators(area_id)
        indicator_map = {ind.name.lower(): ind.value for ind in indicators}
        actions = self.repo.list_actions_for_area(area_id)

        # Multi-factor rule-based ranking
        ranked_actions: list[RestorationAction] = []
        for action in actions:
            ranking_factors = []
            score = 50.0  # Base feasibility score

            # Factor 1: Problem Urgency Matching
            # Check if this action addresses an indicator with acute deficit
            if "connectivity" in action.target_problems or "habitat_fragmentation" in action.target_problems:
                conn_val = indicator_map.get("habitat connectivity index", 70.0)
                if conn_val < 55.0:
                    score += 30.0
                    ranking_factors.append(f"Acute Connectivity Deficit ({conn_val}/100): Direct corridor intervention urgently needed.")
                elif conn_val < 70.0:
                    score += 18.0
                    ranking_factors.append(f"Moderate Connectivity Deficit ({conn_val}/100).")

            if "pollinator_decline" in action.target_problems or "flower_deficit" in action.target_problems:
                poll_val = indicator_map.get("pollinator network robustness", 70.0)
                if poll_val < 50.0:
                    score += 32.0
                    ranking_factors.append(f"Severe Pollinator Collapse Risk ({poll_val}/100): High priority for pollination revival.")
                elif poll_val < 65.0:
                    score += 20.0
                    ranking_factors.append(f"Suboptimal Pollinator Robustness ({poll_val}/100).")

            if "salinity_intrusion" in action.target_problems or "sundari_dieback" in action.target_problems:
                plant_val = indicator_map.get("plant diversity index", 70.0)
                if plant_val < 55.0:
                    score += 30.0
                    ranking_factors.append(f"Critical Mangrove Dieback & High Salinity Stress (Plant Diversity: {plant_val}/100).")

            if "larval_bycatch_overfishing" in action.target_problems or "benthic_depletion" in action.target_problems:
                benthic_val = indicator_map.get("benthic/aquatic health index", 70.0)
                if benthic_val < 70.0:
                    score += 22.0
                    ranking_factors.append(f"Benthic Trophic Depletion detected ({benthic_val}/100).")

            # Factor 2: Keystone and Endangered Species Coverage
            keystone_beneficiaries = [sp for sp in action.beneficiary_species if any(k in sp for k in ["Macaca", "Buceros", "Panthera", "Heritiera", "Rhizophora"])]
            if keystone_beneficiaries:
                score += 15.0
                ranking_factors.append(f"Direct protection for priority keystone taxa: {', '.join(keystone_beneficiaries)}.")

            # Factor 3: Cost Efficiency Leverage
            cost = action.total_estimated_budget_usd
            if max_budget is not None and cost > max_budget:
                score -= 30.0
                ranking_factors.append(f"Exceeds user-specified budget filter (${cost:,.0f} > ${max_budget:,.0f}).")
            else:
                score += 5.0
                ranking_factors.append(f"Financially viable under target allocation (${cost:,.0f} estimated budget).")

            final_score = round(min(max(score, 10.0), 99.0), 1)

            # Create a scored clone of the action
            scored_action = action.model_copy()
            scored_action.ranking_score = final_score
            scored_action.ranking_factors = ranking_factors
            ranked_actions.append(scored_action)

        # Sort descending by ranking score
        ranked_actions.sort(key=lambda a: a.ranking_score, reverse=True)

        methodology = (
            "Multi-criteria deterministic utility function evaluating indicator deficit severity, "
            "keystone species dependency leverage, and budgetary feasibility. No stochastic variables applied."
        )

        limitations = [
            "Rule-based recommendations based on curated ecological catalogs and expert consensus parameters.",
            "Cost estimates are illustrative regional averages and subject to local terrain and labor logistics.",
            "Modular service interface architected to integrate empirical Machine Learning habitat suitability predictions in Phase 3."
        ]

        return RecommendationResponse(
            area_id=area_id,
            ecosystem_name=area.name,
            total_recommendations=len(ranked_actions),
            recommendations=ranked_actions,
            ranking_methodology=methodology,
            limitations_and_assumptions=limitations
        )

recommendation_service = RecommendationService()
