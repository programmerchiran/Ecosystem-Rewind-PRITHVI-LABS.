import pandas as pd

path = (
    "backend/ml/data/processed/"
    "india_nrsc_forest_fire_features_5km.csv"
)

df = pd.read_csv(path)

print("\n========== DATASET OVERVIEW ==========")
print("Rows:", len(df))
print("Columns:", len(df.columns))

print("\n========== COLUMN NAMES ==========")
print(df.columns.tolist())

print("\n========== MISSING VALUES ==========")
print(df.isna().sum())

print("\n========== NUMERIC STATISTICS ==========")
print(df.describe().T)

print("\n========== SAMPLE RECORDS ==========")
print(df.head(5).to_string())

print("\n========== DUPLICATE LOCATIONS ==========")
print(
    df.duplicated(
        subset=["latitude", "longitude"]
    ).sum()
)