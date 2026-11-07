
from pathlib import Path
import pandas as pd

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data" / "processed"

master_path = DATA_DIR / "india_ecosystem_master_v1.csv"
gbif_path = DATA_DIR / "india_gbif_biodiversity_5km.csv"

df = pd.read_csv(master_path)
gbif = pd.read_csv(gbif_path)

print("\n--- MASTER DATASET ---")
print("Shape:", df.shape)

print("\n--- MISSING VALUES BY COLUMN ---")
missing = df.isna().sum()
missing = missing[missing > 0].sort_values(ascending=False)

for column, count in missing.items():
    print(f"{column}: {count} ({count / len(df) * 100:.2f}%)")

print("\n--- MISSING VALUES BY ROW ---")
missing_per_row = df.isna().sum(axis=1)

print("Rows with no missing values:", int((missing_per_row == 0).sum()))
print("Rows with any missing values:", int((missing_per_row > 0).sum()))
print("Maximum missing values in one row:", int(missing_per_row.max()))

print("\n--- GBIF CONSISTENCY ---")
print("GBIF source records:", int(gbif["gbif_occurrence_records"].sum()))
print("Master records:", int(df["gbif_occurrence_records"].sum()))
print("Difference:", int(
    gbif["gbif_occurrence_records"].sum()
    - df["gbif_occurrence_records"].sum()
))

print("\n--- FOREST-CELL MISSINGNESS ---")
if "forest_fraction_2013_raw" in df.columns:
    forest = df[df["forest_fraction_2013_raw"] > 0]
    print("Forest cells:", len(forest))
    print("Missing values in forest cells:", int(forest.isna().sum().sum()))

print("\n--- AUDIT COMPLETED ---")
