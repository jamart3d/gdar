import json
import os
import sys

INPUT_DATA_FILE = 'assets/data/output.optimized_src.json'
CORRECTIONS_FILE = 'tool/set_mismatches_corrections.json'
OUTPUT_FILE = 'assets/data/output.optimized_src.fixed_mismatches.json'

def main():
    if not os.path.exists(INPUT_DATA_FILE):
        print(f"Error: {INPUT_DATA_FILE} not found.")
        return
    if not os.path.exists(CORRECTIONS_FILE):
        print(f"Error: {CORRECTIONS_FILE} not found.")
        return

    print(f"Loading data from {INPUT_DATA_FILE}...")
    with open(INPUT_DATA_FILE, 'r', encoding='utf-8') as f:
        data = json.load(f)

    print(f"Loading corrections from {CORRECTIONS_FILE}...")
    with open(CORRECTIONS_FILE, 'r', encoding='utf-8') as f:
        corrections = json.load(f)

    # Index corrections by ID for fast lookup
    corrections_map = {item['id']: item['tracks'] for item in corrections}
    
    print(f"Loaded {len(corrections_map)} corrections.")

    applied_count = 0
    shows_processed = 0

    for show in data:
        sources = show.get('sources', [])
        for source in sources:
            shnid = source.get('id')
            
            if shnid in corrections_map:
                corrected_tracks_flat = corrections_map[shnid]
                
                # Regroup into sets
                new_sets = []
                current_set_name = None
                current_set_tracks = []
                
                for track in corrected_tracks_flat:
                    set_name = track.get('set')
                    
                    if set_name != current_set_name:
                        # New set detected
                        if current_set_name is not None:
                            new_sets.append({
                                'n': current_set_name,
                                't': current_set_tracks
                            })
                        current_set_name = set_name
                        current_set_tracks = []
                    
                    # Add track to current set (excluding 'set' field which is redundant in nested structure)
                    # We need 't' (title), 'u' (url), 'd' (duration)
                    new_track = {
                        't': track.get('title'),
                        'u': track.get('url'),
                        'd': track.get('duration')
                    }
                    current_set_tracks.append(new_track)
                
                # Append validity check for last set
                if current_set_name is not None:
                     new_sets.append({
                        'n': current_set_name,
                        't': current_set_tracks
                    })
                
                # Apply update
                source['sets'] = new_sets
                applied_count += 1
        
        shows_processed += 1

    print(f"Applied corrections to {applied_count} sources.")
    
    print(f"Saving to {OUTPUT_FILE}...")
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, separators=(',', ':')) # Optimized JSON output
    
    print("Done.")

if __name__ == '__main__':
    main()
