"""
Ecosystem Rewind: prepare the uploaded NRSC/ISRO 5 km forest and fire rasters.

This script:
- Finds the uploaded ZIP files recursively under --input-dir.
- Extracts the GeoTIFFs into a temporary directory.
- Uses Forest_Fraction_5km_2013.tif as the reference grid.
- Adds forest fraction, available forest-type class rasters (1-13),
  and fire AFD/LFP/SDAFD layers.
- Reprojects fire layers to the reference grid with average resampling.
- Writes a grid-level CSV and a metadata JSON.

IMPORTANT:
- The source products are historical (forest products ~2013; fire 2003-2016).
- Raw forest-type class raster values are retained as *_raw. Do not assume
  their units or interpret them as percentages without the source technical guide.
- This is a FEATURE table, not a labelled ML training dataset.
- It does not generate habitat suitability, restoration, or health labels.
- Review the NRSC/ISRO licence before publishing source data or derivatives online.
"""

from __future__ import annotations

import argparse
import json
import re
import tempfile
import zipfile
from pathlib import Path

import numpy as np
import pandas as pd
import rasterio
from rasterio.warp import reproject, Resampling
from rasterio.transform import xy


def find_zip_files(root: Path):
    return sorted(root.rglob("*.zip"))


def extract_geotiffs(zip_paths, temp_dir: Path):
    extracted = []
    for zip_path in zip_paths:
        try:
            with zipfile.ZipFile(zip_path) as zf:
                for member in zf.namelist():
                    if member.lower().endswith((".tif", ".tiff")):
                        target = temp_dir / f"{zip_path.stem}__{Path(member).name}"
                        target.parent.mkdir(parents=True, exist_ok=True)
                        with zf.open(member) as src, open(target, "wb") as dst:
                            dst.write(src.read())
                        extracted.append(target)
        except zipfile.BadZipFile:
            print(f"WARNING: Cannot read ZIP: {zip_path}")
    return extracted


def identify_layers(tif_paths):
    layers = {"forest_fraction": None, "fire_afd": None,
              "fire_lfp": None, "fire_sdafd": None, "forest_types": {}}

    for path in tif_paths:
        name = path.name.lower()
        if "forest_fraction_5km_2013" in name or "forest_fraction" in name:
            layers["forest_fraction"] = path
        elif "fire_afd" in name or re.search(r"\bafd\b", name):
            layers["fire_afd"] = path
        elif "fire_lpf" in name or "fire_lfp" in name or re.search(r"\blfp\b", name):
            layers["fire_lfp"] = path
        elif "fire_sdafd" in name or "sdafd" in name:
            layers["fire_sdafd"] = path
        else:
            match = re.search(r"class[_-]?(\d+)", name)
            if match:
                layers["forest_types"][int(match.group(1))] = path

    return layers


def read_band(path):
    with rasterio.open(path) as src:
        arr = src.read(1, masked=True).astype("float32")
        return arr.filled(np.nan), src.profile.copy()


