
from pathlib import Path

import numpy as np
import pandas as pd

BASE = Path(__file__).resolve().parent.parent
DATA_DIR = BASE / "data" / "processed"

INPUT = DATA_DIR / "india_gbif_plants_clean.csv"
GRID = DATA_DIR / "india_forest_features_v7_soil.csv"

OUTPUT = DATA_DIR / "india_gbif_biodiversity_5km.csv"

print("Loading cleaned GBIF occurrences...")
gbif = pd.read_csv(INPUT)

print("Loading NRSC reference grid...")
grid = pd.read_csv(GRID, usecols=["row", "col"])

# Reference grid dimensions and projection parameters.
WIDTH = 583
HEIGHT = 654
XLL = 995000.0
YLL = 615000.0
CELL = 5000.0

# Transform longitude/latitude into the NRSC Albers projection.
from pyproj import Transformer

transformer = Transformer.from_crs(
    "EPSG:4326",
    "+proj=aea +lat_0=20 +lon_0=78 "
    "+lat_1=28 +lat_2=12 "
    "+x_0=2000000 +y_0=2000000 "
    "+datum=WGS84 +units=m +no_defs",
    always_xy=True,
)

x, y = transformer.transform(
    gbif["decimalLongitude"].to_numpy(),
    gbif["decimalLatitude"].to_numpy(),
)

# Convert projected coordinates to raster indices.
gbif["col"] = np.floor((x - XLL) / CELL).astype("int64")
gbif["row"] = np.floor((YLL + HEIGHT * CELL - y) / CELL).astype("int64")

# Keep only coordinates inside the reference raster.
inside = (
    gbif["row"].between(0, HEIGHT - 1)
    & gbif["col"].between(0, WIDTH - 1)
)

gbif = gbif.loc[inside].copy()

print("Occurrences inside NRSC grid:", len(gbif))

# Aggregate observed biodiversity by grid cell.
summary = (
    gbif.groupby(["row", "col"])
    .agg(
        gbif_occurrence_records=("gbifID", "nunique"),
        gbif_unique_species=("species", "nunique"),
        gbif_unique_genera=("genus", "nunique"),
        gbif_unique_families=("family", "nunique"),
    )
    .reset_index()
)

# Preserve every grid cell, including cells with no records.
result = grid.merge(
    summary,
    on=["row", "col"],
    how="left",
    validate="one_to_one",
)

count_columns = [
    "gbif_occurrence_records",
    "gbif_unique_species",
    "gbif_unique_genera",
    "gbif_unique_families",
]

result[count_columns] = result[count_columns].fillna(0).astype("int64")

print("\n--- BIODIVERSITY GRID REPORT ---")
print("Total grid cells:", len(result))
print("Grid cells with observations:", int((result["gbif_occurrence_records"] > 0).sum()))
print("Grid cells without observations:", int((result["gbif_occurrence_records"] == 0).sum()))
print("Total unique species across grid:", gbif["species"].nunique())
print("Total occurrence records inside grid:", len(gbif))

print("\nTop 10 grid cells by observed species:")
print(
    result.nlargest(10, "gbif_unique_species")[
        ["row", "col", "gbif_unique_species", "gbif_occurrence_records"]
    ].to_string(index=False)
)

result.to_csv(OUTPUT, index=False)

print("\nSaved:", OUTPUT)
print("Biodiversity grid preparation completed.")
