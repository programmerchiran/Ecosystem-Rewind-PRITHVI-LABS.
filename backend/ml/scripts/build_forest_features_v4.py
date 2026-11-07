import zipfile
import tempfile
from pathlib import Path

import numpy as np
import pandas as pd
import rasterio

from rasterio.io import MemoryFile
from rasterio.crs import CRS
from rasterio.warp import reproject, Resampling

RAW = Path("backend/ml/data/raw/nrsc")
OUT = Path("backend/ml/data/processed")

INPUT_CSV = OUT / "india_forest_features_v2.csv"
OUTPUT_CSV = OUT / "india_forest_features_v4.csv"

REFERENCE_CRS = CRS.from_proj4(
    "+proj=aea +lat_1=28 +lat_2=12 +lat_0=20 "
    "+lon_0=78 +x_0=2000000 +y_0=2000000 "
    "+datum=WGS84 +units=m +no_defs"
)

print("Loading forest features...")
df = pd.read_csv(INPUT_CSV)

required = {"row", "col", "forest_fraction_2013_raw"}

missing = required - set(df.columns)

if missing:
    raise ValueError(f"Missing required columns: {missing}")

with zipfile.ZipFile(RAW / "nices_ffc_2013.zip") as archive:
    asc_name = "forest_fraction_5km_2013.asc"

    with tempfile.TemporaryDirectory() as temp:
        asc_path = Path(temp) / asc_name
        asc_path.write_bytes(archive.read(asc_name))

        with rasterio.open(asc_path) as ref:
            ref_transform = ref.transform
            ref_height = ref.height
            ref_width = ref.width

print("Reference grid:", ref_width, "x", ref_height)

rows = df["row"].to_numpy(dtype=int)
cols = df["col"].to_numpy(dtype=int)

if (
    (rows < 0).any() or (rows >= ref_height).any()
    or (cols < 0).any() or (cols >= ref_width).any()
):
    raise ValueError("CSV contains grid indices outside reference raster")

if df.duplicated(["row", "col"]).any():
    raise ValueError("Duplicate row/col pairs found")

def align_fire_raster(zip_name, tif_name, method):
    with zipfile.ZipFile(RAW / zip_name) as archive:
        raster_bytes = archive.read(tif_name)

    with MemoryFile(raster_bytes) as mem:
        with mem.open() as src:
            source = src.read(1).astype("float64")

            source_valid = np.isfinite(source)

            if src.nodata is not None:
                source_valid &= source != src.nodata

            clean = np.where(source_valid, source, np.nan).astype("float32")

            destination = np.full(
                (ref_height, ref_width),
                np.nan,
                dtype="float32"
            )

            reproject(
                source=clean,
                destination=destination,
                src_transform=src.transform,
                src_crs=src.crs,
                src_nodata=np.nan,
                dst_transform=ref_transform,
                dst_crs=REFERENCE_CRS,
                dst_nodata=np.nan,
                resampling=method
            )

            # Reproject a validity mask to estimate source coverage.
            coverage = np.zeros(
                (ref_height, ref_width),
                dtype="float32"
            )

            reproject(
                source=source_valid.astype("float32"),
                destination=coverage,
                src_transform=src.transform,
                src_crs=src.crs,
                src_nodata=None,
                dst_transform=ref_transform,
                dst_crs=REFERENCE_CRS,
                dst_nodata=0,
                resampling=Resampling.average
            )

    return destination, np.clip(coverage, 0, 1)


fire_layers = [
    (
        "fire_afd_raw",
        "fire_afd_coverage",
        "fire_afd_available",
        "nices_ff_AFD.zip",
        "nices_ff_AFD/fire_AFD.tif",
        Resampling.average
    ),
    (
        "fire_lfp_raw",
        "fire_lfp_coverage",
        "fire_lfp_available",
        "nices_ff_LFP.zip",
        "nices_ff_LFP/fire_LPF.tif",
        Resampling.nearest
    ),
    (
        "fire_sdafd_raw",
        "fire_sdafd_coverage",
        "fire_sdafd_available",
        "nices_ff_SDAFD.zip",
        "nices_ff_SDAFD/fire_SDAFD.tif",
        Resampling.average
    )
]

for value_col, coverage_col, available_col, zip_name, tif_name, method in fire_layers:

    print("\nProcessing:", value_col)

    aligned, coverage = align_fire_raster(
        zip_name,
        tif_name,
        method
    )

    values = aligned[rows, cols]
    coverage_values = coverage[rows, cols]

    valid = np.isfinite(values)

    df[value_col] = values
    df[coverage_col] = coverage_values
    df[available_col] = valid.astype("int8")

    print("Resampling:", method.name)
    print("Available:", int(valid.sum()))
    print("Missing:", int((~valid).sum()))
    print("Mean coverage:", float(coverage_values.mean()))

    if valid.any():
        print("Minimum:", float(values[valid].min()))
        print("Maximum:", float(values[valid].max()))

print("\nChecking final dataset...")

fire_available = [
    "fire_afd_available",
    "fire_lfp_available",
    "fire_sdafd_available"
]

print("Rows:", len(df))
print("Columns:", len(df.columns))
print("Duplicate grid cells:", df.duplicated(["row", "col"]).sum())

df.to_csv(OUTPUT_CSV, index=False)

print("\nV4 DATASET SAVED")
print(OUTPUT_CSV)
