
from typing import Optional

from fastapi import APIRouter, HTTPException, Query

from backend.app.services.habitat_service import habitat_service


router = APIRouter(
    prefix="/v1/habitat",
    tags=["Teak Habitat Suitability"],
)


@router.get("/summary")
def get_habitat_summary():
    """Return nationwide teak habitat suitability statistics."""

    try:
        return habitat_service.get_summary()

    except (FileNotFoundError, ValueError) as exc:
        raise HTTPException(
            status_code=500,
            detail=str(exc),
        )


@router.get("/cells")
def get_habitat_cells(
    suitability_class: Optional[str] = Query(
        None,
        alias="class",
        description="Filter by Very Low, Low, Moderate, High or Very High",
    ),
    limit: int = Query(1000, ge=1, le=5000),
    offset: int = Query(0, ge=0),
    min_lat: Optional[float] = Query(None, ge=-90, le=90),
    max_lat: Optional[float] = Query(None, ge=-90, le=90),
    min_lon: Optional[float] = Query(None, ge=-180, le=180),
    max_lon: Optional[float] = Query(None, ge=-180, le=180),
):
    """Return paginated teak suitability grid cells."""

    if min_lat is not None and max_lat is not None:
        if min_lat > max_lat:
            raise HTTPException(
                status_code=400,
                detail="min_lat cannot exceed max_lat",
            )

    if min_lon is not None and max_lon is not None:
        if min_lon > max_lon:
            raise HTTPException(
                status_code=400,
                detail="min_lon cannot exceed max_lon",
            )

    try:
        return habitat_service.get_cells(
            suitability_class=suitability_class,
            limit=limit,
            offset=offset,
            min_lat=min_lat,
            max_lat=max_lat,
            min_lon=min_lon,
            max_lon=max_lon,
        )

    except ValueError as exc:
        raise HTTPException(
            status_code=400,
            detail=str(exc),
        )

    except (FileNotFoundError, OSError) as exc:
        raise HTTPException(
            status_code=500,
            detail=str(exc),
        )
