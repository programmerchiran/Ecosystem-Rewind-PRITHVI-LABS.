from pathlib import Path
import zipfile

base = Path("backend/ml/data/raw/nrsc")

files = [
    "nices_ff_AFD.zip",
    "nices_ff_LFP.zip",
    "nices_ff_SDAFD.zip",
]

for filename in files:
    path = base / filename

    print("\n" + "=" * 60)
    print("ZIP:", filename)

    with zipfile.ZipFile(path) as z:
        for name in z.namelist():
            print(name)
