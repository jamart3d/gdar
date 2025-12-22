import json
import os
import sys
from collections import Counter

# We can chain from the previous output if desired, but user didn't specify. 
# Let's use the 'fixed' output from the previous step if it exists, otherwise the base optimized src.
# Previous step was fix_unlabeled_encores.py -> output.optimized_src_fixed.json
# Wait, report_set3_filenames.py used output.optimized_src.json because fixed didn't exist in that dir?
# Let's assume we want to apply this to the best available data. 
# Step 15 said "Saving to assets/data/output.optimized_src_fixed.json".
# So let's try to use that one to preserve previous fixes.

INPUT_FILE = 'assets/data/output.optimized_src_fixed.json'
OUTPUT_FILE = 'assets/data/output.optimized_src_fixed_set3.json'
REPORT_FILE = 'enc3_report.md'

TARGET_START_SONGS = [
  "Alabama Getaway",
  "Bertha",
  "China Cat Sunflower",
  "Cold Rain and Snow",
  "Dark Star",
  "Don't Ease Me In",
  "Greatest Story Ever Told",
  "I Need a Miracle",
  "Iko Iko",
  "It Takes a Lot to Laugh, It Takes a Train to Cry",
  "Mississippi Half-Step Uptown Toodeloo",
  "Morning Dew",
  "Not Fade Away",
  "Playin' in the Band",
  "Samson and Delilah",
  "Seastones",
  "Shakedown Street",
  "Sugar Magnolia",
  "Tennessee Jed",
  "Terrapin Station",
  "The Promised Land"
]

def main():
    # Use the backup file that contains original Set 3s
    infile = 'assets/data/output.optimized_srco.json'
    
    if not os.path.exists(infile):
        print(f"Error: Could not find input file {infile}.")
        return

    print(f"Loading {infile}...")
    try:
        with open(infile, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        print(f"Error reading JSON: {e}")
        return

    fixed_count = 0
    report_lines = []
    
    # Tally of start tracks for the sets being changed
    changed_start_track_tally = Counter()

    for show in data:
        date = show.get('date', 'Unknown')
        
        for source in show.get('sources', []):
            shnid = source.get('id', 'Unknown')
            tracks = source.get('tracks', [])
            
            # Identify Set 3 tracks
            set3_tracks = [t for t in tracks if t.get('s') == 'Set 3']
            
            if not set3_tracks:
                continue
            
            # Check First Track of Set 3
            first_track = set3_tracks[0]
            t_name = first_track.get('t', '').strip()
            
            # Check if it matches target list
            match_found = False
            for target in TARGET_START_SONGS:
                # Check for startswith to handle " - ", " >", etc.
                if t_name == target or t_name.startswith(target + " ") or t_name.startswith(target + "-") or t_name.startswith(target + ">") or t_name.startswith(target):
                    match_found = True
                    break
            
            if match_found:
                continue
            
            # If NO Match -> This is the target for fixing!
            # Change all 'Set 3' tracks to 'Set 2'
            # "don't change the encore" -> logic below only affects 'Set 3' tracks
            
            for t in tracks:
                if t.get('s') == 'Set 3':
                    t['s'] = 'Set 2'
            
            fixed_count += 1
            changed_start_track_tally[t_name] += 1
            report_lines.append(f"| {date} | {shnid} | {t_name} | Set 3 -> Set 2 |")

    # Generate Report
    print(f"Fixed {fixed_count} sources (Merged Set 3 into Set 2).")
    print(f"Generating {REPORT_FILE}...")
    
    with open(REPORT_FILE, 'w', encoding='utf-8') as f:
        f.write("# Set 3 Fix Report (enc3_report)\n\n")
        f.write(f"**Total Sources Fixed**: {fixed_count}\n")
        f.write("Sources where Set 3 started with a song NOT in the target list have been merged into Set 2.\n\n")
        
        f.write("## Set 3 Start Tracks (Converted to Set 2)\n")
        f.write("| Start Track Name | Count |\n")
        f.write("|---|---|\n")
        for track, count in changed_start_track_tally.most_common(50):
            f.write(f"| {track} | {count} |\n")
        f.write("\n")
        
        f.write("## Detailed Changes\n")
        f.write("| Date | SHNID | Set 3 Start Track | Action |\n")
        f.write("|---|---|---|---|\n")
        for line in report_lines:
            f.write(line + "\n")
            
    # Save Data
    print(f"Saving to {OUTPUT_FILE} (Minified)...")
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, separators=(',', ':'))
        
    print("Done.")

if __name__ == '__main__':
    main()
