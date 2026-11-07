from pathlib import Path
import zipfile
import tempfile
import numpy as np
import rasterio

from rasterio.warp import reproject, Resampling

base = Path("backend/ml/data/raw/nrsc")

with tempfile.TemporaryDirectory() as tmp:
    tmp = Path(tmp)

    forest_zip = base / "nices_ffc_2013.zip"
    fire_zip = base / "nices_ff_AFD.zip"

    with zipfile.ZipFile(forest_zip) as z:
        z.extract("Forest_Fraction_5km_2013.tif", tmp)

    with zipfile.ZipFile(fire_zip) as z:
        z.extract("nices_ff_AFD/fire_AFD.tif", tmp)

    forest_path = tmp / "Forest_Fraction_5km_2013.tif"
    fire_path = tmp / "nices_ff_AFD/fire_AFD.tif"

    with rasterio.open(forest_path) as ref, rasterio.open(fire_path) as src:

        source = src.read(1).astype("float64")
        source_valid = (
            np.isfinite(source) &
            (source != src.nodata)
        )

        source_clean = np.where(source_valid, source, np.nan)

        print("SOURCE VALID PIXELS:", int(source_valid.sum()))
        print("DESTINATION GRID:", ref.width, "x", ref.height)

        for method in [Resampling.nearest, Resampling.average]:

            destination = np.full(
                (ref.height, ref.width),
                np.nan,
                dtype="float32"
            )

            reproject(
                source=source_clean,
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

            print("\nMETHOD:", method.name)
            print("Valid destination cells:", int(valid.sum()))
            print("Missing destination cells:", int((~valid).sum()))

            if valid.any():
                print("Minimum:", float(destination[valid].min()))
                print("Maximum:", float(destination[valid].max()))

print("\nREPROJECTION TEST FINISHED")
