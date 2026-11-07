
from pathlib import Path
import json
import joblib
import pandas as pd
import numpy as np

# --------------------------------------------------
# PATHS
# --------------------------------------------------

BASE_DIR = Path(__file__).resolve().parent.parent

DATA_DIR = BASE_DIR / "data" / "processed"
MODEL_DIR = BASE_DIR / "models"
OUTPUT_DIR = DATA_DIR

MODEL_FILE = MODEL_DIR / "teak_habitat_random_forest_v1.joblib"
FEATURE_FILE = MODEL_DIR / "teak_habitat_features_v1.json"

INPUT_FILE = DATA_DIR / "india_forest_modeling_base_v1.csv"

OUTPUT_FILE = OUTPUT_DIR / "india_teak_habitat_suitability_v1.csv"

# --------------------------------------------------
# LOAD MODEL AND FEATURES
# --------------------------------------------------

print("Loading trained teak habitat model...")

model = joblib.load(MODEL_FILE)

with open(FEATURE_FILE, "r", encoding="utf-8") as f:
    features = json.load(f)

print("Model loaded.")
print("Predictors:", len(features))

# --------------------------------------------------
# LOAD ENVIRONMENTAL DATA
# --------------------------------------------------

print("\nLoading Indian forest environmental data...")

df = pd.read_csv(INPUT_FILE)

required = ["row", "col"] + features

missing = sorted(set(required) - set(df.columns))

if missing:
    raise ValueError(f"Missing required columns: {missing}")

# Keep every eligible forest cell.
# Do not silently impute missing environmental data.

valid_mask = df[features].notna().all(axis=1)

valid = df.loc[valid_mask].copy()
excluded = len(df) - len(valid)

print("Total forest cells:", len(df))
print("Cells with complete predictors:", len(valid))
print("Cells excluded for missing predictors:", excluded)

if len(valid) == 0:
    raise ValueError("No cells have complete predictor data.")

# --------------------------------------------------
# PREDICT
# --------------------------------------------------

print("\nCalculating suitability scores...")

scores = model.predict_proba(valid[features])[:, 1]

output = valid[["row", "col"]].copy()

output["teak_suitability_score"] = scores

# Percentage is a display transformation only.
# It is NOT a probability of wild teak occurrence.
output["teak_suitability_index"] = scores * 100

# --------------------------------------------------
# SUITABILITY CATEGORIES
# --------------------------------------------------

output["suitability_class"] = pd.cut(
    output["teak_suitability_score"],
    bins=[-np.inf, 0.20, 0.40, 0.60, 0.80, np.inf],
    labels=[
        "Very Low",
        "Low",
        "Moderate",
        "High",
        "Very High",
    ],
    right=False,
).astype(str)

# --------------------------------------------------
# SAVE
# --------------------------------------------------

output.to_csv(OUTPUT_FILE, index=False)

print("\n--- PREDICTION REPORT ---")
print("Predicted cells:", len(output))
print("Excluded cells:", excluded)

print("\nSuitability class distribution:")
print(
    output["suitability_class"]
    .value_counts()
    .reindex(
        ["Very Low", "Low", "Moderate", "High", "Very High"],
        fill_value=0
    )
    .to_string()
)

print("\nScore statistics:")
print(output["teak_suitability_score"].describe().to_string())

print("\nSaved predictions:")
print(OUTPUT_FILE)

print("\nPREDICTION COMPLETE")
