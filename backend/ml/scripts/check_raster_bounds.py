from pathlib import Path
import rasterio

base = Path("backend/ml/data/raw/nrsc")

files = {
    "Forest fraction": (
        "nices_ffc_2013.zip",
        "Forest_Fraction_5km_2013.tif"
    ),
    "Fire AFD": (
        "nices_ff_AFD.zip",
        "nices_ff_AFD/fire_AFD.tif"
    ),
    "Fire LFP": (
        "nices_ff_LFP.zip",
        "nices_ff_LFP/fire_LPF.tif"
    ),
    "Fire SDAFD": (
        "nices_ff_SDAFD.zip",
        "nices_ff_SDAFD/fire_SDAFD.tif"
    ),
}

for label, (zip_name, tif_name) in files.items():
    zip_path = (base / zip_name).resolve()

    print("\n" + "=" * 60)
    print(label)

    vsi_path = (
        f"/vsizip/{zip_path.as_posix()}/{tif_name}"
    )

    try:
        with rasterio.open(vsi_path) as src:
            print("CRS:", src.crs)
            print("Bounds:", src.bounds)
            print("Dimensions:", src.width, src.height)
            print("Resolution:", src.res)
            print("Nodata:", src.nodata)
            print("Data type:", src.dtypes)
    except Exception as e:
        print("ERROR:", repr(e))

print("\nINSPECTION FINISHED")
