
import pandas as pd
from pathlib import Path

INPUT = Path(
    "backend/ml/data/processed/india_forest_features_v5_climate.csv"
)

OUTPUT = Path(
    "backend/ml/data/processed/india_forest_qc_report.csv"
)

df = pd.read_csv(INPUT)

# Select cells with recorded forest cover.
forest = df[df["forest_fraction_2013_raw"] > 0].copy()

print("\n========== INDIA FOREST DATA QC ==========")
print("Total grid cells:", len(df))
print("Forest-covered cells:", len(forest))
print("Forest-covered share: {:.2f}%".format(
    len(forest) / len(df) * 100
))

results = []

def add_result(feature, available, total):
    results.append({
        "feature": feature,
        "available_cells": int(available),
        "missing_cells": int(total - available),
        "availability_percent": round(
            available / total * 100, 2
        ) if total else 0
    })

# Forest fraction
add_result(
    "forest_fraction_2013",
    forest["forest_fraction_2013_raw"].notna().sum(),
    len(forest)
)

# Forest type layers
print("\n--- Forest type coverage ---")

for i in range(1, 15):
    col = f"forest_type_class_{i:02d}_raw"

    if col in forest.columns:
        available = (forest[col].fillna(0) > 0).sum()
        add_result(col, available, len(forest))
        print(f"{col}: {available} cells with positive values")

# Fire features
print("\n--- Fire feature quality ---")

for feature in ["afd", "lfp", "sdafd"]:
    value_col = f"fire_{feature}_qc"
    flag_col = f"fire_{feature}_quality_ok"

    if value_col in forest.columns:
        available = forest[value_col].notna().sum()
        add_result(value_col, available, len(forest))

        if flag_col in forest.columns:
            accepted = (
                forest[flag_col].fillna(0).astype(float) == 1
            ).sum()
            print(
                f"{feature.upper()}: "
                f"{available} non-missing QC values; "
                f"{accepted} quality flags accepted"
            )

# Climate features
print("\n--- Climate feature coverage ---")

for i in range(1, 20):
    col = f"bio_{i:02d}"

    if col in forest.columns:
        available = forest[col].notna().sum()
        add_result(col, available, len(forest))
        print(
            f"{col}: {available} available, "
            f"{len(forest) - available} missing"
        )

# Save report
report = pd.DataFrame(results)
report.to_csv(OUTPUT, index=False)

print("\n========== SUMMARY ==========")
print(report.to_string(index=False))
print("\nReport saved to:", OUTPUT)
