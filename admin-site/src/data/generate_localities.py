"""
Reads eidclean_preprocessed.csv and generates localities.js
in the SAME FOLDER as this script.

Place this script next to eidclean_preprocessed.csv inside src/data/.
Then run from that folder: python generate_localities.py
"""

import csv
import os
import sys

INPUT_CSV = "eidclean_preprocessed.csv"
OUTPUT_JS = "localities.js"   # <-- output in current folder

FEATURED_COUNT = 20


def detect_delimiter(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        first_line = f.readline()
        return "\t" if "\t" in first_line else ","


def main():
    if not os.path.exists(INPUT_CSV):
        print(f"ERROR: {INPUT_CSV} not found in {os.getcwd()}")
        print("Place the CSV next to this script and try again.")
        sys.exit(1)

    delimiter = detect_delimiter(INPUT_CSV)
    print(f"Detected delimiter: {'TAB' if delimiter == chr(9) else 'COMMA'}")

    localities = []
    seen_ids = set()

    with open(INPUT_CSV, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f, delimiter=delimiter)
        for row in reader:
            if str(row.get("Eid_Day", "")).strip() != "1":
                continue
            loc_id = row["Locality_ID"].strip()
            if loc_id in seen_ids:
                continue
            seen_ids.add(loc_id)

            localities.append({
                "id": loc_id,
                "name": row["Locality_Name"].strip(),
                "population": int(float(row["Population_2023"])),
                "housing": int(float(row["Housing_Units"])),
                "areaType": row["Area_Type"].strip(),
                "participationRate": float(row["Estimated_Qurbani_Participation_Rate_pct"]),
            })

    for i, loc in enumerate(localities):
        loc["featured"] = i < FEATURED_COUNT

    with open(OUTPUT_JS, "w", encoding="utf-8") as f:
        f.write("// src/data/localities.js\n")
        f.write("//\n")
        f.write("// Auto-generated from eidclean_preprocessed.csv.\n")
        f.write(f"// Total localities: {len(localities)}\n")
        f.write(f"// Featured (shown by default): {FEATURED_COUNT}\n\n")
        f.write("export const LOCALITIES = [\n")

        for loc in localities:
            name = loc["name"].replace('"', '\\"')
            f.write(
                f'  {{ id: "{loc["id"]}", name: "{name}", '
                f'population: {loc["population"]}, housing: {loc["housing"]}, '
                f'areaType: "{loc["areaType"]}", participationRate: {loc["participationRate"]}, '
                f'featured: {"true" if loc["featured"] else "false"} }},\n'
            )

        f.write("];\n")

    print(f"Done. Wrote {len(localities)} localities to {OUTPUT_JS}")
    print(f"Featured: {sum(1 for l in localities if l['featured'])}")


if __name__ == "__main__":
    main()