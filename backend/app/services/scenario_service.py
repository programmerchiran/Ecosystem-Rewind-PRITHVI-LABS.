from typing import Optional
from backend.app.repositories.ecosystem_repository import EcosystemRepository, ecosystem_repo
from backend.app.schemas.models import (
    ScenarioRequest,
    ScenarioResponse,
    ScenarioTrajectory,
    YearPoint,
    RestorationAction,
)

class ScenarioService:
    def __init__(self, repo: EcosystemRepository = ecosystem_repo):
        self.repo = repo

    def calculate_scenario(
        self,
        area_id: str,
        request: ScenarioRequest
    ) -> Optional[ScenarioResponse]:
        area = self.repo.get_area(area_id)
        if not area:
            return None

        indicators = self.repo.list_indicators(area_id)
        if not indicators:
            return None

        # Build map of starting 2025 indicator values
        start_vals = {
            "plant_diversity": 70.0,
            "habitat_connectivity": 60.0,
            "pollinator_network": 55.0,
            "bird_network": 65.0,
            "overall_health": 62.0
        }

        for ind in indicators:
            lower_name = ind.name.lower()
            if "plant" in lower_name:
                start_vals["plant_diversity"] = ind.value
            elif "connectivity" in lower_name:
                start_vals["habitat_connectivity"] = ind.value
            elif "pollinator" in lower_name:
                start_vals["pollinator_network"] = ind.value
            elif "bird" in lower_name:
                start_vals["bird_network"] = ind.value

        start_vals["overall_health"] = round(sum(start_vals.values()) / len(start_vals), 1)

        # Retrieve selected actions
        selected_actions: list[RestorationAction] = []
        total_budget = 0.0
        net_impact_potential = {
            "plant_diversity": 0.0,
            "habitat_connectivity": 0.0,
            "pollinator_network": 0.0,
            "bird_network": 0.0
        }

        for act_id in request.action_ids:
            act = self.repo.get_action_by_id(act_id)
            if act:
                selected_actions.append(act)
                total_budget += act.total_estimated_budget_usd
                for k, v in act.impact_assumptions.items():
                    norm_k = "plant_diversity" if "plant" in k else (
                        "habitat_connectivity" if "connectivity" in k else (
                            "pollinator_network" if "pollinator" in k else "bird_network"
                        )
                    )
                    net_impact_potential[norm_k] += v

        # Factor in user budget scaling if provided
        scaling_factor = 1.0
        if request.budget_usd and total_budget > 0:
            scaling_factor = min(max(request.budget_usd / total_budget, 0.4), 1.5)

        for k in net_impact_potential:
            net_impact_potential[k] = net_impact_potential[k] * scaling_factor

        # S-curve Ecological realization factors across projection years (baseline 2025):
        # 2025: 0% realized
        # 2030 (5 yrs): ~30% realized (sapling establishment, initial colonization)
        # 2040 (15 yrs): ~75% realized (canopy closure, multi-generational breeding)
        # 2045 (20 yrs): ~95% realized (mature climax buffering)
        realization_weights = {
            2025: 0.0,
            2030: 0.32,
            2040: 0.78,
            2045: 0.95
        }

        # Baseline annual climate & fragmentation degradation rate (without intervention)
        baseline_drift_annual = -0.45  # points per year

        all_years = sorted(list(set([2025] + request.target_years)))

        baseline_points: list[YearPoint] = []
        restoration_points: list[YearPoint] = []

        for yr in all_years:
            delta_yrs = yr - 2025
            drift = delta_yrs * baseline_drift_annual

            # 1. Baseline trajectory (business as usual)
            b_plant = round(max(start_vals["plant_diversity"] + drift, 15.0), 1)
            b_conn = round(max(start_vals["habitat_connectivity"] + (drift * 1.2), 10.0), 1)
            b_poll = round(max(start_vals["pollinator_network"] + (drift * 0.9), 12.0), 1)
            b_bird = round(max(start_vals["bird_network"] + (drift * 0.8), 20.0), 1)
            b_overall = round((b_plant + b_conn + b_poll + b_bird) / 4.0, 1)

            baseline_points.append(YearPoint(
                year=yr,
                overall_health=b_overall,
                plant_diversity=b_plant,
                habitat_connectivity=b_conn,
                pollinator_network=b_poll,
                bird_network=b_bird
            ))

            # 2. Restoration trajectory with intervention
            r_weight = realization_weights.get(yr, min(delta_yrs / 20.0, 1.0))
            r_plant = round(min(start_vals["plant_diversity"] + (net_impact_potential["plant_diversity"] * r_weight), 98.0), 1)
            r_conn = round(min(start_vals["habitat_connectivity"] + (net_impact_potential["habitat_connectivity"] * r_weight), 98.0), 1)
            r_poll = round(min(start_vals["pollinator_network"] + (net_impact_potential["pollinator_network"] * r_weight), 98.0), 1)
            r_bird = round(min(start_vals["bird_network"] + (net_impact_potential["bird_network"] * r_weight), 98.0), 1)
            r_overall = round((r_plant + r_conn + r_poll + r_bird) / 4.0, 1)

            restoration_points.append(YearPoint(
                year=yr,
                overall_health=r_overall,
                plant_diversity=r_plant,
                habitat_connectivity=r_conn,
                pollinator_network=r_poll,
                bird_network=r_bird
            ))

        # Net improvement by 2045
        b_2045 = [p for p in baseline_points if p.year == 2045][0]
        r_2045 = [p for p in restoration_points if p.year == 2045][0]

        net_improvements = {
            "overall_health_delta": round(r_2045.overall_health - b_2045.overall_health, 1),
            "plant_diversity_delta": round(r_2045.plant_diversity - b_2045.plant_diversity, 1),
            "habitat_connectivity_delta": round(r_2045.habitat_connectivity - b_2045.habitat_connectivity, 1),
            "pollinator_network_delta": round(r_2045.pollinator_network - b_2045.pollinator_network, 1),
            "bird_network_delta": round(r_2045.bird_network - b_2045.bird_network, 1)
        }

        assumptions = [
            "Projections are deterministic scenario simulations based on documented growth curves and peer-reviewed tropical restoration timelines.",
            "Non-linear ecological lag model: 32% realized by 2030, 78% by 2040, 95% mature equilibrium by 2045.",
            "Baseline 'Business-as-Usual' trajectory incorporates -0.45 pt/year continuous degradation drift from anthropogenic edge pressures.",
            "Outputs are illustrative decision-support scenarios and do not constitute absolute ecological prophecies."
        ]

        return ScenarioResponse(
            area_id=area_id,
            ecosystem_name=area.name,
            scenario_name=request.scenario_name,
            selected_actions=selected_actions,
            total_budget_usd=total_budget * scaling_factor,
            baseline_trajectory=ScenarioTrajectory(
                scenario_type="baseline",
                label="Baseline: Status Quo (No Intervention)",
                description="Continued habitat fragmentation, edge desiccation, and gradual decline in connectivity and pollinator density.",
                projections=baseline_points
            ),
            restoration_trajectory=ScenarioTrajectory(
                scenario_type="intervention",
                label="Restoration Strategy Active",
                description="Implemented ecological interventions progressively expanding native vegetation, corridors, and mutualist networks.",
                projections=restoration_points
            ),
            net_improvement_2045=net_improvements,
            assumptions_and_limitations=assumptions
        )

scenario_service = ScenarioService()
