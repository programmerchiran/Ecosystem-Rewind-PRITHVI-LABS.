
from pathlib import Path
import pandas as pd

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data" / "processed"

df = pd.read_csv(DATA_DIR / "teak_habitat_training_v1.csv")

df["block_row"] = df["row"] // 10
df["block_col"] = df["col"] // 10
df["block_id"] = (
    df["block_row"].astype(str)
    + "_"
    + df["block_col"].astype(str)
)

block_summary = (
    df.groupby("block_id")
    .agg(
        total_cells=("presence", "size"),
        teak_cells=("presence", "sum"),
    )
    .reset_index()
)

block_summary["background_cells"] = (
    block_summary["total_cells"] - block_summary["teak_cells"]
)

print("\n--- BLOCK DISTRIBUTION ---")
print("Total blocks:", len(block_summary))
print("Blocks with teak:", (block_summary["teak_cells"] > 0).sum())
print("Blocks without teak:", (block_summary["teak_cells"] == 0).sum())

print("\nTeak cells per occupied block:")
print(block_summary.loc[
    block_summary["teak_cells"] > 0, "teak_cells"
].describe().to_string())

print("\nOccupied blocks with no background cells:",
      ((block_summary["teak_cells"] > 0) &
       (block_summary["background_cells"] == 0)).sum())

print("\n--- COMPLETE ---")
