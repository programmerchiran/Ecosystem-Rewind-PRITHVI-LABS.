
from pathlib import Path
import zipfile
import rasterio
from rasterio.io import MemoryFile

folder = Path("backend/ml/data/raw/nrsc")

keywords = [
    "forest_fraction",
    "nices_ftg_class",
]

for zip_path in sorted(folder.glob("*.zip")):
    if not any(k in zip_path.name.lower() for k in keywords):
        continue

    print("\n" + "=" * 65)
    print("ZIP:", zip_path.name)

    with zipfile.ZipFile(zip_path) as zf:
        tif_files = [
            name for name in zf.namelist()
            if name.lower().endswith((".tif", ".tiff"))
        ]

        for tif_name in tif_files:
            with zf.open(tif_name) as file:
                content = file.read()

            with MemoryFile(content) as mem:
                with mem.open() as src:
                    print("\nRaster:", tif_name)
                    print("CRS:", src.crs)
                    print("Dimensions:", src.width, src.height)
                    print("Data type:", src.dtypes)
                    print("NoData:", src.nodata)
                    print("Scales:", src.scales)
                    print("Offsets:", src.offsets)
                    print("Band description:", src.descriptions)
                    print("Dataset tags:", src.tags())
                    print("Band tags:", src.tags(1))

                    values = src.read(1, masked=True)
                    if values.count():
                        print("Minimum:", float(values.min()))
                        print("Maximum:", float(values.max()))
