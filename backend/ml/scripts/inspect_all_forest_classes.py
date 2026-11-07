import zipfile
import io
import numpy as np
from pathlib import Path

folder = Path("backend/ml/data/raw/nrsc")

def read_ascii(zip_name, filename):
    with zipfile.ZipFile(folder / zip_name) as archive:
        raw = archive.read(filename)
    array = np.loadtxt(io.BytesIO(raw), skiprows=6, dtype=np.float64)
    array[array == -9999] = np.nan
    return array

forest = read_ascii(
    "nices_ffc_2013.zip",
    "forest_fraction_5km_2013.asc"
)

classes = []

print("FOREST FRACTION")
print("Shape:", forest.shape)
print("Min:", np.nanmin(forest))
print("Max:", np.nanmax(forest))
print("Percentiles:", np.nanpercentile(
    forest, [0, 25, 50, 75, 90, 95, 99, 100]
))

print("\nFOREST TYPE CLASSES")

for i in range(1, 15):
    zip_name = f"nices_ftg_class{i}.zip"
    filename = f"forest_type_5km_class{i}.asc"

    arr = read_ascii(zip_name, filename)
    classes.append(arr)

    valid = np.isfinite(arr)
    positive = valid & (arr > 0)

    print(
        f"Class {i:02d}: "
        f"min={np.nanmin(arr):.0f}, "
        f"max={np.nanmax(arr):.0f}, "
        f"positive={positive.sum()}, "
        f"valid={valid.sum()}"
    )

stack = np.stack(classes)
class_sum = np.nansum(stack, axis=0)

valid_both = np.isfinite(forest) & np.any(np.isfinite(stack), axis=0)
difference = class_sum - forest

print("\nCLASS SUM VS FOREST FRACTION")
print("Valid comparable cells:", valid_both.sum())
print("Class sum > forest fraction:",
      np.sum(valid_both & (difference > 1000)))
print("Class sum > 1,000,000:",
      np.sum(valid_both & (class_sum > 1_000_000)))
print("Class sum percentiles:",
      np.nanpercentile(class_sum[valid_both], [0, 25, 50, 75, 90, 95, 99, 100]))

print("\nNUMBER OF POSITIVE CLASSES PER CELL")
positive_counts = np.sum(np.isfinite(stack) & (stack > 0), axis=0)
values, counts = np.unique(positive_counts[valid_both], return_counts=True)

for value, count in zip(values, counts):
    print(f"{value} classes: {count} cells")

print("\nCLASS 14 CHECK")
print("Class 14 positive cells:", np.sum(np.isfinite(classes[13]) & (classes[13] > 0)))
