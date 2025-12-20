import json
import os
import sys
from collections import Counter

INPUT_FILE = 'assets/data/output.optimized_src.json'
OUTPUT_FILE = 'assets/data/output.optimized_src_blue.json'
REPORT_FILE = 'blue_fix_report.md'

TARGET_WRONG = "It's All Over Now Baby Blue"
TARGET_WRONG_ESCAPED = r"It\'s All Over Now, Baby Blue"
TARGET_BABY_BLUE = "Baby Blue"
TARGET_RIGHT = "It's All Over Now, Baby Blue"

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

    fixed_count = 0
    report_lines = []
    
    # Tally for other "Blue" tracks
    other_blue_tally = Counter()

    for show in data:
        date = show.get('date', 'Unknown')
        
        for source in show.get('sources', []):
            shnid = source.get('id', 'Unknown')
            tracks = source.get('tracks', [])
            
            for t in tracks:
                t_name = t.get('t', '')
                
                # Check for various wrong patterns
                should_fix = False
                matched_wrong_target = ""
                
                # Broad checks
                if t_name == TARGET_WRONG or t_name.startswith(TARGET_WRONG + " ") or t_name.startswith(TARGET_WRONG + "-") or t_name.startswith(TARGET_WRONG + "*"):
                    should_fix = True
                    matched_wrong_target = TARGET_WRONG
                elif t_name == TARGET_WRONG_ESCAPED: 
                    # Exact match for escaped version (rare to have suffix on this typically)
                    should_fix = True
                    matched_wrong_target = TARGET_WRONG_ESCAPED
                elif t_name == TARGET_BABY_BLUE:
                     # Exact match for Baby Blue (be careful not to match "Viola Lee Blues" etc by accident if using substring)
                     # User said "Baby Blue" -> ...
                     should_fix = True
                     matched_wrong_target = TARGET_BABY_BLUE

                if should_fix:
                    
                    # Store old for report
                    old_name = t_name
                    
                    if matched_wrong_target == TARGET_BABY_BLUE:
                         t['t'] = TARGET_RIGHT
                    elif matched_wrong_target == TARGET_WRONG_ESCAPED:
                         t['t'] = TARGET_RIGHT
                    elif matched_wrong_target == TARGET_WRONG:
                        if t_name == TARGET_WRONG:
                            t['t'] = TARGET_RIGHT
                        else:
                            # Replace the substring
                            t['t'] = t_name.replace(TARGET_WRONG, TARGET_RIGHT, 1)
                        
                    fixed_count += 1
                    report_lines.append(f"| {date} | {source.get('src','?')} | {shnid} | {old_name} -> {t['t']} |")
                
                # Check for other "Blue" tracks
                # Use the CURRENT name (t['t']) to check.
                # If we just fixed it, it is now "It's All Over Now, Baby Blue".
                # We want to report OTHER tracks.
                current_name = t.get('t', '')
                if 'blue' in current_name.lower():
                     # Exclude our target song (even the fixed version)
                     if TARGET_RIGHT not in current_name and TARGET_WRONG not in current_name:
                         other_blue_tally[current_name] += 1

    # Generate Report
    print(f"Fixed {fixed_count} instances.")
    print(f"Generating {REPORT_FILE}...")
    
    with open(REPORT_FILE, 'w', encoding='utf-8') as f:
        f.write("# Blue Fix Report\n\n")
        f.write(f"**Total Fixed**: {fixed_count}\n\n")
        
        f.write("## Tally of Other 'Blue' Tracks\n")
        f.write("| Track Name | Count |\n")
        f.write("|---|---|\n")
        for track, count in other_blue_tally.most_common(50):
             f.write(f"| {track} | {count} |\n")
        f.write("\n")
        
        f.write("## Detailed Fixes\n")
        f.write("| Date | Cat | SHNID | Change |\n")
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
