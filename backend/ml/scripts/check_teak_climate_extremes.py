
from pathlib import Path
import pandas as pd

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data" / "processed"

INPUT = DATA_DIR / "teak_habitat_training_v1.csv"

df = pd.read_csv(INPUT)

climate_cols = [f"bio_{i:02d}" for i in range(1, 20)]

print("\n--- CLIMATE EXTREME CHECK ---")

for col in ["bio_01", "bio_05", "bio_06",
            "bio_12", "bio_13", "bio_14",
            "bio_18", "bio_19"]:

    print(f"\n{col}:")
    print(
        df.nlargest(5, col)[
            ["row", "col", "presence", col]
        ].to_string(index=False)
    )

    print("\nLowest values:")
    print(
        df.nsmallest(5, col)[
            ["row", "col", "presence", col]
        ].to_string(index=False)
    )

print("\n--- PRESENCE VS BACKGROUND CLIMATE ---")

for col in climate_cols:
    p = df.loc[df["presence"] == 1, col]
    b = df.loc[df["presence"] == 0, col]

    print(
        f"{col}: "
        f"presence median={p.median():.2f}, "
        f"background median={b.median():.2f}"
    )

print("\n--- CHECK COMPLETE ---")
