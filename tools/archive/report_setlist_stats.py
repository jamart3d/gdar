import json
import os
import re
import sys
from collections import Counter

# Default input file
DEFAULT_INPUT_FILE = 'assets/data/output.optimized_src.json'
INPUT_FILE = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_INPUT_FILE
REPORT_FILE = 'setlist_report.md'

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

    # Metrics
    total_sources = 0
    sources_with_s123 = 0
    sources_with_s123_enc = 0
    sources_no_encore = 0
    
    # Lists for detail reports
    list_s123 = []
    list_s123_enc = []
    list_s12_enc = []  # Set 1 + Set 2 + Encore (+ maybe Set 3)
    list_no_encore = []
    list_misplaced_enc = []
    list_misplaced_enc = []
    list_suspect_missing_sets = []
    list_ending_with_encore_break = []
    list_long_single_set = []
    list_long_no_encore_s23 = []
    list_duplicate_shnids = []
    
    # Counter for last tracks in No-Encore shows
    no_encore_last_track_tally = Counter()
    
    # Counter for ALL tracks in actual Encore sets (for comparison)
    all_encore_tracks_tally = Counter()

    for show in data:
        date = show.get('date', 'Unknown')
        show_name = show.get('name', 'Unknown Show')
        
        seen_shnids = set()

        for source in show.get('sources', []):
            total_sources += 1
            shnid = source.get('id', 'Unknown')
            
            # Check for duplicate SHNIDs within the same show
            if shnid in seen_shnids:
               list_duplicate_shnids.append({
                   'date': date,
                   'shnid': shnid,
                   'cat': source.get('src', '?'),
                   'details': f"Duplicate SHNID in show: {show_name}"
               })
            else:
               seen_shnids.add(shnid)

            tracks = source.get('tracks', [])
            
            # Analyze sets
            has_set1 = False
            has_set2 = False
            has_set3 = False
            has_encore = False
            encore_tracks = []
            
            last_set_label = None
            
            misplaced_encore_found = False
            misplaced_details = []

            for i, track in enumerate(tracks):
                s_label = track.get('s', '')
                t_name = track.get('t', '')
                
                if s_label == 'Set 1': has_set1 = True
                if s_label == 'Set 2': has_set2 = True
                if s_label == 'Set 3': has_set3 = True
                if s_label == 'Encore': 
                    has_encore = True
                    encore_tracks.append(track)
                    all_encore_tracks_tally[t_name] += 1
                    
                    # Check for misplaced encore: Encore track NOT followed by end of show, 
                    # but followed by a main set track.
                    # Actually, user asked for: "encore tracks that are not after set 1/2/3"
                    # This implies we need to check the ORDER.
                    
                    # Let's check if we have seen an Encore, and then later we see Set 1/2/3.
                    # This is slightly different from "followed immediately by".
                    # But the simplest check for "not after" is:
                    # If current is Encore, check if any SUBSEQUENT track is Set 1/2/3
                    
                    # Ideally, Encore should be at the end.
                    pass
                
                # Check for "Encore tracks that are not after set 1/2/3"
                # This could mean:
                # 1. Encores that appear BEFORE Set 3 (if Set 3 exists)
                # 2. Encores that appear BEFORE Set 2 (if Set 2 exists)
                # 3. Encores that appear BEFORE Set 1 (unlikely but possible error)
                
                # Let's implement logical check:
                # If we are at an "Encore" track, are there any "Set X" tracks AFTER this one?
                if s_label == 'Encore':
                    # Look ahead
                    for next_track in tracks[i+1:]:
                        next_s = next_track.get('s', '')
                        if next_s in ['Set 1', 'Set 2', 'Set 3']:
                            misplaced_encore_found = True
                            misplaced_details.append(f"Track '{t_name}' (Encore) followed by {next_s}")
                            break
                    if misplaced_encore_found:
                        break # Only report source once per loop for simplicity
            
            # Check for suspicious filenames if NO Set 2 or Set 3
            # looking for patterns like d2t01, d3t05 which imply disc 2/3 but we only found Set 1 (or nothing)
            if not has_set2 and not has_set3:
                suspect_tracks = []
                for t in tracks:
                    u_val = t.get('u', '')
                    # Regex for d2t..., d3t..., cd2..., disc2...
                    if re.search(r'(d[2-9]t|cd[2-9]|disc[2-9])', u_val, re.IGNORECASE):
                        suspect_tracks.append(f"{t.get('t','')} ({u_val})")
                
                if suspect_tracks:
                    # Limit output
                    details_str = ", ".join(suspect_tracks[:3]) 
                    if len(suspect_tracks) > 3:
                        details_str += "..."
                        
                    list_suspect_missing_sets.append({
                        'date': date,
                        'shnid': shnid,
                        'cat': source.get('src', '?'),
                        'details': details_str
                    })

            # Tally categories
            is_s123 = has_set1 and has_set2 and has_set3
            is_s12 = has_set1 and has_set2

            if is_s12 and has_encore:
                list_s12_enc.append({'date': date, 'shnid': shnid, 'cat': source.get('src','?')})
            
            if is_s123:
                sources_with_s123 += 1
                list_s123.append({'date': date, 'shnid': shnid, 'cat': source.get('src','?')})
                
                if has_encore:
                    sources_with_s123_enc += 1
                    list_s123_enc.append({'date': date, 'shnid': shnid, 'cat': source.get('src','?')})
            
            if not has_encore:
                sources_no_encore += 1
                list_no_encore.append({'date': date, 'shnid': shnid, 'cat': source.get('src','?')})
                
            if misplaced_encore_found:
                list_misplaced_enc.append({
                    'date': date, 
                    'shnid': shnid, 
                    'cat': source.get('src','?'),
                    'details': misplaced_details[0] # Just the first reason
                })

            # Check for shows ending with "Encore Break"
            if tracks:
                last_track = tracks[-1]
                lt_name = last_track.get('t', '').lower()
                if 'encore' in lt_name and 'break' in lt_name:
                    list_ending_with_encore_break.append({
                        'date': date,
                        'shnid': shnid,
                        'cat': source.get('src', '?'),
                        'track': last_track.get('t', '')
                    })

            # Check for "Single Set" shows that are long (> 12 tracks)
            # Definition: Has Set 1, DOES NOT have Set 2 or Set 3. 
            # (ignoring Encore presence? User said "only 1 set". Usually Encore is separate. 
            #  Let's assume "Only Set 1" means no Set 2, no Set 3. 
            #  If it has Encore, is it "1 set"? Technically 2. 
            #  I will include those strictly without Set 2 or Set 3.
            if has_set1 and not has_set2 and not has_set3:
                if len(tracks) > 12:
                    list_long_single_set.append({
                        'date': date,
                        'shnid': shnid,
                        'cat': source.get('src', '?'),
                        'count': len(tracks)
                    })

            # Check for Long Shows (>12 tracks) with Set 2 or Set 3 but NO Encore
            if (has_set2 or has_set3) and not has_encore and len(tracks) > 12:
                list_long_no_encore_s23.append({
                    'date': date,
                    'shnid': shnid,
                    'cat': source.get('src', '?'),
                    'count': len(tracks)
                })
                
                if tracks:
                    last_track_name = tracks[-1].get('t', 'Unknown')
                    no_encore_last_track_tally[last_track_name] += 1

    # Generate Report
    print(f"Generating {REPORT_FILE}...")
    with open(REPORT_FILE, 'w', encoding='utf-8') as f:
        f.write("# Setlist Analysis Report\n\n")
        f.write("## Summary Tallies\n")
        f.write(f"- **Total Sources**: {total_sources}\n")
        f.write(f"- **Sources with Set 1, 2, AND 3**: {sources_with_s123}\n")
        f.write(f"- **Sources with Set 1, 2, 3 AND Encore**: {sources_with_s123_enc}\n")
        f.write(f"- **Sources with Set 1, 2 AND Encore**: {len(list_s12_enc)}\n")
        f.write(f"- **Sources with NO Encore**: {sources_no_encore}\n")
        f.write(f"- **Sources with Misplaced Encores**: {len(list_misplaced_enc)}\n")
        f.write(f"- **Sources Missing Set 2/3 but have Multi-Disc Files**: {len(list_suspect_missing_sets)}\n")
        f.write(f"- **Sources Ending with 'Encore Break'**: {len(list_ending_with_encore_break)}\n")
        f.write(f"- **Sources with Only Set 1 (and >12 tracks)**: {len(list_long_single_set)}\n")
        f.write(f"- **Sources with Set 2/3, >12 tracks, NO Encore**: {len(list_long_no_encore_s23)}\n")
        f.write(f"- **Shows with Duplicate SHNIDs**: {len(list_duplicate_shnids)}\n\n")

        f.write("## Shows with Duplicate SHNIDs\n")
        f.write("| Date | Cat | SHNID | Details |\n")
        f.write("|---|---|---|---|\n")
        for item in list_duplicate_shnids:
            f.write(f"| {item['date']} | {item['cat']} | {item['shnid']} | {item['details']} |\n")
        f.write("\n")

        f.write("## Sources with Set 1, 2, 3 AND Encore\n")
        f.write("| Date | Cat | SHNID |\n")
        f.write("|---|---|---|\n")
        for item in list_s123_enc:
            f.write(f"| {item['date']} | {item['cat']} | {item['shnid']} |\n")
        f.write("\n")

        f.write("## Sources with Set 1, 2, AND Encore (Set 3 optional)\n")
        f.write("| Date | Cat | SHNID |\n")
        f.write("|---|---|---|\n")
        for item in list_s12_enc:
            f.write(f"| {item['date']} | {item['cat']} | {item['shnid']} |\n")
        f.write("\n")

        f.write("## Sources with Set 1, 2, 3 (regardless of Encore)\n")
        f.write("| Date | Cat | SHNID |\n")
        f.write("|---|---|---|\n")
        for item in list_s123:
            f.write(f"| {item['date']} | {item['cat']} | {item['shnid']} |\n")
        f.write("\n")
        
        f.write("## Sources with NO Encore\n")
        f.write("| Date | Cat | SHNID |\n")
        f.write("|---|---|---|\n")
        for item in list_no_encore:
            f.write(f"| {item['date']} | {item['cat']} | {item['shnid']} |\n")
        f.write("\n")

        f.write("## Sources with Misplaced Encores (Encore track followed by Set 1/2/3)\n")
        f.write("| Date | Cat | SHNID | Issue |\n")
        f.write("|---|---|---|---|\n")
        for item in list_misplaced_enc:
            f.write(f"| {item['date']} | {item['cat']} | {item['shnid']} | {item['details']} |\n")
        f.write("\n")

        f.write("## Sources Missing Set 2/3 but have Multi-Disc Files\n")
        f.write("| Date | Cat | SHNID | Suspicious Tracks |\n")
        f.write("|---|---|---|---|\n")
        for item in list_suspect_missing_sets:
            f.write(f"| {item['date']} | {item['cat']} | {item['shnid']} | {item['details']} |\n")
        f.write("\n")

        f.write("## Sources Ending with 'Encore Break'\n")
        f.write("| Date | Cat | SHNID | Last Track |\n")
        f.write("|---|---|---|---|\n")
        for item in list_ending_with_encore_break:
            f.write(f"| {item['date']} | {item['cat']} | {item['shnid']} | {item['track']} |\n")
        f.write("\n")

        f.write("## Sources with Only Set 1 (and >12 tracks)\n")
        f.write("| Date | Cat | SHNID | Track Count |\n")
        f.write("|---|---|---|---|\n")
        for item in list_long_single_set:
            f.write(f"| {item['date']} | {item['cat']} | {item['shnid']} | {item['count']} |\n")
        f.write("\n")

        f.write("## Sources with Set 2/3, >12 tracks, NO Encore\n")
        f.write("| Date | Cat | SHNID | Track Count |\n")
        f.write("|---|---|---|---|\n")
        for item in list_long_no_encore_s23:
            f.write(f"| {item['date']} | {item['cat']} | {item['shnid']} | {item['count']} |\n")
        f.write("\n")

        f.write("### Last Track Tally for Above Group\n")
        f.write("| Track Name | Count |\n")
        f.write("|---|---|\n")
        for track, count in no_encore_last_track_tally.most_common(20):
            f.write(f"| {track} | {count} |\n")
        f.write("\n")

        f.write("### Reference: Most Common Tracks in Actual Encore Sets\n")
        f.write("| Track Name | Count |\n")
        f.write("|---|---|\n")
        for track, count in all_encore_tracks_tally.most_common(40):
            f.write(f"| {track} | {count} |\n")
        f.write("\n")

    print("Done.")

if __name__ == '__main__':
    main()
