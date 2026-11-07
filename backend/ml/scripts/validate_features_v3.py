import pandas as pd
import numpy as np
from pathlib import Path

path = Path("backend/ml/data/processed/india_forest_features_v3.csv")

print("Loading dataset...")
df = pd.read_csv(path)

print("\nDATASET")
print("Rows:", len(df))
print("Columns:", len(df.columns))
print("Duplicate row/column pairs:",
      df.duplicated(["row", "col"]).sum())

print("\nFOREST FRACTION")
print(df["forest_fraction_2013_raw"].describe())

print("\nFOREST TYPE VALIDATION")

for i in range(1, 15):
    col = f"forest_type_class_{i:02d}_raw"
    print(
        col,
        "valid:", df[col].notna().sum(),
        "positive:", (df[col] > 0).sum(),
        "max:", df[col].max()
    )

print("\nFIRE VALIDATION")

fire_cols = [
    "fire_afd_raw",
    "fire_lfp_raw",
    "fire_sdafd_raw"
]

for col in fire_cols:
    values = df[col].dropna()

    print("\n", col)
    print("Valid:", len(values))
    print("Missing:", df[col].isna().sum())
    print("Min:", values.min() if len(values) else None)
    print("Max:", values.max() if len(values) else None)
    print("Infinite:", np.isinf(values).sum())

print("\nFIRE COVERAGE BY FOREST FRACTION")

valid_fire = df[fire_cols].notna().all(axis=1)

print("Cells with all 3 fire values:", valid_fire.sum())
print("Cells without all 3:", (~valid_fire).sum())
print("Fire coverage among cells with forest fraction > 0:",
      valid_fire[df["forest_fraction_2013_raw"] > 0].mean())

print("\nCLASS 14")
print("Positive cells:",
      (df["forest_type_class_14_raw"] > 0).sum())

print("\nVALIDATION FINISHED")
