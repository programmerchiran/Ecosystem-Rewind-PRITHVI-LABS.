from pathlib import Path
import zipfile
import tempfile
import numpy as np
import rasterio

from rasterio.warp import reproject, Resampling

base = Path("backend/ml/data/raw/nrsc")

files = {
    "AFD": (
        "nices_ff_AFD.zip",
        "nices_ff_AFD/fire_AFD.tif",
        Resampling.average
    ),
    "LFP": (
        "nices_ff_LFP.zip",
        "nices_ff_LFP/fire_LPF.tif",
        Resampling.nearest
    ),
    "SDAFD": (
        "nices_ff_SDAFD.zip",
        "nices_ff_SDAFD/fire_SDAFD.tif",
        Resampling.average
    ),
}

with tempfile.TemporaryDirectory() as tmp:
    tmp = Path(tmp)

    forest_zip = base / "nices_ffc_2013.zip"

    with zipfile.ZipFile(forest_zip) as z:
        z.extract("Forest_Fraction_5km_2013.tif", tmp)

    forest_path = tmp / "Forest_Fraction_5km_2013.tif"

    with rasterio.open(forest_path) as ref:

        for label, (zip_name, tif_name, method) in files.items():

            print("\n" + "=" * 50)
            print("FEATURE:", label)
            print("RESAMPLING:", method.name)

            with zipfile.ZipFile(base / zip_name) as z:
                z.extract(tif_name, tmp)

            fire_path = tmp / tif_name

            with rasterio.open(fire_path) as src:

                source = src.read(1).astype("float64")

                source_valid = (
                    np.isfinite(source) &
                    (source != src.nodata)
                )

                clean = np.where(source_valid, source, np.nan)

                destination = np.full(
                    (ref.height, ref.width),
                    np.nan,
                    dtype="float32"
                )

                reproject(
                    source=clean,
                    destination=destination,
                    src_transform=src.transform,
                    src_crs=src.crs,
                    src_nodata=np.nan,
                    dst_transform=ref.transform,
                    dst_crs=ref.crs,
                    dst_nodata=np.nan,
                    resampling=method
                )

                valid = np.isfinite(destination)

                print("Source valid:", int(source_valid.sum()))
                print("Destination valid:", int(valid.sum()))
                print("Destination missing:", int((~valid).sum()))

                if valid.any():
                    print("Minimum:", float(destination[valid].min()))
                    print("Maximum:", float(destination[valid].max()))

print("\nALL FIRE FEATURES TESTED")
