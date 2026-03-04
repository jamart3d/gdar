import json
import re
import os

INPUT_FILE = 'tool/set_structure_corrections.json'
OUTPUT_PLAN_FILE = 'tool/pending_set_fixes.json'

def main():
    if not os.path.exists(INPUT_FILE):
        print(f"Error: {INPUT_FILE} not found.")
        return

    with open(INPUT_FILE, 'r') as f:
        data = json.load(f)

    changes = []
    
    print(f"Scanning {INPUT_FILE} for set mismatches...")
    
    for show in data:
        show_id = show.get('id', 'unknown')
        date = show.get('date', 'unknown')
        tracks = show.get('tracks', [])
        
        for i, track in enumerate(tracks):
            url = track.get('url', '')
            current_set = track.get('set', '')
            title = track.get('title', '')
            
            # Pattern matching for URL s-tag: gdYY-MM-DDsXtYY.mp3
            s_match = re.search(r's(\d+)t', url)
            if s_match:
                s_num = int(s_match.group(1))
                
                expected_set = current_set
                
                if s_num == 1:
                    expected_set = "Set 1"
                elif s_num == 2:
                    expected_set = "Set 2"
                elif s_num == 3:
                    expected_set = "Set 3"
                elif s_num >= 4:
                    expected_set = "Encore"
                
                if expected_set != current_set:
                    # Record the change
                    changes.append({
                        "show_id": show_id,
                        "track_index": i,
                        "url": url,
                        "current_set": current_set,
                        "new_set": expected_set,
                        "reason": f"Filename tag s{s_num} implies {expected_set}"
                    })

    # Write the plan
    with open(OUTPUT_PLAN_FILE, 'w') as f:
        json.dump(changes, f, indent=4)
        
    print(f"Scan complete. Found {len(changes)} pending fixes.")
    print(f"Plan written to {OUTPUT_PLAN_FILE}")

if __name__ == "__main__":
    main()
