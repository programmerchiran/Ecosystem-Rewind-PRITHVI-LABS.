from fastapi import APIRouter, HTTPException
from backend.app.services.domino_service import domino_service
from backend.app.schemas.models import DominoSimulationRequest, DominoSimulationResult

router = APIRouter(tags=["Ecological Domino Simulator"])

@router.post("/areas/{area_id}/simulate", response_model=DominoSimulationResult)
def simulate_species_loss(area_id: str, request: DominoSimulationRequest):
    """Simulate the removal of a species from the ecosystem graph and evaluate cascading trophic impacts."""
    result = domino_service.simulate_species_removal(area_id, request)
    if not result:
        raise HTTPException(
            status_code=404,
            detail=f"Simulation failed. Ensure area '{area_id}' and species '{request.species_id}' exist."
        )
    return result