def warp_to_reference(path, ref_profile, resampling=Resampling.average):
    destination = np.full(
        (ref_profile["height"], ref_profile["width"]),
        np.nan,
        dtype=np.float32,
    )

    with rasterio.open(path) as src:
        raw = src.read(1)
        valid = src.read_masks(1) > 0

        # Convert only valid pixels, avoiding nodata overflow.
        src_arr = np.full(raw.shape, np.nan, dtype=np.float32)
        src_arr[valid] = raw[valid].astype(np.float32)

        sentinel = -999999.0
        source = np.where(
            np.isfinite(src_arr), src_arr, sentinel
        ).astype(np.float32)

        reproject(
            source=source,
            destination=destination,
            src_transform=src.transform,
            src_crs=src.crs,
            src_nodata=sentinel,
            dst_transform=ref_profile["transform"],
            dst_crs=ref_profile["crs"],
            dst_nodata=np.nan,
            resampling=resampling,
        )

    return destination


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--input-dir", required=True,
        help="Folder containing the uploaded NRSC/ISRO ZIP files"
    )
    parser.add_argument(
        "--output-dir", default="backend/ml/data/processed",
        help="Output folder for CSV and metadata JSON"
    )
    args = parser.parse_args()

    input_dir = Path(args.input_dir).expanduser().resolve()
    output_dir = Path(args.output_dir).expanduser().resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    zip_paths = find_zip_files(input_dir)
    if not zip_paths:
        raise SystemExit(f"No ZIP files found under: {input_dir}")

    print(f"Found {len(zip_paths)} ZIP files.")
    with tempfile.TemporaryDirectory(prefix="ecosystem_rewind_") as tmp:
        tif_paths = extract_geotiffs(zip_paths, Path(tmp))
        layers = identify_layers(tif_paths)

        if layers["forest_fraction"] is None:
            raise SystemExit(
                "Could not find Forest_Fraction_5km_2013.tif. "
                "Check that nices_ffc_2013.zip is present."
            )

        with rasterio.open(layers["forest_fraction"]) as ref:
            ref_profile = ref.profile.copy()
            forest_fraction = ref.read(1, masked=True).astype("float32").filled(np.nan)
            transform = ref.transform
            height, width = ref.height, ref.width
            crs = ref.crs

        print(f"Reference grid: {width} columns x {height} rows; CRS={crs}")

        data = {
            "row": np.repeat(np.arange(height), width),
            "col": np.tile(np.arange(width), height),
        }
        rr = data["row"]
        cc = data["col"]
        xs, ys = xy(transform, rr, cc, offset="center")

        with rasterio.Env():
            from rasterio.warp import transform as transform_coords
            lon, lat = transform_coords(crs, "EPSG:4326", list(xs), list(ys))

        data["longitude"] = np.asarray(lon, dtype=np.float64)
        data["latitude"] = np.asarray(lat, dtype=np.float64)
        data["forest_fraction_2013_raw"] = forest_fraction.ravel()

        for class_id in range(1, 14):
            path = layers["forest_types"].get(class_id)
            col_name = f"forest_type_class_{class_id:02d}_raw"
            if path is None:
                print(f"WARNING: Missing forest type class {class_id}")
                data[col_name] = np.nan
                continue

            with rasterio.open(path) as src:
                same_grid = (
                    src.crs == crs and src.transform == transform
                    and src.width == width and src.height == height
                )
                if same_grid:
                    arr = src.read(1, masked=True).astype("float32").filled(np.nan)
                else:
                    arr = warp_to_reference(path, ref_profile, Resampling.average)
            data[col_name] = arr.ravel()

        for key in ("fire_afd", "fire_lfp", "fire_sdafd"):
            path = layers[key]
            if path is None:
                print(f"WARNING: Missing {key}")
                data[f"{key}_raw"] = np.nan
            else:
                arr = warp_to_reference(path, ref_profile, Resampling.average)
                data[f"{key}_raw"] = arr.ravel()

        df = pd.DataFrame(data)

        # Keep reference-grid cells with a valid forest-fraction pixel.
        df = df[np.isfinite(df["forest_fraction_2013_raw"])].copy()
        df = df.reset_index(drop=True)

        csv_path = output_dir / "india_nrsc_forest_fire_features_5km.csv"
        df.to_csv(csv_path, index=False)

        metadata = {
            "dataset": "Ecosystem Rewind India NRSC/ISRO forest-fire feature table",
            "reference_grid": "Forest_Fraction_5km_2013.tif",
            "reference_crs": str(crs),
            "reference_width": int(width),
            "reference_height": int(height),
            "valid_grid_cells": int(len(df)),
            "available_forest_type_classes": sorted(layers["forest_types"].keys()),
            "expected_forest_type_classes_from_metadata": list(range(1, 15)),
            "missing_forest_type_classes": [
                i for i in range(1, 15) if i not in layers["forest_types"]
            ],
            "fire_period": "2003-2016 (per source metadata)",
            "forest_type_period": "2013 (per source metadata)",
            "forest_fraction_period": "2013 (per source metadata)",
            "columns_with_raw_suffix": (
                "Source raster values retained without assuming units/scaling."
            ),
            "warning": (
                "Feature table only. No verified habitat suitability, restoration "
                "priority, or ecosystem-health labels are created."
            ),
            "source_files": [p.name for p in zip_paths],
        }
        meta_path = output_dir / "india_nrsc_forest_fire_features_5km_metadata.json"
        meta_path.write_text(json.dumps(metadata, indent=2), encoding="utf-8")

        print("\nDONE")
        print(f"Rows: {len(df):,}")
        print(f"CSV: {csv_path}")
        print(f"Metadata: {meta_path}")
        print("\nNext: inspect raster value ranges and add validated GBIF/climate/soil features.")
        print("Do not train on the provisional target columns in the demo CSV as ground truth.")


if __name__ == "__main__":
    main()
