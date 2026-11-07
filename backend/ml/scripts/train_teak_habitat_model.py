
from pathlib import Path
import json
import warnings

import joblib
import numpy as np
import pandas as pd
import sklearn

from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import GroupKFold
from sklearn.metrics import (
    roc_auc_score,
    average_precision_score,
    balanced_accuracy_score,
)

warnings.filterwarnings("ignore", category=UserWarning)

# --------------------------------------------------
# PATHS AND SETTINGS
# --------------------------------------------------

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data" / "processed"
MODEL_DIR = BASE_DIR / "models"
EVAL_DIR = BASE_DIR / "evaluation"

INPUT_FILE = DATA_DIR / "teak_habitat_training_v1.csv"

MODEL_DIR.mkdir(parents=True, exist_ok=True)
EVAL_DIR.mkdir(parents=True, exist_ok=True)

RANDOM_STATE = 42
BACKGROUND_RATIO = 3
N_SPLITS = 5

# --------------------------------------------------
# FEATURES
# --------------------------------------------------

FEATURES = (
    [f"bio_{i:02d}" for i in range(1, 20)]
    + [
        "elevation_m",
        "slope_degrees",
        "soil_organic_carbon_g_kg",
        "soil_ph",
        "clay_percent",
        "sand_percent",
    ]
    + [
        f"forest_type_class_{i:02d}_candidate"
        for i in range(1, 15)
    ]
)

# --------------------------------------------------
# LOAD DATA
# --------------------------------------------------

print("Loading teak training data...")

df = pd.read_csv(INPUT_FILE)

required = FEATURES + [
    "row", "col", "presence"
]

missing_columns = sorted(set(required) - set(df.columns))

if missing_columns:
    raise ValueError(f"Missing columns: {missing_columns}")

if df[FEATURES].isna().any().any():
    raise ValueError("Predictors contain missing values.")

if df.duplicated(["row", "col"]).any():
    raise ValueError("Duplicate grid cells detected.")

df["presence"] = df["presence"].astype(int)

# 50 km blocks: 10 cells × 5 km
df["block_row"] = df["row"] // 10
df["block_col"] = df["col"] // 10
df["block_id"] = (
    df["block_row"].astype(str)
    + "_"
    + df["block_col"].astype(str)
)

presence = df[df["presence"] == 1].copy()
background = df[df["presence"] == 0].copy()

if len(presence) == 0:
    raise ValueError("No teak presence cells found.")

# --------------------------------------------------
# BACKGROUND SAMPLING
# --------------------------------------------------

# Background cells are unrecorded locations,
# NOT confirmed teak absences.
#
# Uniform random sampling is used for this first
# baseline. Observation-effort bias remains a limitation.

n_background = min(
    len(background),
    len(presence) * BACKGROUND_RATIO
)

sampled_background = background.sample(
    n=n_background,
    random_state=RANDOM_STATE
).copy()

data = pd.concat(
    [presence, sampled_background],
    ignore_index=True
)

data = data.sample(
    frac=1,
    random_state=RANDOM_STATE
).reset_index(drop=True)

X = data[FEATURES]
y = data["presence"]
groups = data["block_id"]

print("\n--- TRAINING DATA ---")
print("Presence cells:", len(presence))
print("Sampled background:", len(sampled_background))
print("Total samples:", len(data))
print("Predictors:", len(FEATURES))
print("Spatial blocks:", groups.nunique())
# --------------------------------------------------
# SPATIAL CROSS-VALIDATION
# --------------------------------------------------

cv = GroupKFold(n_splits=N_SPLITS)

fold_results = []
oof_predictions = []

print("\nStarting spatial cross-validation...")

