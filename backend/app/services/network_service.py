import networkx as nx
from typing import Optional
from backend.app.repositories.ecosystem_repository import EcosystemRepository, ecosystem_repo
from backend.app.schemas.models import (
    NetworkGraphResponse,
    NetworkNode,
    NetworkEdge,
    NetworkMetrics,
)

class NetworkService:
    def __init__(self, repo: EcosystemRepository = ecosystem_repo):
        self.repo = repo

    def build_networkx_graph(self, area_id: str) -> nx.DiGraph:
        """Constructs a NetworkX DiGraph populated with species attributes and interaction edges."""
        species_list = self.repo.list_species(area_id)
        interactions = self.repo.list_interactions(area_id)

        G = nx.DiGraph()
        for sp in species_list:
            G.add_node(
                sp.species_id,
                common_name=sp.common_name,
                scientific_name=sp.scientific_name,
                group=sp.group,
                status=sp.observation_status,
                trophic_level=sp.trophic_level,
                description=sp.description,
                dependency_criticality=sp.dependency_criticality
            )

        for edge in interactions:
            G.add_edge(
                edge.source_species_id,
                edge.target_species_id,
                interaction_id=edge.interaction_id,
                interaction_type=edge.interaction_type,
                strength=edge.strength,
                dependency_weight=edge.dependency_weight,
                direction=edge.direction
            )
            # If bidirectional, add reciprocal edge for flow calculations
            if edge.direction == "bidirectional":
                G.add_edge(
                    edge.target_species_id,
                    edge.source_species_id,
                    interaction_id=f"{edge.interaction_id}_rev",
                    interaction_type=edge.interaction_type,
                    strength=edge.strength,
                    dependency_weight=edge.dependency_weight,
                    direction=edge.direction
                )

        return G

    def get_network_graph(self, area_id: str) -> Optional[NetworkGraphResponse]:
        area = self.repo.get_area(area_id)
        if not area:
            return None

        G = self.build_networkx_graph(area_id)
        return self._format_graph_response(area_id, area.name, G)

    def _format_graph_response(self, area_id: str, area_name: str, G: nx.DiGraph) -> NetworkGraphResponse:
        undirected_G = G.to_undirected()
        
        # Calculate centrality and metrics
        try:
            pagerank_dict = nx.pagerank(G, weight="strength") if len(G) > 0 else {}
        except Exception:
            pagerank_dict = {n: 0.1 for n in G.nodes()}

        try:
            betweenness_dict = nx.betweenness_centrality(undirected_G) if len(undirected_G) > 0 else {}
        except Exception:
            betweenness_dict = {n: 0.0 for n in G.nodes()}

        nodes: list[NetworkNode] = []
        groups_set: set[str] = set()

        for node_id, data in G.nodes(data=True):
            group = data.get("group", "Unknown")
            groups_set.add(group)
            status = data.get("status", "Common")
            is_keystone = "keystone" in status.lower() or data.get("dependency_criticality", 0) > 0.85

            nodes.append(NetworkNode(
                id=node_id,
                label=data.get("common_name", node_id),
                scientific_name=data.get("scientific_name", ""),
                group=group,
                status=status,
                trophic_level=data.get("trophic_level", "Unknown"),
                degree=G.degree(node_id),
                in_degree=G.in_degree(node_id),
                out_degree=G.out_degree(node_id),
                pagerank=round(pagerank_dict.get(node_id, 0.0), 4),
                betweenness=round(betweenness_dict.get(node_id, 0.0), 4),
                is_keystone=is_keystone,
                description=data.get("description", "")
            ))

        edges: list[NetworkEdge] = []
        interaction_types: set[str] = set()
        seen_edges: set[tuple[str, str, str]] = set()

        for u, v, data in G.edges(data=True):
            itype = data.get("interaction_type", "trophic")
            interaction_types.add(itype)
            edge_key = (u, v, itype)
            if edge_key not in seen_edges:
                seen_edges.add(edge_key)
                edges.append(NetworkEdge(
                    id=data.get("interaction_id", f"{u}_{v}"),
                    source=u,
                    target=v,
                    interaction_type=itype,
                    strength=round(data.get("strength", 0.5), 2),
                    dependency_weight=round(data.get("dependency_weight", 0.5), 2),
                    direction=data.get("direction", "directed")
                ))

        total_nodes = len(G.nodes())
        total_edges = len(edges)
        density = round(nx.density(G), 3) if total_nodes > 1 else 0.0
        clustering = round(nx.average_clustering(undirected_G), 3) if total_nodes > 1 else 0.0
        connected_comp = nx.number_connected_components(undirected_G) if total_nodes > 0 else 0

        metrics = NetworkMetrics(
            total_nodes=total_nodes,
            total_edges=total_edges,
            graph_density=density,
            average_clustering=clustering,
            connected_components=connected_comp
        )

        return NetworkGraphResponse(
            area_id=area_id,
            ecosystem_name=area_name,
            nodes=nodes,
            edges=edges,
            metrics=metrics,
            groups=sorted(list(groups_set)),
            interaction_types=sorted(list(interaction_types))
        )

network_service = NetworkService()
