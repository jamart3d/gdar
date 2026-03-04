import json
import re
import os
from collections import Counter

INPUT_FILE = 'assets/data/output.optimized_src.json'
REPORT_FILE = 'report.md'

TARGET_START_SONGS = [
  "Alabama Getaway",
  "Bertha",
  "Cold Rain and Snow",
  "Dark Star",
  "Don't Ease Me In",
  "I Need a Miracle",
  "It Takes a Lot to Laugh, It Takes a Train to Cry",
  "Mississippi Half-Step Uptown Toodeloo",
  "Morning Dew",
  "Not Fade Away",
  "Samson and Delilah",
  "Sugar Magnolia",
  "Terrapin Station",
  "The Promised Land"
]

def main():
    if not os.path.exists(INPUT_FILE):
        print(f"Error: {INPUT_FILE} not found.")
        return

    print(f"Loading {INPUT_FILE}...")
    try:
        with open(INPUT_FILE, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        print(f"Error reading JSON: {e}")
        return

    pattern = re.compile(r'd\d+t\d+', re.IGNORECASE)

    sources_with_set3_count = 0
    sources_matching_criteria = 0
    sources_with_d3 = 0
    shows_with_set3_count = 0
    
    # New tallies
    set3_starts_with_target_count = 0
    set3_starts_with_other_count = 0
    other_start_tracks_tally = Counter()
    
    report_lines = []

    for show in data:
        date = show.get('date', 'Unknown')
        show_has_set3 = False
        
        for source in show.get('sources', []):
            shnid = source.get('id', 'Unknown')
            tracks = source.get('tracks', [])
            
            # Check for Set 3
            set3_tracks = [t for t in tracks if t.get('s') == 'Set 3']
            
            if set3_tracks:
                show_has_set3 = True
                sources_with_set3_count += 1
                
                # Check for filename pattern & d3
                found_match = False
                has_d3 = False
                example_match = ""
                
                for t in tracks:
                    u = t.get('u', '')
                    if pattern.search(u):
                        found_match = True
                        example_match = u
                    if 'd3' in u.lower():
                        has_d3 = True
                
                if found_match:
                    sources_matching_criteria += 1
                    report_lines.append(f"| {date} | {shnid} | {example_match} |")
                    
                if has_d3:
                    sources_with_d3 += 1
                    
                # Check Set 3 Start Track
                first_track = set3_tracks[0]
                t_name = first_track.get('t', '').strip()
                
                match_found = False
                for target in TARGET_START_SONGS:
                    # Check if track name starts with target (handling " - " etc)
                    if t_name == target or t_name.startswith(target + " ") or t_name.startswith(target + "-") or t_name.startswith(target + ">"):
                        match_found = True
                        break
                    # Also simple startswith if exact match isn't required strictly
                    if t_name.startswith(target):
                        match_found = True
                        break
                
                if match_found:
                    set3_starts_with_target_count += 1
                else:
                    set3_starts_with_other_count += 1
                    other_start_tracks_tally[t_name] += 1
        
        if show_has_set3:
            shows_with_set3_count += 1

    print(f"Total Shows with 'Set 3': {shows_with_set3_count}")
    print(f"Total Sources with 'Set 3': {sources_with_set3_count}")
    print(f"Sources with 'Set 3' AND matching filename pattern (d#t#): {sources_matching_criteria}")
    print(f"Sources with 'Set 3' AND 'd3' in filename: {sources_with_d3}")
    print("-" * 20)
    print(f"Set 3 Starts with Target Song: {set3_starts_with_target_count}")
    print(f"Set 3 Starts with Other: {set3_starts_with_other_count}")
    
    print(f"Saving report to {REPORT_FILE}...")
    
    with open(REPORT_FILE, 'w', encoding='utf-8') as f:
        f.write("# Set 3 Analysis Report\n\n")
        
        f.write("## Summary Stats\n")
        f.write(f"- **Total Shows with 'Set 3'**: {shows_with_set3_count}\n")
        f.write(f"- **Total Sources with 'Set 3'**: {sources_with_set3_count}\n")
        f.write(f"- **Sources with 'Set 3' AND matching filename pattern (d#t#)**: {sources_matching_criteria}\n")
        f.write(f"- **Sources with 'Set 3' AND 'd3' in filename**: {sources_with_d3}\n\n")
        
        f.write("## Set 3 Start Track Analysis\n")
        f.write(f"- **Set 3 starts with a song from the list**: {set3_starts_with_target_count}\n")
        f.write(f"- **Set 3 starts with OTHER song**: {set3_starts_with_other_count}\n\n")
        
        f.write("### Top 'Other' Start Tracks\n")
        f.write("| Track Name | Count |\n")
        f.write("|---|---|\n")
        for t, c in other_start_tracks_tally.most_common(20):
             f.write(f"| {t} | {c} |\n")
        f.write("\n")

        f.write("## Sources with Set 3 (d#t# match)\n")
        f.write("| Date | SHNID | Example Filename |\n")
        f.write("|---|---|---|\n")
        for line in report_lines:
            f.write(line + "\n")
            
    print("Done.")

if __name__ == '__main__':
    main()
