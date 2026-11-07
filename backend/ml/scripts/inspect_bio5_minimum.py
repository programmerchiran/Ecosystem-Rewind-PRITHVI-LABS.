
import pandas as pd

path = "backend/ml/data/processed/india_forest_features_v5_climate.csv"
df = pd.read_csv(path)

# Keep only cells where the forest fraction is greater than zero.
forest = df[df["forest_fraction_2013_raw"] > 0].copy()

print("Cells with nonzero forest fraction:", len(forest))
print("Lowest BIO5 in those cells:", forest["bio_05"].min())

print("\n10 lowest BIO5 values in cells with forest:")
print(
    forest.nsmallest(10, "bio_05")[
        [
            "row",
            "col",
            "forest_fraction_2013_raw",
            "bio_01",
            "bio_05",
            "bio_06",
        ]
    ].to_string(index=False)
)
