
import pandas as pd
import numpy as np

path = (
    "backend/ml/data/processed/"
    "india_nrsc_forest_fire_features_5km.csv"
)

df = pd.read_csv(path)

forest_cols = [
    c for c in df.columns
    if c.startswith("forest_type_class_")
]

print("\n========== FOREST FRACTION ==========")

print(df["forest_fraction_2013_raw"].describe(
    percentiles=[0.1, 0.25, 0.5, 0.75, 0.9, 0.95, 0.99]
))

print("\n========== FOREST TYPE VALUES ==========")

for col in forest_cols:
    print(
        col,
        "min =", df[col].min(),
        "max =", df[col].max(),
        "nonzero =", (df[col] > 0).sum()
    )

print("\n========== SUM OF FOREST TYPE LAYERS ==========")

df["forest_type_sum"] = df[forest_cols].sum(axis=1)

print(df["forest_type_sum"].describe())

print("\n========== COMPARE FOREST FRACTION AND TYPE SUM ==========")

print(
    df[
        ["forest_fraction_2013_raw", "forest_type_sum"]
    ].corr()
)

print("\n========== FIRE COVERAGE ==========")

for col in ["fire_afd_raw", "fire_lfp_raw", "fire_sdafd_raw"]:
    print(
        col,
        "available:", df[col].notna().sum(),
        "missing:", df[col].isna().sum()
    )

print("\n========== COORDINATE RANGE ==========")

print("Longitude:", df.longitude.min(), df.longitude.max())
print("Latitude:", df.latitude.min(), df.latitude.max())

print("\nValidation inspection completed.")
