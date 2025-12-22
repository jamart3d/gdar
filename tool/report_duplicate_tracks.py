import json
import os
from collections import Counter

INPUT_FILE = 'assets/data/output.optimized_src.json'
REPORT_FILE = 'dup_report.md'

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

    results = []

    for show in data:
        date = show.get('date', 'Unknown')
        venue = show.get('venue', 'Unknown Venue')
        
        for source in show.get('sources', []):
            shnid = source.get('id', 'Unknown')
            tracks = source.get('tracks', [])
            
            # Extract track names, keeping original casing for reporting but normalizing for comparison if needed
            # User likely wants exact or near-exact duplicates.
            # Let's check for exact string matches first as that's the most obvious "duplicate".
            
            track_names = [t.get('t', '').strip() for t in tracks if t.get('t')]
            
            if not track_names:
                continue

            # Count occurrences
            counts = Counter(track_names)
            
            # User Request: Report ONLY if EVERY track is duplicated (count >= 2)
            # This filters out sources that just have one accidental duplicate but are mostly fine.
            # We are looking for sources that likely have the full show listed twice (e.g. A, B, C, A, B, C)
            
            if counts and all(count >= 2 for count in counts.values()):
                duplicates = counts # All are duplicates
                results.append({
                    'date': date,
                    'shnid': shnid,
                    'duplicates': duplicates,
                    'venue': venue
                })

    print(f"Found {len(results)} sources with duplicate tracks.")
    
    print(f"Generating report {REPORT_FILE}...")
    with open(REPORT_FILE, 'w', encoding='utf-8') as f:
        f.write("# Fully Duplicated Tracks Report\n\n")
        f.write(f"**Sources where EVERY track is listed 2+ times:** {len(results)}\n\n")
        f.write("| Date | SHNID | Tracks (Count) |\n")
        f.write("|---|---|---|\n")
        
        for item in results:
            dups_str = ", ".join([f"{name} ({count})" for name, count in item['duplicates'].items()])
            # Escape pipes for markdown table
            dups_safe = dups_str.replace('|', '-')
            venue_safe = item['venue'].replace('|', '-')
            
            f.write(f"| {item['date']} | {item['shnid']} | {dups_safe} |\n")

    print("Done.")

if __name__ == '__main__':
    main()
