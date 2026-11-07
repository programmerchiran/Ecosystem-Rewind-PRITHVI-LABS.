import copy
import networkx as nx
from typing import Optional
from backend.app.repositories.ecosystem_repository import EcosystemRepository, ecosystem_repo
from backend.app.schemas.models import (
    DominoSimulationRequest,
    DominoSimulationResult,
    AffectedNodeInfo,
    Species,
)
from backend.app.services.network_service import NetworkService, network_service

class DominoService:
    def __init__(self, repo: EcosystemRepository = ecosystem_repo, net_service: NetworkService = network_service):
        self.repo = repo
        self.net_service = net_service

    def simulate_species_removal(
        self,
        area_id: str,
        request: DominoSimulationRequest
    ) -> Optional[DominoSimulationResult]:
        area = self.repo.get_area(area_id)
        if not area:
            return None

        species = self.repo.get_species(area_id, request.species_id)
        if not species:
            return None

        # 1. Load original graph and build baseline
        base_G = self.net_service.build_networkx_graph(area_id)
        before_response = self.net_service._format_graph_response(area_id, area.name, base_G)

        # 2. Work on an independent, deep copy
        sim_G = copy.deepcopy(base_G)

        if not sim_G.has_node(request.species_id):
            return None

        # 3. Analyze direct neighbors and incident edges before removal
        in_edges = list(sim_G.in_edges(request.species_id, data=True))
        out_edges = list(sim_G.out_edges(request.species_id, data=True))
        all_incident_edges = in_edges + out_edges
        direct_links_count = len(all_incident_edges)

        direct_neighbors = set(sim_G.predecessors(request.species_id)).union(set(sim_G.successors(request.species_id)))

        # 4. Assess impact on neighbors based on transparent dependency rules
        potentially_affected: list[AffectedNodeInfo] = []
        applied_rules = [
            f"Species '{species.common_name}' ({species.scientific_name}) was systematically removed from the ecosystem graph.",
            "Independent graph copy isolated from master baseline; baseline graph remains immutable.",
            "Trophic / Mutualism Dependency Propagation: Evaluates relative dependency weight and remaining redundant food/pollination/habitat links.",
            "Cascade Threshold: Triggered if remaining support links drop by >= 40% or if an obligate keystone dependency is broken."
        ]

        for neighbor_id in direct_neighbors:
            neighbor_sp = self.repo.get_species(area_id, neighbor_id)
            if not neighbor_sp:
                continue

            # Check edges between removed species and neighbor
            lost_deps = []
            max_dep_weight = 0.0

            # Edges where neighbor was source (e.g., neighbor depended on removed species for food or nesting)
            for u, v, d in out_edges:
                if v == neighbor_id:
                    itype = d.get("interaction_type", "trophic")
                    weight = d.get("dependency_weight", 0.6)
                    lost_deps.append(f"{itype} (dependency weight: {weight})")
                    if weight > max_dep_weight:
                        max_dep_weight = weight

            for u, v, d in in_edges:
                if u == neighbor_id:
                    itype = d.get("interaction_type", "trophic")
                    weight = d.get("dependency_weight", 0.6)
                    lost_deps.append(f"{itype} (dependency weight: {weight})")
                    if weight > max_dep_weight:
                        max_dep_weight = weight

            # Total remaining degrees for neighbor
            deg_before = base_G.degree(neighbor_id)
            fraction_lost = len(lost_deps) / max(deg_before, 1)

            if fraction_lost >= 0.7 or max_dep_weight >= 0.85:
                level = "Critical"
                rationale = f"Severe disruption: Lost {len(lost_deps)} core ecological link(s) representing {int(fraction_lost * 100)}% of its known network interactions."
            elif fraction_lost >= 0.4 or max_dep_weight >= 0.65:
                level = "High"
                rationale = f"Significant stress: Lost primary interaction partner ({lost_deps[0] if lost_deps else 'trophic'}). May shift foraging behavior or experience localized decline."
            else:
                level = "Moderate"
                rationale = f"Noticeable effect: Lost secondary or opportunistic link ({lost_deps[0] if lost_deps else 'interaction'}); alternate ecological partners remain present."

            potentially_affected.append(AffectedNodeInfo(
                species_id=neighbor_id,
                common_name=neighbor_sp.common_name,
                scientific_name=neighbor_sp.scientific_name,
                group=neighbor_sp.group,
                impact_level=level,
                impact_rationale=rationale,
                lost_dependencies=lost_deps
            ))

        # 5. Remove node from simulated copy
        sim_G.remove_node(request.species_id)

        # 6. Check for newly isolated nodes
        isolated_species: list[str] = []
        for n in sim_G.nodes():
            if sim_G.degree(n) == 0:
                iso_sp = self.repo.get_species(area_id, n)
                isolated_species.append(iso_sp.common_name if iso_sp else n)

        if isolated_species:
            applied_rules.append(f"Newly orphaned/isolated species detected: {', '.join(isolated_species)} (0 remaining active interactions in modeled dataset).")
        else:
            applied_rules.append("No newly isolated nodes: Remaining species retain secondary connections within the broader food web.")

        # 7. Calculate modified metrics
        after_response = self.net_service._format_graph_response(area_id, area.name, sim_G)

        # 8. Domino Shock Score Calculation
        # Normalized score based on:
        # - Degree fraction removed
        # - Criticality of removed species
        # - Number of critical/high affected nodes
        # - Change in density and components
        critical_count = sum(1 for a in potentially_affected if a.impact_level in ["Critical", "High"])
        keystone_boost = 25.0 if species.observation_status.lower() == "keystone" or species.dependency_criticality > 0.85 else 10.0
        isolation_penalty = len(isolated_species) * 12.0
        affected_ratio = (len(potentially_affected) / max(len(base_G.nodes()) - 1, 1)) * 40.0

        raw_score = keystone_boost + (critical_count * 8.0) + isolation_penalty + affected_ratio
        domino_impact_score = round(min(max(raw_score, 12.0), 98.0), 1)

        explanation = (
            f"Simulating the removal of {species.common_name} ({species.scientific_name}) removed {direct_links_count} direct ecological relationships, "
            f"inducing structural stress on {len(potentially_affected)} associated species. "
            f"{critical_count} dependent species face severe ecological shock. "
            f"Overall Community Domino Impact Score is evaluated at {domino_impact_score}/100."
        )

        return DominoSimulationResult(
            area_id=area_id,
            removed_species=species,
            direct_relationships_removed=direct_links_count,
            potentially_affected_species=potentially_affected,
            isolated_species=isolated_species,
            domino_impact_score=domino_impact_score,
            before_metrics=before_response.metrics,
            after_metrics=after_response.metrics,
            applied_rules_and_assumptions=applied_rules,
            explanation=explanation,
            modified_network=after_response
        )

domino_service = DominoService()
