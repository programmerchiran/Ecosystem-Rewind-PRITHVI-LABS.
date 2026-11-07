import zipfile
import io
import numpy as np
import pandas as pd
from pathlib import Path

RAW = Path("backend/ml/data/raw/nrsc")
OUT = Path("backend/ml/data/processed")
OUT.mkdir(parents=True, exist_ok=True)

def read_ascii(zip_name, filename):
    with zipfile.ZipFile(RAW / zip_name) as archive:
        raw = archive.read(filename)

    arr = np.loadtxt(io.BytesIO(raw), skiprows=6, dtype=np.float64)
    arr[arr == -9999] = np.nan
    return arr

print("Reading forest fraction...")
forest = read_ascii(
    "nices_ffc_2013.zip",
    "forest_fraction_5km_2013.asc"
)

rows, cols = forest.shape
data = {
    "row": np.repeat(np.arange(rows), cols),
    "col": np.tile(np.arange(cols), rows),
    "forest_fraction_2013_raw": forest.ravel(),
    "forest_fraction_2013_candidate": (forest / 1_000_000).ravel(),
}

print("Reading all 14 forest type classes...")

for i in range(1, 15):
    print(f"  Class {i}/14")

    arr = read_ascii(
        f"nices_ftg_class{i}.zip",
        f"forest_type_5km_class{i}.asc"
    )

    data[f"forest_type_class_{i:02d}_raw"] = arr.ravel()
    data[f"forest_type_class_{i:02d}_candidate"] = (
        arr / 1_000_000
    ).ravel()

print("Reading fire indicators...")

fire_files = {
    "fire_afd_raw": (
        "nices_ff_AFD.zip",
        "nices_ff_AFD/Fire_AFD.tif"
    ),
    "fire_lfp_raw": (
        "nices_ff_LFP.zip",
        "nices_ff_LFP/Fire_LFP.tif"
    ),
    "fire_sdafd_raw": (
        "nices_ff_SDAFD.zip",
        "nices_ff_SDAFD/Fire_SDAFD.tif"
    ),
}

# Fire layers will be added in the next step after checking
# their actual filenames and grid alignment.
print("Fire layers intentionally not added yet.")

df = pd.DataFrame(data)

# Keep cells with valid forest-fraction observations.
df = df[df["forest_fraction_2013_raw"].notna()].copy()

output = OUT / "india_forest_features_v2.csv"
df.to_csv(output, index=False)

print("\nCompleted.")
print("Rows:", len(df))
print("Columns:", len(df.columns))
print("Output:", output)
print("Class 14 included:", "forest_type_class_14_raw" in df.columns)
