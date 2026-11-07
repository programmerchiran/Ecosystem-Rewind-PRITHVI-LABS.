import zipfile
from pathlib import Path

folder = Path("backend/ml/data/raw/nrsc")

files_to_read = {
    "nices_ftg_class1.zip": ["metadata_ftg.xml"],
    "nices_ff_AFD.zip": [
        "metadata_ff.xml", "readme.txt", "policy.txt"
    ],
    "nices_ff_LFP.zip": [
        "metadata_ff.xml", "readme.txt", "policy.txt"
    ],
    "nices_ff_SDAFD.zip": [
        "metadata_ff.xml", "readme.txt", "policy.txt"
    ],
}

for zip_name, wanted_files in files_to_read.items():
    path = folder / zip_name
    print("\n" + "=" * 80)
    print("ZIP:", zip_name)

    with zipfile.ZipFile(path) as archive:
        for wanted in wanted_files:
            matches = [
                name for name in archive.namelist()
                if name.lower().endswith(wanted.lower())
            ]

            for name in matches:
                print("\n---", name, "---")
                raw = archive.read(name)
                print(raw.decode("utf-8", errors="replace"))
