
from pathlib import Path
import pandas as pd

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data" / "processed"

INPUT = DATA_DIR / "india_ecosystem_master_v1.csv"
OUTPUT = DATA_DIR / "india_forest_modeling_base_v1.csv"

print("Loading master ecosystem dataset...")
df = pd.read_csv(INPUT)

# Select cells identified as forest in the 2013 NRSC layer.
forest = df.loc[
    df["forest_fraction_2013_raw"] > 0
].copy()

# Validate grid keys.
keys = ["row", "col"]

if forest[keys].isna().any().any():
    raise ValueError("Missing grid coordinates found.")

if forest.duplicated(keys).any():
    raise ValueError("Duplicate forest grid cells found.")

# Preserve all source columns and missing values.
forest = forest.sort_values(keys).reset_index(drop=True)

forest.to_csv(OUTPUT, index=False)

print("\n--- FOREST MODELING BASE REPORT ---")
print("Rows:", len(forest))
print("Columns:", len(forest.columns))
print("Missing values:", int(forest.isna().sum().sum()))
print("Duplicate grid cells:", int(forest.duplicated(keys).sum()))

print("\n--- FEATURE GROUPS ---")
groups = {
    "Forest cover and types": [
        c for c in forest.columns
        if c.startswith("forest_")
    ],
    "Fire": [
        c for c in forest.columns
        if c.startswith("fire_")
    ],
    "Climate": [
        c for c in forest.columns
        if c.startswith("bio_")
    ],
    "Terrain": ["elevation_m", "slope_degrees"],
    "Soil": [
        "soil_organic_carbon_g_kg",
        "soil_ph",
        "clay_percent",
        "sand_percent"
    ],
    "Biodiversity observations": [
        c for c in forest.columns
        if c.startswith("gbif_")
    ]
}

for group, columns in groups.items():
    print(f"{group}: {len(columns)} columns")

print("\nSaved:", OUTPUT)
print("Forest modeling base preparation completed.")
