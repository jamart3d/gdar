import json
import os
from collections import defaultdict

def audit_sets():
    input_file = 'assets/data/output.optimized_src.json'
    report_file = 'set_audit_report.md'
    
    if not os.path.exists(input_file):
        print(f"Error: {input_file} not found.")
        return

    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # 1. Duplicate Sources (SHNID check)
    shnid_counts = defaultdict(list)
    
    # 2. Long Set 1 (Only Set 1, > 12 tracks)
    long_set1_sources = []
    
    # 3. Short Set 1 (>1 sets, Set 1 has == 1 track)
    short_set1_sources = []
    
    # 4. Long Encore (>2 tracks, title contains "encore")
    long_encore_sources = []

    for show in data:
        show_date = show.get('date', 'Unknown')
        show_venue = show.get('venue', 'Unknown')
        
        for source in show.get('sources', []):
            shnid = source.get('id', 'Unknown')
            # Track SHNID location
            shnid_counts[shnid].append(f"{show_date} - {show_venue}")
            
            sets = source.get('sets', [])
            if not sets:
                continue
                
            # Check 2: Only Set 1 > 12 tracks
            if len(sets) == 1:
                s = sets[0]
                # Check if name is exactly "Set 1" or just check if it's the only set? 
                # User said "sources with only set 1". I will check if name is "Set 1".
                if s.get('n') == "Set 1" and len(s.get('t', [])) > 12:
                    long_set1_sources.append({
                        'date': show_date,
                        'venue': show_venue,
                        'id': shnid,
                        'count': len(s.get('t', []))
                    })
            
            # Check 3: > 1 set, Set 1 has == 1 song
            if len(sets) > 1:
                # Find Set 1
                set1 = next((s for s in sets if s.get('n') == "Set 1"), None)
                if set1 and len(set1.get('t', [])) == 1:
                    track_name = set1.get('t', [])[0].get('t', 'Unknown')
                    short_set1_sources.append({
                        'date': show_date,
                        'venue': show_venue,
                        'id': shnid,
                        'track': track_name,
                        'sets_count': len(sets)
                    })

            # Check 4: Encore > 2 tracks, one title has "encore" AND is not the first track
            # Find Encore sets
            encores = [s for s in sets if "encore" in s.get('n', '').lower()]
            for e in encores:
                tracks = e.get('t', [])
                if len(tracks) > 2:
                    # Check for "encore" in track titles, but skip the first track
                    # We look for any track from index 1 onwards that contains "encore"
                    other_tracks = tracks[1:]
                    has_encore_in_later_tracks = any("encore" in t.get('t', '').lower() for t in other_tracks)
                    
                    if has_encore_in_later_tracks:
                        long_encore_sources.append({
                            'date': show_date,
                            'venue': show_venue,
                            'id': shnid,
                            'set_name': e.get('n'),
                            'count': len(tracks),
                            'tracks': [t.get('t') for t in tracks]
                        })

    # Generate Report
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write("# Set Structure Audit Report\n\n")
        
        # 1. Duplicate Sources
        duplicates = {k: v for k, v in shnid_counts.items() if len(v) > 1}
        f.write(f"## 1. Duplicate Sources ({len(duplicates)} found)\n")
        if duplicates:
            f.write("| SHNID | Locations |\n")
            f.write("|-------|-----------|\n")
            for shnid, locs in duplicates.items():
                f.write(f"| {shnid} | {', '.join(locs)} |\n")
        else:
            f.write("No duplicate sources found.\n")
        f.write("\n")

        # 2. Long Set 1
        f.write(f"## 2. Single 'Set 1' with > 12 Tracks ({len(long_set1_sources)} found)\n")
        if long_set1_sources:
            for s in long_set1_sources:
                f.write(f"- **{s['date']}** (SHNID {s['id']}): {s['count']} tracks\n")
        else:
            f.write("None found.\n")
        f.write("\n")

        # 3. Short Set 1
        f.write(f"## 3. Multiple Sets with Single-Track 'Set 1' ({len(short_set1_sources)} found)\n")
        if short_set1_sources:
            for s in short_set1_sources:
                f.write(f"- **{s['date']}** (SHNID {s['id']}): Track '{s['track']}'\n")
        else:
            f.write("None found.\n")
        f.write("\n")

        # 4. Long Encore
        f.write(f"## 4. Long Encores (>2 tracks) containing 'Encore' in title ({len(long_encore_sources)} found)\n")
        if long_encore_sources:
            for s in long_encore_sources:
                f.write(f"- **{s['date']}** (SHNID {s['id']}) - {s['set_name']}: {s['count']} tracks\n")
                for t in s['tracks']:
                    f.write(f"  - {t}\n")
        else:
            f.write("None found.\n")
        f.write("\n")

    print(f"Report generated at {report_file}")

if __name__ == "__main__":
    audit_sets()
