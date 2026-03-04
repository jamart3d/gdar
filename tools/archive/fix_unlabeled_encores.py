import json
import os
import sys
from collections import Counter

INPUT_FILE = 'assets/data/output.optimized_src.json'
OUTPUT_FILE = 'assets/data/output.optimized_src_fixed.json'
REPORT_FILE = 'fix_encores_report.md'

TARGET_SONGS = {
  "And We Bid You Goodnight",
  "Black Muddy River",
  "Box Of Rain",
  "Brokedown Palace",
  "Casey Jones",
  "Don't Ease Me In",
  "I Fought The Law",
  "It's All Over Now, Baby Blue",
  "Johnny B. Goode",
  "Keep Your Day Job",
  "Knockin' On Heaven's Door",
  "Liberty",
  "Lucy In The Sky With Diamonds",
  "Not Fade Away",
  "One More Saturday Night",
  "Quinn The Eskimo",
  "Rain",
  "Satisfaction",
  "Sugar Magnolia",
  "The Weight",
  "Touch Of Grey",
  "U.S. Blues",
  "Uncle John's Band",
  "Werewolves Of London"
}

def normalize_title(t):
    return t.strip()

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
    fixed_via_tuning = 0
    fixed_via_target = 0
    
    report_lines = []
    
    # Tally of changed tracks (individual tracks moved to Encore)
    changed_track_tally = Counter()
    
    # Tally of "Tuning" tracks found near end
    tuning_track_tally = Counter()
    tuning_sources_count = 0
    
    # Tally of sequences appearing AFTER tuning
    post_tuning_sequence_tally = Counter()

    for show in data:
        date = show.get('date', 'Unknown')
        
        for source in show.get('sources', []):
            shnid = source.get('id', 'Unknown')
            tracks = source.get('tracks', [])
            
            # Criteria 1: Length > 12
            if len(tracks) <= 12:
                continue
            
            # Criteria 2: Check Sets
            has_set2 = False
            has_set3 = False
            has_encore = False
            
            for t in tracks:
                s = t.get('s', '')
                if s == 'Set 2': has_set2 = True
                if s == 'Set 3': has_set3 = True
                if s == 'Encore': has_encore = True
            
            # Must have Set 2 OR Set 3
            if not (has_set2 or has_set3):
                continue
                
            # Must NOT have Encore already
            if has_encore:
                continue

            # --- logic start ---
            fixed_this_source = False

            # STRATEGY 1: Check for "Tuning" near the end
            # Search in last 3 tracks, but ensure there is at least one track AFTER it.
            tuning_idx = -1
            start_search = max(0, len(tracks) - 3)
            # End at len(tracks) - 2 so that i+1 is a valid index
            for i in range(start_search, len(tracks) - 1):
                t_name_raw = tracks[i].get('t', '')
                t_name_lower = t_name_raw.lower()
                if 'tuning' in t_name_lower:
                    tuning_idx = i
                    # Capture formatting for tally
                    tuning_track_tally[t_name_raw] += 1
                    tuning_track_name = t_name_raw
                    break # Take the first tuning found in this range
            
            if tuning_idx != -1:
                # Apply Fix: Move all subsequent tracks to Encore
                subsequent_tracks = []
                # old_s_label = tracks[tuning_idx+1].get('s', '?') # Unused
                
                for j in range(tuning_idx + 1, len(tracks)):
                    tracks[j]['s'] = 'Encore'
                    t_title = tracks[j].get('t', '')
                    subsequent_tracks.append(t_title)
                    changed_track_tally[t_title] += 1
                
                seq_str = " -> ".join(subsequent_tracks)
                post_tuning_sequence_tally[seq_str] += 1
                
                report_lines.append(f"| {date} | {source.get('src','?')} | {shnid} | {seq_str} | Sequence after '{tuning_track_name}' -> Encore |")
                
                fixed_count += 1
                fixed_via_tuning += 1
                tuning_sources_count += 1
                fixed_this_source = True

            # STRATEGY 2: Last Track Match (Fallback)
            if not fixed_this_source:
                last_track = tracks[-1]
                t_name = normalize_title(last_track.get('t', ''))
                
                match_found = False
                matched_song = ""
                
                for target in TARGET_SONGS:
                    if t_name == target:
                        match_found = True
                        matched_song = target
                        break
                    if t_name.startswith(target):
                        remainder = t_name[len(target):]
                        if not remainder or not remainder[0].isalnum():
                            match_found = True
                            matched_song = target
                            break
                            
                if match_found:
                    old_s = last_track.get('s', '?')
                    last_track['s'] = 'Encore'
                    
                    changed_track_tally[matched_song] += 1
                    report_lines.append(f"| {date} | {source.get('src','?')} | {shnid} | {t_name} | {old_s} -> Encore (Target Match) |")
                    
                    fixed_count += 1
                    fixed_via_target += 1
                    fixed_this_source = True

    # Generate Report
    print(f"Fixed {fixed_count} sources ({fixed_via_tuning} via Tuning, {fixed_via_target} via Target Match).")
    print(f"Generating {REPORT_FILE}...")
    
    with open(REPORT_FILE, 'w', encoding='utf-8') as f:
        f.write("# Fix Unlabeled Encores Report\n\n")
        f.write(f"**Total Fixed**: {fixed_count}\n")
        f.write(f"- Via Tuning Sequence: {fixed_via_tuning}\n")
        f.write(f"- Via Target Song Match: {fixed_via_target}\n\n")
        
        f.write("## Tally of Changed Tracks\n")
        f.write("| Track Name | Count |\n")
        f.write("|---|---|\n")
        for track, count in changed_track_tally.most_common():
            f.write(f"| {track} | {count} |\n")
        f.write("\n")
        
        if fixed_via_tuning > 0:
            f.write("## Tuning Tracks Found Near End\n")
            f.write(f"**Sources with Tuning tracks used for fix**: {tuning_sources_count}\n\n")
            f.write("| Track Name | Count |\n")
            f.write("|---|---|\n")
            for track, count in tuning_track_tally.most_common(20):
                f.write(f"| {track} | {count} |\n")
            f.write("\n")
            
            f.write("## Sequences Following 'Tuning' (Moved to Encore)\n")
            f.write("| Sequence | Count |\n")
            f.write("|---|---|\n")
            for seq, count in post_tuning_sequence_tally.most_common(50):
                f.write(f"| {seq} | {count} |\n")
            f.write("\n")

        f.write("## Detailed Changes\n")
        f.write("| Date | Cat | SHNID | Track(s) | Change |\n")
        f.write("|---|---|---|---|---|\n")
        for line in report_lines:
            f.write(line + "\n")
            
    # Save Data
    print(f"Saving to {OUTPUT_FILE} (Minified)...")
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, separators=(',', ':'))
        
    print("Done.")

if __name__ == '__main__':
    main()
