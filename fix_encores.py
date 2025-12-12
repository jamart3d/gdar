import json
import sys
import os

def load_json(path):
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_json(data, path):
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, separators=(',', ':'))

def main():
    input_path = 'assets/data/output.optimizedo_final.json'
    output_path = 'assets/data/output.optimizedo_final2.json'
    
    target_track_names = {
        "Playing In The Band  -",
        "Playing In The Band",
        "Not Fade Away-",
        "Not Fade Away -", 
        "Not Fade Away",
        "And We Bid You Goodnight",
        "Stella Blue",
        "Liberty-",
        "Liberty",
        "It's All Over Now, Baby Blue",
        "The Mighty Quinn (Quinn The Eskimo)",
        "Keep Your Day Job",
        "Johnny B. Goode",
        "One More Saturday Night",
        "U.S. Blue",
        "U.S. Blues",
        "Casey Jones", # Added based on common pairing
        # "Sugar Magnolia" - Removed as requested
    }

    print(f"Loading {input_path}...")
    try:
        data = load_json(input_path)
    except FileNotFoundError:
        print(f"File not found: {input_path}")
        return

    fixed_count = 0
    total_sources = 0

    shows_list = data if isinstance(data, list) else data.get('shows', [])

    for show in shows_list:
        for source in show.get('sources', []):
            total_sources += 1
            tracks = source.get('tracks', [])
            
            if not tracks:
                continue
            
            # Check if any track is ALREADY in an Encore set
            has_encore = False
            for t in tracks:
                s_val = t.get('s', t.get('set', ''))
                if s_val and 'encore' in s_val.lower():
                    has_encore = True
                    break
            
            if has_encore:
                continue

            # Check LAST few tracks (up to 3 from end)
            # This handles cases where the encore is followed by "tuning" or "crowd" or another encore
            
            # Identify candidates for checking
            candidates_indices = []
            if len(tracks) >= 1: candidates_indices.append(-1)
            if len(tracks) >= 2: candidates_indices.append(-2)
            if len(tracks) >= 3: candidates_indices.append(-3)
            
            for idx in candidates_indices:
                track = tracks[idx]
                
                # Verify it's currently in Set 2 or 3
                s_val = track.get('s', track.get('set', ''))
                if not s_val: continue
                lower_s = s_val.lower()
                if not ('set 2' in lower_s or 'set 3' in lower_s or 'second set' in lower_s or 'third set' in lower_s):
                    continue

                title = track.get('t', track.get('title', 'Unknown'))
                
                # Clean title for comparison (strip whitespace)
                clean_title = title.strip()
                
                # Check for match
                matched = False
                if clean_title in target_track_names:
                    matched = True
                
                if matched:
                    # FIX IT
                    if 's' in track:
                        track['s'] = 'Encore'
                    elif 'set' in track:
                        track['set'] = 'Encore'
                    else:
                        track['s'] = 'Encore'
                    
                    fixed_count += 1
                    # Don't break immediately, might be multiple encore tracks? 
                    # Actually if we find one, the show is 'fixed' for the report, but we might want to label all of them.
                    # Let's verify subsequent tracks?
                    # If track[-2] is fixed, track[-1] remains in Set 2? That's weird but acceptable for "detection".
                    # Better to move checking loop from end backwards.

    print(f"Total Sources Checked: {total_sources}")
    print(f"Total Tracks Moved to Encore: {fixed_count}")
    
    print(f"Saving to {output_path}...")
    save_json(data, output_path)
    print("Done.")

if __name__ == "__main__":
    main()
