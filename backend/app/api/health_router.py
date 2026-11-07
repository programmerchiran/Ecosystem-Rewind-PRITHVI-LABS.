from fastapi import APIRouter, HTTPException
from backend.app.services.health_service import health_service
from backend.app.schemas.models import AreaSummary

router = APIRouter(tags=["Ecosystem Health Dashboard"])

@router.get("/areas/{area_id}/summary", response_model=AreaSummary)
def get_area_summary(area_id: str):
    """Retrieve comprehensive health summary and indicators for the selected ecosystem area."""
    summary = health_service.get_area_health_summary(area_id)
    if not summary:
        raise HTTPException(status_code=404, detail=f"Ecosystem summary for area '{area_id}' not found.")
    return summary
