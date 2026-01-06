import json
import argparse
import sys
from collections import defaultdict

def report_locations(input_file, output_file):
    print(f"Reading {input_file}...")
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        print(f"FATAL: {e}")
        sys.exit(1)

    location_counts = defaultdict(int)
    shows_by_location = defaultdict(list)
    missing_l = 0

    for show in data:
        loc = show.get('l')
        date = show.get('date', 'Unknown Date')
        venue = show.get('name', 'Unknown Venue')
        
        if not loc:
            missing_l += 1
            shows_by_location['(Missing Location)'].append(f"{date} - {venue}")
            location_counts['(Missing Location)'] += 1
        else:
            location_counts[loc] += 1
            shows_by_location[loc].append(f"{date} - {venue}")

    # Sort locations by name
    sorted_locations = sorted(location_counts.keys())
    # Or maybe by count? Let's do alphabetical for lookup, but maybe provide a top list too.
    # User just said "report md all locations".
    
    print(f"Found {len(location_counts)} unique locations. Writing to {output_file}...")
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("# Location Report\n\n")
        f.write(f"Total Unique Locations: {len(location_counts)}\n")
        f.write(f"Shows Missing Location: {missing_l}\n\n")
        
        f.write("## Locations Table\n\n")
        f.write("| Location | Count |\n")
        f.write("| :--- | :---: |\n")
        
        for loc in sorted_locations:
            count = location_counts[loc]
            f.write(f"| {loc} | {count} |\n")
            
        f.write("\n## Detailed Show Lists\n\n")
        for loc in sorted_locations:
            f.write(f"### {loc} ({location_counts[loc]})\n")
            # Sort shows by date
            shows = sorted(shows_by_location[loc])
            for s in shows:
                f.write(f"- {s}\n")
            f.write("\n")

    print("Done.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--input', default='assets/data/output.optimized_src.json')
    parser.add_argument('--output', default='locations_report.md')
    args = parser.parse_args()
    
    report_locations(args.input, args.output)
