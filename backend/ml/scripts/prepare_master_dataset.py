
from pathlib import Path
import pandas as pd

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data" / "processed"

FILES = [
    DATA_DIR / "india_forest_features_v7_soil.csv",
    DATA_DIR / "india_gbif_biodiversity_5km.csv",
]

OUTPUT = DATA_DIR / "india_ecosystem_master_v1.csv"

print("Loading forest, climate, terrain, soil and fire features...")
master = pd.read_csv(FILES[0])

print("Loading GBIF biodiversity features...")
gbif = pd.read_csv(FILES[1])

KEYS = ["row", "col"]

# Validate keys before merging
for name, df in [("Master", master), ("GBIF", gbif)]:
    if df[KEYS].isna().any().any():
        raise ValueError(f"{name} contains missing grid coordinates.")

    if df.duplicated(KEYS).any():
        raise ValueError(f"{name} contains duplicate grid coordinates.")

master_cells = set(map(tuple, master[KEYS].values))
gbif_cells = set(map(tuple, gbif[KEYS].values))

if master_cells != gbif_cells:
    raise ValueError("Grid coordinates do not match.")

# Add GBIF columns without duplicating grid keys
gbif_features = [
    col for col in gbif.columns if col not in KEYS
]

master = master.merge(
    gbif[KEYS + gbif_features],
    on=KEYS,
    how="left",
    validate="one_to_one"
)

if master[gbif_features].isna().any().any():
    raise ValueError("Missing GBIF values found after merge.")

master = master.sort_values(KEYS).reset_index(drop=True)

master.to_csv(OUTPUT, index=False)

print("\n--- MASTER DATASET REPORT ---")
print("Rows:", len(master))
print("Columns:", len(master.columns))
print("Missing values:", int(master.isna().sum().sum()))
print("Duplicate grid cells:", int(master.duplicated(KEYS).sum()))
print("GBIF occurrence records:", int(master["gbif_occurrence_records"].sum()))
print("Unique species summed across cells:",
      int(master["gbif_unique_species"].sum()))
print("Saved:", OUTPUT)
print("\nMaster dataset preparation completed.")
