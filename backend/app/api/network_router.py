from typing import Optional
from fastapi import APIRouter, HTTPException, Query
from backend.app.repositories.ecosystem_repository import ecosystem_repo
from backend.app.services.network_service import network_service
from backend.app.schemas.models import NetworkGraphResponse, Species

router = APIRouter(tags=["Species & Interactive Network"])

@router.get("/areas/{area_id}/species", response_model=list[Species])
def get_species_for_area(area_id: str, group: Optional[str] = Query(None, description="Filter by species group")):
    """List all species documented in the selected area, with optional taxonomic group filtering."""
    if not ecosystem_repo.get_area(area_id):
        raise HTTPException(status_code=404, detail=f"Ecosystem area '{area_id}' not found.")
    return ecosystem_repo.list_species(area_id, group=group)

@router.get("/areas/{area_id}/network", response_model=NetworkGraphResponse)
def get_network_graph(area_id: str):
    """Retrieve full interactive species network graph with centrality metrics and ecological edges."""
    graph = network_service.get_network_graph(area_id)
    if not graph:
        raise HTTPException(status_code=404, detail=f"Network graph for area '{area_id}' not found.")
    return graph
