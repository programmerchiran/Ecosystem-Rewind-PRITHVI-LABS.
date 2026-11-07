
from pathlib import Path

import numpy as np
import pandas as pd
import rasterio

BASE = Path(__file__).resolve().parent.parent
DATA_DIR = BASE / "data" / "processed"

CSV_INPUT = DATA_DIR / "india_forest_features_v6_terrain.csv"
RASTER_INPUT = DATA_DIR / "india_soil_features_aligned_5km.tif"
CSV_OUTPUT = DATA_DIR / "india_forest_features_v7_soil.csv"

SOIL_COLUMNS = [
    "soil_organic_carbon_g_kg",
    "soil_ph",
    "clay_percent",
    "sand_percent",
]

print("Loading v6 forest, climate and terrain dataset...")
df = pd.read_csv(CSV_INPUT)

print("Loading aligned SoilGrids raster...")

with rasterio.open(RASTER_INPUT) as src:

    if src.count != 4:
        raise ValueError(
            f"Expected 4 soil bands, found {src.count}"
        )

    if src.width != 583 or src.height != 654:
        raise ValueError(
            f"Unexpected raster dimensions: {src.width} x {src.height}"
        )

    rows = df["row"].to_numpy(dtype=np.int64)
    cols = df["col"].to_numpy(dtype=np.int64)

    if (
        (rows < 0).any()
        or (rows >= src.height).any()
        or (cols < 0).any()
        or (cols >= src.width).any()
    ):
        raise ValueError("CSV grid indices exceed raster dimensions.")

    if df.duplicated(subset=["row", "col"]).any():
        raise ValueError("Duplicate row/col positions found.")

    for band_number, column in enumerate(SOIL_COLUMNS, start=1):
        band = src.read(band_number, masked=True)
        values = np.asarray(
            band.filled(np.nan),
            dtype=np.float32
        )

        df[column] = values[rows, cols]

        df[column] = df[column].replace(
            [np.inf, -np.inf], np.nan
        )

forest_mask = df["forest_fraction_2013_raw"] > 0

print("\n--- SOIL DATA QUALITY REPORT ---")
print("Total grid cells:", len(df))
print("Forest grid cells:", int(forest_mask.sum()))

for column in SOIL_COLUMNS:
    valid = df[column].notna()

    print(f"\n{column}")
    print("Valid cells:", int(valid.sum()))
    print("Missing cells:", int((~valid).sum()))
    print("Valid forest cells:", int((valid & forest_mask).sum()))

    if valid.any():
        print("Minimum:", round(float(df.loc[valid, column].min()), 3))
        print("Maximum:", round(float(df.loc[valid, column].max()), 3))
        print("Mean:", round(float(df.loc[valid, column].mean()), 3))

# Save a new version without modifying v6.
df.to_csv(CSV_OUTPUT, index=False)

print("\nSaved:", CSV_OUTPUT)
print("Output dimensions:", df.shape)
print("Soil integration completed.")
