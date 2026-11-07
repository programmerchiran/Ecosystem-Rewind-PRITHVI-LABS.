
from pathlib import Path
import pandas as pd
import numpy as np

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data" / "processed"

INPUT = DATA_DIR / "teak_habitat_training_v1.csv"

df = pd.read_csv(INPUT)

predictors = [
    f"bio_{i:02d}" for i in range(1, 20)
] + [
    "elevation_m",
    "slope_degrees",
    "soil_organic_carbon_g_kg",
    "soil_ph",
    "clay_percent",
    "sand_percent",
] + [
    f"forest_type_class_{i:02d}_candidate"
    for i in range(1, 15)
]

print("\n--- DATASET AUDIT ---")
print("Rows:", len(df))
print("Predictors:", len(predictors))
print("Missing predictor values:", df[predictors].isna().sum().sum())

print("\n--- LABEL DISTRIBUTION ---")
print(df["presence"].value_counts().to_string())

print("\n--- PRESENCE/BACKGROUND RATIO ---")
print(
    "Presence percentage:",
    round(df["presence"].mean() * 100, 3),
    "%"
)

print("\n--- PREDICTOR SUMMARY ---")
print(df[predictors].describe().T.to_string())

print("\n--- SPATIAL DISTRIBUTION ---")
df["block_id"] = (
    (df["row"] // 10).astype(str)
    + "_"
    + (df["col"] // 10).astype(str)
)

occupied = df[df["presence"] == 1]

print("Occupied cells:", len(occupied))
print("Occupied blocks:", occupied["block_id"].nunique())
print("Background blocks:", df.loc[df["presence"] == 0, "block_id"].nunique())

print("\n--- AUDIT COMPLETE ---")
