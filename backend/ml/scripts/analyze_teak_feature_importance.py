
from pathlib import Path
import json
import joblib
import pandas as pd

BASE_DIR = Path(__file__).resolve().parent.parent

MODEL_DIR = BASE_DIR / "models"
EVAL_DIR = BASE_DIR / "evaluation"
DATA_DIR = BASE_DIR / "data" / "processed"

MODEL_FILE = MODEL_DIR / "teak_habitat_random_forest_v1.joblib"
FEATURE_FILE = MODEL_DIR / "teak_habitat_features_v1.json"
INPUT_FILE = DATA_DIR / "teak_habitat_training_v1.csv"

model = joblib.load(MODEL_FILE)

with open(FEATURE_FILE, "r", encoding="utf-8") as f:
    features = json.load(f)

df = pd.read_csv(INPUT_FILE)

importance = pd.DataFrame({
    "feature": features,
    "importance": model.feature_importances_
})

importance = importance.sort_values(
    "importance",
    ascending=False
)

importance.to_csv(
    EVAL_DIR / "teak_feature_importance.csv",
    index=False
)

print("\n--- TOP 20 TEAK HABITAT PREDICTORS ---")
print(importance.head(20).to_string(index=False))

print("\n--- IMPORTANCE BY FEATURE GROUP ---")

def feature_group(name):
    if name.startswith("bio_"):
        return "Climate"
    if name.startswith("forest_type"):
        return "Forest Type"
    if name in ["elevation_m", "slope_degrees"]:
        return "Terrain"
    return "Soil"

importance["group"] = importance["feature"].apply(feature_group)

group_importance = (
    importance.groupby("group")["importance"]
    .sum()
    .sort_values(ascending=False)
)

print(group_importance.to_string())

group_importance.to_csv(
    EVAL_DIR / "teak_feature_group_importance.csv"
)

print("\nSaved feature importance reports.")
