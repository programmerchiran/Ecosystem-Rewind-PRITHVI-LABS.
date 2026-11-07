from fastapi import APIRouter, HTTPException
from backend.app.repositories.ecosystem_repository import ecosystem_repo
from backend.app.schemas.models import EcosystemArea

router = APIRouter(tags=["Ecosystem Areas"])

@router.get("/areas", response_model=list[EcosystemArea])
def list_areas():
    """Retrieve all supported study areas with geographic boundaries and metadata."""
    return ecosystem_repo.list_areas()

@router.get("/areas/{area_id}", response_model=EcosystemArea)
def get_area(area_id: str):
    """Retrieve a single ecosystem area by its unique identifier."""
    area = ecosystem_repo.get_area(area_id)
    if not area:
        raise HTTPException(status_code=404, detail=f"Ecosystem area '{area_id}' not found.")
    return area
