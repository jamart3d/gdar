import json
import os

INPUT_FILE = 'assets/data/output.optimized_src_fixed_encores.json'
REPORT_FILE = 'report_long_encores_fixed.md'

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
            
            has_set2 = False
            has_set3 = False
            encore_tracks = []

            for t in tracks:
                set_name = t.get('s', '').lower()
                if set_name == 'set 2':
                    has_set2 = True
                elif set_name == 'set 3':
                    has_set3 = True
                elif set_name == 'encore':
                    t_name = t.get('t', 'Unknown Track')
                    # Exclude "encore" variations (e.g. "Encore Break") from count
                    if 'encore' not in t_name.lower():
                        encore_tracks.append(t_name)
            
            # Criteria: (Set 2 OR Set 3 exists) AND (Encore has >= 2 tracks)
            if (has_set2 or has_set3) and len(encore_tracks) >= 2:
                results.append({
                    'date': date,
                    'venue': venue,
                    'shnid': shnid,
                    'encore_count': len(encore_tracks),
                    'encore_tracks': encore_tracks
                })

    print(f"Found {len(results)} matching sources.")
    
    # Tally pre-final encore tracks
    from collections import Counter
    pre_final_tally = Counter()
    
    for item in results:
        tracks = item['encore_tracks']
        # "Before the last encore track" -> all except the last one
        pre_final_tracks = tracks[:-1]
        for t in pre_final_tracks:
            # Normalize for tallying
            t_clean = t.strip()
            pre_final_tally[t_clean] += 1

    print(f"Generating report {REPORT_FILE}...")
    with open(REPORT_FILE, 'w', encoding='utf-8') as f:
        f.write("# Long Encore Report\n\n")
        f.write("Criteria: Shows having **Set 2** or **Set 3** present AND **2 or more tracks** in the **Encore** set.\n\n")
        
        # Write Tally Section
        f.write("## Pre-Final Encore Track Tally\n")
        f.write("Frequency of tracks appearing in the Encore set *before* the final track.\n\n")
        f.write("| Track Name | Count |\n")
        f.write("|---|---|\n")
        for track, count in pre_final_tally.most_common():
             # Basic Markdown escape for pipes
            safe_track = track.replace('|', '-') 
            f.write(f"| {safe_track} | {count} |\n")
        f.write("\n" + "="*80 + "\n\n")

        f.write(f"## Detailed List (Total: {len(results)})\n\n")
        f.write("| Date | SHNID | Count | Tracks |\n")
        f.write("|---|---|---|---|\n")
        
        for item in results:
            track_list = ", ".join(item['encore_tracks'])
            if len(track_list) > 100:
                track_list = track_list[:97] + "..."
            venue_safe = item['venue'].replace('|', '-')
            f.write(f"| {item['date']} | {item['shnid']} | {item['encore_count']} | {track_list} |\n")

    print("Done.")

if __name__ == '__main__':
    main()
