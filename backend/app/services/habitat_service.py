
from functools import lru_cache
from pathlib import Path

import pandas as pd
from pyproj import Transformer


# --------------------------------------------------
# PATHS AND GRID CONFIGURATION
# --------------------------------------------------

BASE_DIR = Path(__file__).resolve().parents[2]

PREDICTION_FILE = (
    BASE_DIR
    / "ml"
    / "data"
    / "processed"
    / "india_teak_habitat_suitability_v1.csv"
)

GRID_X_ORIGIN = 995000
GRID_Y_TOP = 3885000
GRID_CELL_SIZE = 5000

ALBERS_CRS = (
    "+proj=aea +lat_0=20 +lon_0=78 "
    "+lat_1=28 +lat_2=12 "
    "+x_0=2000000 +y_0=2000000 "
    "+datum=WGS84 +units=m +no_defs"
)

SUITABILITY_CLASSES = [
    "Very Low",
    "Low",
    "Moderate",
    "High",
    "Very High",
]


# --------------------------------------------------
# LOAD PREDICTIONS ONCE
# --------------------------------------------------

@lru_cache(maxsize=1)
def load_habitat_data():
    if not PREDICTION_FILE.exists():
        raise FileNotFoundError(
            f"Habitat prediction file not found: {PREDICTION_FILE}"
        )

    df = pd.read_csv(PREDICTION_FILE)

    required_columns = [
        "row",
        "col",
        "teak_suitability_score",
        "teak_suitability_index",
        "suitability_class",
    ]

    missing = [
        col for col in required_columns
        if col not in df.columns
    ]

    if missing:
        raise ValueError(
            f"Prediction file is missing columns: {missing}"
        )

    if df[required_columns].isna().any().any():
        raise ValueError(
            "Prediction file contains missing required values."
        )

    if df.duplicated(["row", "col"]).any():
        raise ValueError(
            "Duplicate grid cells found in prediction file."
        )

    if not df["teak_suitability_score"].between(0, 1).all():
        raise ValueError(
            "Suitability scores must be between 0 and 1."
        )

    # Convert 5 km grid-cell centres from Albers to WGS84.
    x = (
        GRID_X_ORIGIN
        + (df["col"].to_numpy() + 0.5) * GRID_CELL_SIZE
    )

    y = (
        GRID_Y_TOP
        - (df["row"].to_numpy() + 0.5) * GRID_CELL_SIZE
    )

    transformer = Transformer.from_crs(
        ALBERS_CRS,
        "EPSG:4326",
        always_xy=True,
    )

    longitude, latitude = transformer.transform(x, y)

    df["longitude"] = longitude
    df["latitude"] = latitude

    return df


# --------------------------------------------------
# SUMMARY
# --------------------------------------------------

class HabitatService:

    def get_summary(self):
        df = load_habitat_data()

        class_counts = (
            df["suitability_class"]
            .value_counts()
            .reindex(SUITABILITY_CLASSES, fill_value=0)
        )

        return {
            "species": "Tectona grandis",
            "species_common_name": "Teak",
            "model": "Random Forest",
            "prediction_type": "Relative habitat suitability",
            "total_predicted_cells": int(len(df)),
            "mean_suitability_score": round(
                float(df["teak_suitability_score"].mean()), 4
            ),
            "min_suitability_score": round(
                float(df["teak_suitability_score"].min()), 4
            ),
            "max_suitability_score": round(
                float(df["teak_suitability_score"].max()), 4
            ),
            "class_distribution": {
                name: int(class_counts[name])
                for name in SUITABILITY_CLASSES
            },
            "grid_resolution_m": GRID_CELL_SIZE,
            "disclaimer": (
                "Exploratory presence-background model. "
                "Scores are not calibrated probabilities of "
                "wild teak occurrence. Background locations "
                "are not confirmed absences."
            ),
        }

    # --------------------------------------------------
    # MAP CELLS
    # --------------------------------------------------

    def get_cells(
        self,
        suitability_class=None,
        limit=1000,
        offset=0,
        min_lat=None,
        max_lat=None,
        min_lon=None,
        max_lon=None,
    ):
        df = load_habitat_data()

        filtered = df

        if suitability_class:
            if suitability_class not in SUITABILITY_CLASSES:
                raise ValueError(
                    f"Invalid suitability class: {suitability_class}"
                )

            filtered = filtered[
                filtered["suitability_class"] == suitability_class
            ]

        # Optional geographic bounding-box filter.
        if min_lat is not None:
            filtered = filtered[
                filtered["latitude"] >= min_lat
            ]

        if max_lat is not None:
            filtered = filtered[
                filtered["latitude"] <= max_lat
            ]

        if min_lon is not None:
            filtered = filtered[
                filtered["longitude"] >= min_lon
            ]

        if max_lon is not None:
            filtered = filtered[
                filtered["longitude"] <= max_lon
            ]

        total = len(filtered)

        page = filtered.iloc[offset:offset + limit]

        cells = page[
            [
                "row",
                "col",
                "latitude",
                "longitude",
                "teak_suitability_score",
                "teak_suitability_index",
                "suitability_class",
            ]
        ].to_dict(orient="records")

        return {
            "total": int(total),
            "limit": limit,
            "offset": offset,
            "cells": cells,
        }


habitat_service = HabitatService()
