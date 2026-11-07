import pandas as pd
import numpy as np
from pathlib import Path

path = Path("backend/ml/data/processed/india_forest_features_v4_qc.csv")
df = pd.read_csv(path)

print("DATASET:", path.name)
print("Shape:", df.shape)
print("Duplicate grid cells:", df.duplicated(["row", "col"]).sum())

print("\nFOREST FEATURES")
for i in range(1, 15):
    col = f"forest_type_class_{i:02d}_raw"
    print(col, "positive:", int((df[col] > 0).sum()))

print("\nFIRE QC FEATURES")
for feature in ["afd", "lfp", "sdafd"]:
    value = df[f"fire_{feature}_qc"]
    coverage = df[f"fire_{feature}_coverage"]
    quality = df[f"fire_{feature}_quality_ok"]

    print(
        feature.upper(),
        "accepted:", int(quality.sum()),
        "missing QC values:", int(value.isna().sum()),
        "invalid quality flags:", int((~quality.isin([0, 1])).sum()),
        "coverage min/max:", float(coverage.min()), float(coverage.max())
    )

print("\nCHECK COMPLETE")
