import json
import os

INPUT_DATA_FILE = 'tool/set_structure_corrections.json'
INPUT_PLAN_FILE = 'tool/pending_set_fixes.json'
OUTPUT_DATA_FILE = 'tool/set_structure_corrections_fixed.json'

def main():
    if not os.path.exists(INPUT_DATA_FILE):
        print(f"Error: {INPUT_DATA_FILE} not found.")
        return
    if not os.path.exists(INPUT_PLAN_FILE):
        print(f"Error: {INPUT_PLAN_FILE} not found.")
        return

    with open(INPUT_DATA_FILE, 'r') as f:
        data = json.load(f)
        
    with open(INPUT_PLAN_FILE, 'r') as f:
        plan = json.load(f)
        
    if not plan:
        print("Plan is empty. No changes to apply.")
        return

    print(f"Applying {len(plan)} fixes from {INPUT_PLAN_FILE}...")
    
    # Organize plan for efficient lookup: show_id -> url -> new_set
    # A bit complex if duplicate URLs exist, but setlist URLs should be unique per show.
    # Actually, simpler to just iterate data again or use the index if we stored it?
    # I stored track_index. That's safest.
    
    # Create a lookup map: show_id -> { track_index: new_set }
    fix_map = {}
    for item in plan:
        sid = item['show_id']
        idx = item['track_index']
        new_s = item['new_set']
        
        if sid not in fix_map:
            fix_map[sid] = {}
        fix_map[sid][idx] = new_s
        
    applied_count = 0
    
    for show in data:
        sid = show.get('id')
        if sid in fix_map:
            tracks = show.get('tracks', [])
            for idx, new_set in fix_map[sid].items():
                if 0 <= idx < len(tracks):
                    # verify url matches just in case
                    # (Skipping deep URL check for brevity, trusting index from scan)
                    show['tracks'][idx]['set'] = new_set
                    applied_count += 1
                else:
                    print(f"Warning: Track index {idx} out of range for show {sid}")
                    
    print(f"Successfully applied {applied_count} fixes.")
    
    # Save to new file
    with open(OUTPUT_DATA_FILE, 'w') as f:
        json.dump(data, f, indent=4)
    
    print(f"Updated data saved to {OUTPUT_DATA_FILE}")

if __name__ == "__main__":
    main()
