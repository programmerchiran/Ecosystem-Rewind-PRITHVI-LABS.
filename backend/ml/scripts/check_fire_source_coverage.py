from pathlib import Path
import zipfile
import tempfile
import numpy as np
import rasterio
from rasterio.warp import transform_bounds

base = Path("backend/ml/data/raw/nrsc")

files = {
    "AFD": ("nices_ff_AFD.zip", "nices_ff_AFD/fire_AFD.tif"),
    "LFP": ("nices_ff_LFP.zip", "nices_ff_LFP/fire_LPF.tif"),
    "SDAFD": ("nices_ff_SDAFD.zip", "nices_ff_SDAFD/fire_SDAFD.tif"),
}

forest_zip = base / "nices_ffc_2013.zip"

with zipfile.ZipFile(forest_zip) as z:
    with tempfile.TemporaryDirectory() as tmp:
        name = "Forest_Fraction_5km_2013.tif"
        z.extract(name, tmp)

        with rasterio.open(Path(tmp) / name) as forest:
            print("FOREST GRID")
            print("CRS:", forest.crs)
            print("Bounds:", forest.bounds)

            forest_bounds_geo = transform_bounds(
                forest.crs,
                "EPSG:4326",
                *forest.bounds,
                densify_pts=41
            )

            print("Approx geographic bounds:", forest_bounds_geo)

for label, (zip_name, tif_name) in files.items():
    print("\n" + "=" * 55)
    print("FIRE:", label)

    with zipfile.ZipFile(base / zip_name) as z:
        with tempfile.TemporaryDirectory() as tmp:
            z.extract(tif_name, tmp)

            with rasterio.open(Path(tmp) / tif_name) as src:
                arr = src.read(1, masked=True)

                valid = ~np.ma.getmaskarray(arr)
                values = np.asarray(arr.data)[valid]

                print("Total pixels:", arr.size)
                print("Valid pixels:", int(valid.sum()))
                print("Nodata pixels:", int((~valid).sum()))

                if values.size:
                    print("Valid minimum:", float(values.min()))
                    print("Valid maximum:", float(values.max()))
                    print("Valid mean:", float(values.mean()))

                print("Source bounds:", src.bounds)
                print("Source CRS:", src.crs)

print("\nSOURCE COVERAGE CHECK FINISHED")
