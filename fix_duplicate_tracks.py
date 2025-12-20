import json
import os
from collections import Counter

INPUT_FILE = 'assets/data/output.optimized_src.json'
OUTPUT_FILE = 'assets/data/output.optimized_src_fixed.json'
REPORT_FILE = 'dup_fix_report.md'

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

    fixed_sources = []

    for show in data:
        date = show.get('date', 'Unknown')
        venue = show.get('venue', 'Unknown Venue')
        
        for source in show.get('sources', []):
            shnid = source.get('id', 'Unknown')
            tracks = source.get('tracks', [])
            
            track_names = [t.get('t', '').strip() for t in tracks if t.get('t')]
            
            if not track_names:
                continue

            counts = Counter(track_names)
            
            # STRICT FILTER: Only fix if EVERY track appears >= 2 times.
            if counts and all(count >= 2 for count in counts.values()):
                # Fix: Keep only the first occurrence of each track title
                # This preserves order and removes strings of duplicates.
                # Note: This might crush a reprise sandwich (A, B, A -> A, B), but 
                # given the "every track duplicated" criteria, it's safer to assume broken data.
                
                unique_tracks = []
                seen_titles = set()
                
                for t in tracks:
                    t_name = t.get('t', '').strip()
                    if t_name not in seen_titles:
                        unique_tracks.append(t)
                        seen_titles.add(t_name)
                
                # Update the source's tracks
                source['tracks'] = unique_tracks
                
                fixed_sources.append({
                    'date': date,
                    'shnid': shnid,
                    'original_count': len(tracks),
                    'new_count': len(unique_tracks),
                    'tracks_removed': len(tracks) - len(unique_tracks)
                })

    print(f"Fixed {len(fixed_sources)} sources.")
    
    print(f"Saving to {OUTPUT_FILE}...")
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, separators=(',', ':'))

    print(f"Generating report {REPORT_FILE}...")
    with open(REPORT_FILE, 'w', encoding='utf-8') as f:
        f.write("# Duplicate Track Fix Report\n\n")
        f.write(f"**Total Sources Fixed:** {len(fixed_sources)}\n\n")
        f.write("| Date | SHNID | Original Count | New Count | Tracks Removed |\n")
        f.write("|---|---|---|---|---|\n")
        
        for item in fixed_sources:
            f.write(f"| {item['date']} | {item['shnid']} | {item['original_count']} | {item['new_count']} | {item['tracks_removed']} |\n")

    print("Done.")

if __name__ == '__main__':
    main()
