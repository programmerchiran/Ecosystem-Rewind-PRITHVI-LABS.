import zipfile
from pathlib import Path

folder = Path("backend/ml/data/raw/nrsc")

checks = {
    "nices_ffc_2013.zip": "forest_fraction_5km_2013.asc",
    "nices_ftg_class1.zip": "forest_type_5km_class1.asc",
    "nices_ftg_class5.zip": "forest_type_5km_class5.asc",
    "nices_ftg_class14.zip": "forest_type_5km_class14.asc",
}

for zip_name, asc_name in checks.items():
    print("\n" + "=" * 65)
    print("SOURCE:", zip_name)

    with zipfile.ZipFile(folder / zip_name) as archive:
        with archive.open(asc_name) as f:
            for i in range(6):
                line = f.readline().decode("utf-8", errors="replace").strip()
                if not line:
                    break
                print(line)
