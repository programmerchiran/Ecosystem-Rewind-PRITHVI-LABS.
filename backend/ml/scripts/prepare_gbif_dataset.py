
from pathlib import Path
import pandas as pd

BASE = Path(__file__).resolve().parent.parent
RAW_DIR = BASE / "data" / "raw" / "gbif"
OUT_DIR = BASE / "data" / "processed"

INPUT = RAW_DIR / "0000045-261104105008071.zip"
OUTPUT = OUT_DIR / "india_gbif_plants_clean.csv"

OUT_DIR.mkdir(parents=True, exist_ok=True)

COLUMNS = [
    "gbifID",
    "kingdom",
    "phylum",
    "class",
    "order",
    "family",
    "genus",
    "species",
    "taxonRank",
    "scientificName",
    "countryCode",
    "stateProvince",
    "decimalLatitude",
    "decimalLongitude",
    "coordinateUncertaintyInMeters",
    "year",
    "basisOfRecord",
    "occurrenceStatus",
    "datasetKey",
]

print("Reading GBIF archive in chunks...")

total = 0
kept = 0
first_chunk = True

for chunk in pd.read_csv(
    INPUT,
    sep="\t",
    compression="zip",
    usecols=COLUMNS,
    chunksize=100000,
    low_memory=False,
):
    total += len(chunk)

    for col in [
        "decimalLatitude",
        "decimalLongitude",
        "coordinateUncertaintyInMeters",
        "year",
    ]:
        chunk[col] = pd.to_numeric(chunk[col], errors="coerce")

    mask = (
        chunk["kingdom"].eq("Plantae")
        & chunk["countryCode"].eq("IN")
        & chunk["taxonRank"].eq("SPECIES")
        & chunk["species"].notna()
        & chunk["decimalLatitude"].between(6, 38)
        & chunk["decimalLongitude"].between(67, 99)
        & chunk["coordinateUncertaintyInMeters"].between(0, 1000)
        & chunk["year"].between(2000, 2025)
        & chunk["basisOfRecord"].isin([
            "HUMAN_OBSERVATION",
            "PRESERVED_SPECIMEN",
        ])
        & chunk["occurrenceStatus"].eq("PRESENT")
    )

    clean = chunk.loc[mask, COLUMNS].copy()

    clean.to_csv(
        OUTPUT,
        mode="w" if first_chunk else "a",
        header=first_chunk,
        index=False,
    )

    kept += len(clean)
    first_chunk = False

    print(f"Processed {total:,} | Retained {kept:,}")

print("\n--- GBIF CLEANING REPORT ---")
print("Total source records:", f"{total:,}")
print("Retained records:", f"{kept:,}")
print("Output:", OUTPUT)

print("\nGBIF cleaning completed.")
