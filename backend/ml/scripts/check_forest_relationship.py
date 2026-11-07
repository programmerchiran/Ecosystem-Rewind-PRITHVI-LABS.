
import pandas as pd
import numpy as np

path = (
    "backend/ml/data/processed/"
    "india_nrsc_forest_fire_features_5km.csv"
)

df = pd.read_csv(path)

classes = [
    c for c in df.columns
    if c.startswith("forest_type_class_")
]

df["forest_type_sum"] = df[classes].sum(axis=1)
df["difference"] = (
    df["forest_type_sum"] - df["forest_fraction_2013_raw"]
)

print("Cells with type sum > forest fraction:",
      (df["difference"] > 1000).sum())

print("Cells with type sum > 1,000,000:",
      (df["forest_type_sum"] > 1_000_000).sum())

print("\nLargest discrepancies:")
print(
    df.nlargest(15, "difference")[
        [
            "latitude",
            "longitude",
            "forest_fraction_2013_raw",
            "forest_type_sum",
            "difference",
        ]
    ].to_string(index=False)
)

print("\nClass overlap:")
positive = df[classes].gt(0).sum(axis=1)
print(positive.value_counts().sort_index())
