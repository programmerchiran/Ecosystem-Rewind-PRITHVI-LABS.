from typing import Optional
from fastapi import APIRouter, HTTPException, Query
from backend.app.services.recommendation_service import recommendation_service
from backend.app.schemas.models import RecommendationResponse

router = APIRouter(tags=["Restoration Recommendations"])

@router.get("/areas/{area_id}/recommendations", response_model=RecommendationResponse)
def get_recommendations(
    area_id: str,
    max_budget: Optional[float] = Query(None, description="Optional maximum total budget limit in USD")
):
    """Retrieve prioritized, rule-based restoration actions tailored to the ecological conditions of the area."""
    recs = recommendation_service.get_recommendations_for_area(area_id, max_budget=max_budget)
    if not recs:
        raise HTTPException(status_code=404, detail=f"Ecosystem recommendations for area '{area_id}' not found.")
    return recs
