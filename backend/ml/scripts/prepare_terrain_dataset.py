
from pathlib import Path

import numpy as np
import pandas as pd
import rasterio

BASE = Path(__file__).resolve().parent.parent

DATA_DIR = BASE / "data" / "processed"

CSV_INPUT = DATA_DIR / "india_forest_features_v5_climate.csv"
RASTER_INPUT = DATA_DIR / "india_terrain_features_aligned_5km.tif"
CSV_OUTPUT = DATA_DIR / "india_forest_features_v6_terrain.csv"

print("Loading forest and climate dataset...")
df = pd.read_csv(CSV_INPUT)

print("Loading aligned terrain raster...")
with rasterio.open(RASTER_INPUT) as src:

    if src.count < 2:
        raise ValueError("Terrain raster must contain at least 2 bands.")

    if src.width != 583 or src.height != 654:
        raise ValueError(
            f"Unexpected raster dimensions: {src.width} x {src.height}"
        )

    if src.descriptions[0] != "elevation_m":
        raise ValueError(f"Unexpected band 1: {src.descriptions[0]}")

    if src.descriptions[1] != "slope_degrees":
        raise ValueError(f"Unexpected band 2: {src.descriptions[1]}")

    rows = df["row"].to_numpy(dtype=np.int64)
    cols = df["col"].to_numpy(dtype=np.int64)

    if (
        (rows < 0).any()
        or (rows >= src.height).any()
        or (cols < 0).any()
        or (cols >= src.width).any()
    ):
        raise ValueError("CSV contains row/col indices outside raster bounds.")

    if df.duplicated(subset=["row", "col"]).any():
        raise ValueError("Duplicate row/col grid positions found in CSV.")

    elevation = src.read(1, masked=True)
    slope = src.read(2, masked=True)

    elevation_values = np.asarray(elevation.filled(np.nan), dtype=np.float32)
    slope_values = np.asarray(slope.filled(np.nan), dtype=np.float32)

    df["elevation_m"] = elevation_values[rows, cols]
    df["slope_degrees"] = slope_values[rows, cols]

# Convert invalid values to proper missing values.
df["elevation_m"] = df["elevation_m"].replace(
    [np.inf, -np.inf], np.nan
)
df["slope_degrees"] = df["slope_degrees"].replace(
    [np.inf, -np.inf], np.nan
)

# Basic quality checks.
forest_mask = df["forest_fraction_2013_raw"] > 0

print("\n--- TERRAIN MERGE QUALITY REPORT ---")
print("Total CSV rows:", len(df))
print("Forest grid cells:", int(forest_mask.sum()))

for column in ["elevation_m", "slope_degrees"]:
    valid = df[column].notna()

    print(f"\n{column}")
    print("Valid cells:", int(valid.sum()))
    print("Missing cells:", int((~valid).sum()))
    print("Valid forest cells:", int((valid & forest_mask).sum()))

    if valid.any():
        print("Minimum:", round(float(df.loc[valid, column].min()), 3))
        print("Maximum:", round(float(df.loc[valid, column].max()), 3))
        print("Mean:", round(float(df.loc[valid, column].mean()), 3))

# Save as a new file. Original v5 remains unchanged.
df.to_csv(CSV_OUTPUT, index=False)

print("\nSaved:", CSV_OUTPUT)
print("Output dimensions:", df.shape)
print("\nTerrain feature integration completed.")
