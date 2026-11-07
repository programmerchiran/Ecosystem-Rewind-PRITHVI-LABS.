
from pathlib import Path
import pandas as pd
import numpy as np

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data" / "processed"

INPUT = DATA_DIR / "teak_habitat_training_v1.csv"

df = pd.read_csv(INPUT)

# Each block covers approximately 50 km × 50 km.
# The NRSC grid cells are 5 km × 5 km.
BLOCK_SIZE = 10

df["block_row"] = df["row"] // BLOCK_SIZE
df["block_col"] = df["col"] // BLOCK_SIZE

df["block_id"] = (
    df["block_row"].astype(str)
    + "_"
    + df["block_col"].astype(str)
)

occupied = df[df["presence"] == 1]

print("\n--- SPATIAL BLOCK REPORT ---")
print("Total occupied cells:", len(occupied))
print("Occupied spatial blocks:", occupied["block_id"].nunique())

print("\nOccupied cells per block:")
print(
    occupied.groupby("block_id")
    .size()
    .sort_values(ascending=False)
    .head(20)
    .to_string()
)

print("\nBlocks containing at least:")
for threshold in [2, 3, 5, 10]:
    count = (
        occupied.groupby("block_id")
        .size()
        .ge(threshold)
        .sum()
    )
    print(f"{threshold} occupied cells: {count}")

print("\n--- COMPLETED ---")
