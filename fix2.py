import json

# Configuration
INPUT_FILENAME = 'assets/data/output.optimized.json'
OUTPUT_FILENAME = 'assets/data/output.optimizedo_final2_corrected.json'
REPORT_FILENAME = 'setlist_correction_report.md'

def fix_show_1995_07_09(show, report_lines):
    """
    Applies specific setlist corrections for the Soldier Field 1995-07-09 show.
    """
    changes_made = False

    # Define the split points for this specific show
    set_2_starters = [
        "Shakedown Street", "Samson and Delilah", "So Many Roads",
        "Samba in the Rain", "Corrina", "Drums", "Space",
        "Unbroken Chain", "Sugar Magnolia"
    ]

    encore_starters = [
        "Black Muddy River", "Box Of Rain", "Box of Rain"
    ]

    date = show.get("date", "Unknown Date")

    for source in show.get("sources", []):
        for track in source.get("tracks", []):
            name = track.get("t", "")
            current_set = track.get("s", "")

            new_set = current_set

            # Check if track belongs in Set 2
            if name in set_2_starters:
                new_set = "Set 2"

            # Check if track belongs in Encore
            elif name in encore_starters:
                new_set = "Encore"

            # Apply change if needed
            if new_set != current_set:
                track["s"] = new_set
                report_lines.append(f"  [FIX] {date}: Moved '{name}' from '{current_set}' to '{new_set}'")
                changes_made = True

    return changes_made

def analyze_potential_errors(data, report_lines):
    """
    Scans the data for suspicious setlist structures (e.g., huge single sets)
    and logs warnings to the report.
    """
    report_lines.append("\n### ANALYSIS WARNINGS (Potential Errors to Check)")

    for show in data:
        date = show.get("date", "Unknown Date")

        # Aggregate stats for the show
        set_counts = {}
        total_tracks = 0

        for source in show.get("sources", []):
            # We check the first source as a proxy for the show structure
            for track in source.get("tracks", []):
                s_label = track.get("s", "Unknown")
                set_counts[s_label] = set_counts.get(s_label, 0) + 1
                total_tracks += 1
            break # Analyze only the first source to avoid duplicates in report

        # Heuristic 1: If a show has >15 tracks but only 1 Set label (e.g., all "Set 1")
        if len(set_counts) == 1 and total_tracks > 15:
            label = list(set_counts.keys())[0]
            report_lines.append(f"  [WARN] {date}: Suspicious structure. {total_tracks} tracks found, but all are labeled '{label}'.")

        # Heuristic 2: Large shows missing an Encore (Standard Dead shows usually have one)
        if total_tracks > 12 and "Encore" not in set_counts and "E" not in set_counts:
             # Just a soft warning, as some shows legitimately lack encores or use different labels
             pass

def main():
    report_lines = []
    report_lines.append("# Grateful Dead Setlist Correction Report")
    report_lines.append("\n")

    try:
        print(f"Reading {INPUT_FILENAME}...")
        with open(INPUT_FILENAME, 'r', encoding='utf-8') as f:
            data = json.load(f)

        correction_count = 0

        # Iterate through shows
        for show in data:
            # 1. Apply Specific Fixes
            if show.get("date") == "1995-07-09":
                if fix_show_1995_07_09(show, report_lines):
                    correction_count += 1

        # 2. Run General Analysis
        analyze_potential_errors(data, report_lines)

        # 3. Save Corrected JSON
        print(f"Saving corrected data to {OUTPUT_FILENAME}...")
        with open(OUTPUT_FILENAME, 'w', encoding='utf-8') as f:
            json.dump(data, f, separators=(',', ':'))

        # 4. Save Report
        print(f"Saving report to {REPORT_FILENAME}...")
        with open(REPORT_FILENAME, 'w', encoding='utf-8') as f:
            f.write('\n'.join(report_lines))

        print("\nDone!")
        print(f"Total shows corrected: {correction_count}")
        print(f"Check '{REPORT_FILENAME}' for details and warnings.")

    except FileNotFoundError:
        print(f"Error: Could not find file '{INPUT_FILENAME}'. Please ensure it is in this folder.")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")

if __name__ == "__main__":
    main()