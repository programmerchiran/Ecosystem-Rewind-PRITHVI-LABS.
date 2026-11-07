import pandas as pd
import numpy as np
from pathlib import Path

path = Path("backend/ml/data/processed/india_forest_features_v4.csv")
out = Path("backend/ml/data/processed/india_forest_features_v4_qc.csv")

df = pd.read_csv(path)

MIN_COVERAGE = 0.50

for feature in ["afd", "lfp", "sdafd"]:
    value_col = f"fire_{feature}_raw"
    coverage_col = f"fire_{feature}_coverage"
    available_col = f"fire_{feature}_available"

    coverage = pd.to_numeric(
        df[coverage_col], errors="coerce"
    ).fillna(0)

    # Remove tiny floating-point artefacts.
    coverage = coverage.clip(0, 1)
    coverage[coverage < 1e-6] = 0

    available = (
        df[available_col].eq(1)
        & df[value_col].notna()
    )

    quality = available & (coverage >= MIN_COVERAGE)

    df[coverage_col] = coverage
    df[f"fire_{feature}_quality_ok"] = quality.astype("int8")

    # Preserve original measurement; expose a separate QC version.
    df[f"fire_{feature}_qc"] = df[value_col].where(quality)

    print("\n", feature.upper())
    print("Original available:", int(available.sum()))
    print("Quality accepted:", int(quality.sum()))
    print("Excluded by coverage:", int((available & ~quality).sum()))

df.to_csv(out, index=False)

print("\nQC DATASET SAVED:", out)
print("Rows:", len(df))
print("Columns:", len(df.columns))
