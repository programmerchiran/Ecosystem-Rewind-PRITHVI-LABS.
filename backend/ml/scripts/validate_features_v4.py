import pandas as pd
import numpy as np
from pathlib import Path

path = Path("backend/ml/data/processed/india_forest_features_v4.csv")
df = pd.read_csv(path)

print("DATASET")
print("Rows:", len(df))
print("Columns:", len(df.columns))
print("Duplicate grid cells:", df.duplicated(["row", "col"]).sum())

features = ["afd", "lfp", "sdafd"]

for feature in features:
    print("\n" + "=" * 45)
    print("FEATURE:", feature.upper())

    value = df[f"fire_{feature}_raw"]
    coverage = df[f"fire_{feature}_coverage"]
    available = df[f"fire_{feature}_available"]

    print("Available:", int(available.sum()))
    print("Missing:", int((available == 0).sum()))
    print("Availability flag errors:",
          int((available != value.notna().astype(int)).sum()))

    print("\nCoverage for available cells:")
    print(coverage[available == 1].describe())

    print("\nCoverage for missing cells:")
    print(coverage[available == 0].describe())

    print("Coverage outside 0-1:",
          int(((coverage < 0) | (coverage > 1)).sum()))

    print("Infinite values:",
          int(np.isinf(value.dropna()).sum()))

print("\nV4 VALIDATION COMPLETE")