for fold, (train_idx, test_idx) in enumerate(
    cv.split(X, y, groups=groups),
    start=1
):
    X_train = X.iloc[train_idx]
    X_test = X.iloc[test_idx]

    y_train = y.iloc[train_idx]
    y_test = y.iloc[test_idx]

    train_groups = set(groups.iloc[train_idx])
    test_groups = set(groups.iloc[test_idx])

    if train_groups.intersection(test_groups):
        raise RuntimeError("Spatial leakage detected!")

    if y_test.nunique() < 2:
        raise RuntimeError(
            f"Fold {fold} has only one class. "
            "Spatial evaluation cannot calculate ROC-AUC."
        )

    model = RandomForestClassifier(
        n_estimators=400,
        max_depth=18,
        min_samples_split=10,
        min_samples_leaf=5,
        max_features="sqrt",
        class_weight="balanced_subsample",
        random_state=RANDOM_STATE + fold,
        n_jobs=-1,
    )

    model.fit(X_train, y_train)

    probabilities = model.predict_proba(X_test)[:, 1]
    predictions = (probabilities >= 0.5).astype(int)

    roc_auc = roc_auc_score(y_test, probabilities)
    avg_precision = average_precision_score(
        y_test, probabilities
    )
    balanced_acc = balanced_accuracy_score(
        y_test, predictions
    )

    fold_results.append({
        "fold": fold,
        "train_samples": len(train_idx),
        "test_samples": len(test_idx),
        "train_presence": int(y_train.sum()),
        "test_presence": int(y_test.sum()),
        "test_blocks": len(test_groups),
        "roc_auc": roc_auc,
        "average_precision": avg_precision,
        "balanced_accuracy_at_0_5": balanced_acc,
    })

    fold_output = data.iloc[test_idx][
        ["row", "col", "block_id", "presence"]
    ].copy()

    fold_output["fold"] = fold
    fold_output["predicted_suitability_score"] = probabilities

    oof_predictions.append(fold_output)

    print(
        f"Fold {fold}: "
        f"ROC-AUC={roc_auc:.4f}, "
        f"AP={avg_precision:.4f}, "
        f"test presences={int(y_test.sum())}"
    )

# --------------------------------------------------
# SAVE EVALUATION
# --------------------------------------------------

results = pd.DataFrame(fold_results)

results.to_csv(
    EVAL_DIR / "teak_spatial_cv_results.csv",
    index=False
)

oof = pd.concat(oof_predictions, ignore_index=True)

oof.to_csv(
    EVAL_DIR / "teak_spatial_oof_predictions.csv",
    index=False
)

summary = {
    "model": "RandomForestClassifier",
    "sklearn_version": sklearn.__version__,
    "random_state": RANDOM_STATE,
    "spatial_block_size": "50km x 50km",
    "spatial_folds": N_SPLITS,
    "background_ratio": BACKGROUND_RATIO,
    "presence_cells": len(presence),
    "sampled_background_cells": len(sampled_background),
    "predictor_count": len(FEATURES),
    "mean_roc_auc": float(results["roc_auc"].mean()),
    "std_roc_auc": float(results["roc_auc"].std()),
    "mean_average_precision": float(
        results["average_precision"].mean()
    ),
    "std_average_precision": float(
        results["average_precision"].std()
    ),
    "mean_balanced_accuracy_at_0_5": float(
        results["balanced_accuracy_at_0_5"].mean()
    ),
    "interpretation": (
        "Relative presence-background discrimination; "
        "not calibrated wild occurrence probability."
    ),
}

with open(
    EVAL_DIR / "teak_model_evaluation.json",
    "w",
    encoding="utf-8"
) as f:
    json.dump(summary, f, indent=4)

# --------------------------------------------------
# FINAL MODEL: FIT ON ALL SAMPLED DATA
# --------------------------------------------------

print("\nTraining final model on all sampled data...")

final_model = RandomForestClassifier(
    n_estimators=400,
    max_depth=18,
    min_samples_split=10,
    min_samples_leaf=5,
    max_features="sqrt",
    class_weight="balanced_subsample",
    random_state=RANDOM_STATE,
    n_jobs=-1,
)

final_model.fit(X, y)

joblib.dump(
    final_model,
    MODEL_DIR / "teak_habitat_random_forest_v1.joblib"
)

with open(
    MODEL_DIR / "teak_habitat_features_v1.json",
    "w",
    encoding="utf-8"
) as f:
    json.dump(FEATURES, f, indent=4)

print("\n--- MODEL TRAINING COMPLETE ---")
print(results.to_string(index=False))

print("\n--- MEAN SPATIAL VALIDATION ---")
print(f"ROC-AUC: {summary['mean_roc_auc']:.4f}")
print(
    "Average precision:",
    f"{summary['mean_average_precision']:.4f}"
)
print(
    "Balanced accuracy:",
    f"{summary['mean_balanced_accuracy_at_0_5']:.4f}"
)

print("\nSaved model:")
print(MODEL_DIR / "teak_habitat_random_forest_v1.joblib")

print("\nSaved evaluation:")
print(EVAL_DIR / "teak_model_evaluation.json")
print(EVAL_DIR / "teak_spatial_cv_results.csv")
print(EVAL_DIR / "teak_spatial_oof_predictions.csv")
