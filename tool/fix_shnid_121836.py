import json
import os

def fix_shnid_121836(input_file, output_file):
    print(f"Reading from {input_file}...")
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"Error: Input file {input_file} not found.")
        return

    target_id = "121836"
    target_source = None
    
    # Locate Source
    for show in data:
        for source in show.get('sources', []):
            if source.get('id') == target_id:
                target_source = source
                break
        if target_source:
            break
            
    if not target_source:
        print(f"Error: SHNID {target_id} not found.")
        return

    print(f"Found SHNID {target_id}. Processing...")

    # 1. Flatten all tracks to work with them easily
    all_tracks = []
    for set_obj in target_source.get('sets', []):
        for track in set_obj.get('t', []):
            all_tracks.append(track)
            
    # 2. Extract Titles to perform the Shift
    # We only shift titles, keeping other metadata (URLs, durations, etc.) in place on the objects
    titles = [t.get('t', '') for t in all_tracks]
    
    # Check if we have enough tracks
    if len(titles) >= 32:
        # Move Title at 31 (originally "Phil & Ned Jam...") to 20 (originally "El Paso")
        moved_title = titles.pop(31)
        titles.insert(20, moved_title)
        print("Applied Title Shift: Moved title at index 31 to index 20.")
        
        # Write titles back to the track objects
        for i, title in enumerate(titles):
            all_tracks[i]['t'] = title
    else:
        print(f"Error: Not enough tracks ({len(titles)}) to perform shift.")
        return

    # 3. Restructure Sets based on Triggers
    new_sets = []
    
    # Triggers
    # Default starts at Set 1
    current_set_name = "Set 1"
    current_set_tracks = []
    
    for track in all_tracks:
        title_lower = track.get('t', '').lower()
        
        # Check for set boundaries
        if "bertha" in title_lower:
            # Finish previous set if mostly full, or just switch?
            # Standard logic: Close current set (if not empty), start new one
            if current_set_tracks:
                new_sets.append({"n": current_set_name, "t": current_set_tracks})
            current_set_name = "Set 2"
            current_set_tracks = []
            
        elif "el paso" in title_lower:
             if current_set_tracks:
                new_sets.append({"n": current_set_name, "t": current_set_tracks})
             current_set_name = "Set 3"
             current_set_tracks = []
             
        elif "uncle john's band" in title_lower:
             if current_set_tracks:
                new_sets.append({"n": current_set_name, "t": current_set_tracks})
             current_set_name = "Encore"
             current_set_tracks = []
        
        current_set_tracks.append(track)
        
    # Append final set
    if current_set_tracks:
        new_sets.append({"n": current_set_name, "t": current_set_tracks})
        
    # 4. Update Source
    target_source['sets'] = new_sets
    
    # Save Output
    print(f"Saving modified data to {output_file}...")
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, separators=(',', ':'))
        
    print("Done. Fix applied.")

if __name__ == "__main__":
    input_path = 'assets/data/output.optimized_src_encore_fix.json'
    output_path = 'assets/data/output.optimized_src_121836_fix.json'
    
    # Fallback input for testing
    if not os.path.exists(input_path):
         print(f"Warning: {input_path} not found, trying previous version.")
         input_path = 'assets/data/output.optimized_src.json'

    fix_shnid_121836(input_path, output_path)
