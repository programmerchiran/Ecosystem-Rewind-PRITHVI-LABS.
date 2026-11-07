from pathlib import Path
import rasterio

folder = Path("backend/ml/data/raw/nrsc/wc2.1_5m_bio")

for i in range(1, 20):
    path = folder / f"wc2.1_5m_bio_{i}.tif"

    print("\nBIO", i)

    if not path.exists():
        print("MISSING")
        continue

    with rasterio.open(path) as src:
        print("CRS:", src.crs)
        print("Dimensions:", src.width, src.height)
        print("Bounds:", src.bounds)
        print("Resolution:", src.res)
        print("Data type:", src.dtypes)
        print("Nodata:", src.nodata)
        print("Scale:", src.scales)
        print("Offset:", src.offsets)
