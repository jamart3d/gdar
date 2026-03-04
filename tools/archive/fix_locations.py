import json
import argparse
import sys
from collections import defaultdict

# Corrections map
LOCATION_CORRECTIONS = {
    "Ind": "Bloomington, IN",
    "Giza, 08": "Giza, Egypt",
    "Hamburg, 04": "Hamburg, GER",
    "Munich, Ger": "Munich, GER",
    "Northern Illinois U": "Northern Illinois University",
    "Bremen, 03": "Bremen, GER",
    "Barcelona, 56": "Barcelona, ESP"
}

def fix_locations(input_file, output_file, report_file):
    print(f"Reading {input_file}...")
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        print(f"FATAL: {e}")
        sys.exit(1)

    changes = []
    
    for show in data:
        loc = show.get('l')
        date = show.get('date', 'Unknown')
        
        if loc in LOCATION_CORRECTIONS:
            new_loc = LOCATION_CORRECTIONS[loc]
            show['l'] = new_loc
            changes.append({
                "date": date,
                "old": loc,
                "new": new_loc,
                "video": show.get('name', '')
            })

    print(f"Applied {len(changes)} corrections.")

    # Write Output
    print(f"Writing to {output_file}...")
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, separators=(',', ':'))

    # Write Report
    print(f"Writing report to {report_file}...")
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write("# Location Correction Report\n\n")
        f.write(f"Total Corrections: {len(changes)}\n\n")
        
        if changes:
           f.write("| Date | Venue | Old Location | New Location |\n")
           f.write("| :--- | :--- | :--- | :--- |\n")
           for c in changes:
               f.write(f"| {c['date']} | {c['video']} | {c['old']} | {c['new']} |\n")
        else:
            f.write("No corrections needed based on the current list.\n")

    print("Done.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--input', default='assets/data/output.optimized_src.json')
    parser.add_argument('--output', default='assets/data/output.optimized_src_fixed_locs.json')
    parser.add_argument('--report', default='location_fix_report.md')
    args = parser.parse_args()
    
    fix_locations(args.input, args.output, args.report)
