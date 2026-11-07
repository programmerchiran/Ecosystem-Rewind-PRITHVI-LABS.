import zipfile
from pathlib import Path
import rasterio
from rasterio.io import MemoryFile

folder = Path("backend/ml/data/raw/nrsc")

for zip_name in [
    "nices_ff_AFD.zip",
    "nices_ff_LFP.zip",
    "nices_ff_SDAFD.zip"
]:
    print("\n" + "=" * 65)
    print("ZIP:", zip_name)

    with zipfile.ZipFile(folder / zip_name) as archive:
        tif_files = [
            n for n in archive.namelist()
            if n.lower().endswith((".tif", ".tiff"))
        ]

        for name in tif_files:
            print("\nRaster:", name)

            with MemoryFile(archive.read(name)) as mem:
                with mem.open() as src:
                    print("Dimensions:", src.width, src.height)
                    print("CRS:", src.crs)
                    print("Transform:", src.transform)
                    print("Data type:", src.dtypes)
                    print("NoData:", src.nodata)
                    print("Bounds:", src.bounds)
