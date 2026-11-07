import numpy as np
import pandas as pd
import rasterio
from pathlib import Path
from rasterio.io import MemoryFile
from rasterio.warp import reproject, Resampling
from rasterio.crs import CRS

RAW = Path("backend/ml/data/raw/nrsc")
CLIMATE = RAW / "wc2.1_5m_bio"
OUT = Path("backend/ml/data/processed")

INPUT = OUT / "india_forest_features_v4_qc.csv"
OUTPUT = OUT / "india_forest_features_v5_climate.csv"

REFERENCE_CRS = CRS.from_proj4(
    "+proj=aea +lat_1=28 +lat_2=12 +lat_0=20 "
    "+lon_0=78 +x_0=2000000 +y_0=2000000 "
    "+datum=WGS84 +units=m +no_defs"
)

print("Loading v4 quality-controlled dataset...")
df = pd.read_csv(INPUT)

import zipfile
import tempfile

with tempfile.TemporaryDirectory() as temp:
    with zipfile.ZipFile(RAW / "nices_ffc_2013.zip") as archive:
        archive.extract("Forest_Fraction_5km_2013.tif", temp)

    reference_path = Path(temp) / "Forest_Fraction_5km_2013.tif"

    with rasterio.open(reference_path) as ref:
        transform = ref.transform
        height = ref.height
        width = ref.width

print("Reference grid:", width, "x", height)

rows = df["row"].to_numpy(dtype=int)
cols = df["col"].to_numpy(dtype=int)

if (
    (rows < 0).any() or (rows >= height).any()
    or (cols < 0).any() or (cols >= width).any()
):
    raise ValueError("Grid indices outside reference raster")

for i in range(1, 20):
    column = f"bio_{i:02d}"
    path = CLIMATE / f"wc2.1_5m_bio_{i}.tif"

    print("\nProcessing", column)

    if not path.exists():
        raise FileNotFoundError(path)

    with rasterio.open(path) as src:
        source = src.read(1).astype("float32")

        valid = np.isfinite(source)

        if src.nodata is not None:
            valid &= source != src.nodata

        source = np.where(valid, source, np.nan)

        destination = np.full(
            (height, width),
            np.nan,
            dtype="float32"
        )

        reproject(
            source=source,
            destination=destination,
            src_transform=src.transform,
            src_crs=src.crs,
            src_nodata=np.nan,
            dst_transform=transform,
            dst_crs=REFERENCE_CRS,
            dst_nodata=np.nan,
            resampling=Resampling.average
        )

    values = destination[rows, cols]
    df[column] = values

    valid_count = int(np.isfinite(values).sum())

    print("Valid cells:", valid_count)
    print("Missing cells:", len(values) - valid_count)

    if valid_count:
        print("Minimum:", float(np.nanmin(values)))
        print("Maximum:", float(np.nanmax(values)))

print("\nSaving climate dataset...")
df.to_csv(OUTPUT, index=False)

print("\nV5 CREATED")
print("Rows:", len(df))
print("Columns:", len(df.columns))
print("File:", OUTPUT)
