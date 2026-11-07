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
OUTPUT_CSV = OUT / "india_forest_features_v3.csv"

# Explicit NRSC WGS 84 Albers Equal Area projection.
REFERENCE_CRS = CRS.from_proj4(
    "+proj=aea +lat_1=28 +lat_2=12 +lat_0=20 "
    "+lon_0=78 +x_0=2000000 +y_0=2000000 "
    "+datum=WGS84 +units=m +no_defs"
)

print("Loading forest feature dataset...")
df = pd.read_csv(INPUT_CSV)

print("Reading reference forest grid...")

with zipfile.ZipFile(RAW / "nices_ffc_2013.zip") as archive:
    asc_name = "forest_fraction_5km_2013.asc"

    with tempfile.TemporaryDirectory() as temp:
        asc_path = Path(temp) / asc_name
        asc_path.write_bytes(archive.read(asc_name))

        with rasterio.open(asc_path) as ref:
            ref_transform = ref.transform
            ref_height = ref.height
            ref_width = ref.width

print("Reference dimensions:", ref_width, ref_height)
print("Reference CRS:", REFERENCE_CRS)


def align_fire_raster(zip_name, tif_name, resampling):
    with zipfile.ZipFile(RAW / zip_name) as archive:
        raster_bytes = archive.read(tif_name)

    with MemoryFile(raster_bytes) as mem:
        with mem.open() as src:
            source = src.read(1).astype(np.float64)

            if src.nodata is not None:
                source[source == src.nodata] = np.nan

            source[~np.isfinite(source)] = np.nan
            source = source.astype(np.float32)

            destination = np.full(
                (ref_height, ref_width),
                np.nan,
                dtype=np.float32
            )

            reproject(
                source=source,
                destination=destination,
                src_transform=src.transform,
                src_crs=src.crs,
                src_nodata=np.nan,
                dst_transform=ref_transform,
                dst_crs=REFERENCE_CRS,
                dst_nodata=np.nan,
                resampling=resampling
            )

    return destination


fire_layers = [
    (
        "fire_afd_raw",
        "nices_ff_AFD.zip",
        "nices_ff_AFD/fire_AFD.tif",
        Resampling.bilinear
    ),
    (
        "fire_lfp_raw",
        "nices_ff_LFP.zip",
        "nices_ff_LFP/fire_LPF.tif",
        Resampling.nearest
    ),
    (
        "fire_sdafd_raw",
        "nices_ff_SDAFD.zip",
        "nices_ff_SDAFD/fire_SDAFD.tif",
        Resampling.bilinear
    )
]

for column, zip_name, tif_name, method in fire_layers:
    print("\nAligning:", column)

    aligned = align_fire_raster(zip_name, tif_name, method)

    values = aligned[
        df["row"].to_numpy(dtype=int),
        df["col"].to_numpy(dtype=int)
    ]

    df[column] = values

    valid = np.isfinite(values)

    print("Valid cells:", int(valid.sum()))
    print("Missing cells:", int((~valid).sum()))

    if valid.any():
        print("Minimum:", float(np.min(values[valid])))
        print("Maximum:", float(np.max(values[valid])))

print("\nSaving new dataset...")
df.to_csv(OUTPUT_CSV, index=False)

print("\nCompleted!")
print("Rows:", len(df))
print("Columns:", len(df.columns))
print("Output:", OUTPUT_CSV)
