import json
import re
import os
import sys

# Configuration
DATA_PATH = '/home/jam/StudioProjects/gdar/assets/data/output.optimized_src.json'
OUTPUT_PATH = '/home/jam/StudioProjects/gdar/tool/set_mismatches_global.json'
CORRECTIONS_OUTPUT_PATH = '/home/jam/StudioProjects/gdar/tool/set_mismatches_corrections.json'

# Mappings based on user request
# "s3 is not in set 3" -> means if s3 is in url, set should be Set 3
# "s4 is the same as encore" -> means if s4 is in url, set should be Encore
SET_MAPPING = {
    '1': 'Set 1',
    '2': 'Set 2',
    '3': 'Set 3',
    '4': 'Set 4'
}

# Regex to find s1, s2, s3, s4 followed by 't' (e.g., s1t01, s2t05)
# Using case insensitive just in case, but usually lowercase based on examples
REGEX_SET_TRACK = re.compile(r's([1-4])t\d+', re.IGNORECASE)

def main():
    if not os.path.exists(DATA_PATH):
        print(f"Error: Data file not found at {DATA_PATH}")
        sys.exit(1)

    print(f"Loading data from {DATA_PATH}...")
    try:
        with open(DATA_PATH, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        print(f"Error loading JSON: {e}")
        sys.exit(1)

    mismatches = []
    corrections = []
    
    # Iterate through data structure
    # Assuming list of shows
    shows_count = 0
    sources_count = 0
    tracks_count = 0
    mismatch_count = 0

    encore_add_count = 0
    encore_remove_count = 0

    for show in data:
        shows_count += 1
        
        # Filter: Skip shows before 1970
        date_str = show.get('date', '1900-01-01')
        venue = show.get('venue', {}).get('name', 'Unknown') if isinstance(show.get('venue'), dict) else show.get('venue', 'Unknown')

        try:
            year = int(date_str.split('-')[0])
            if year < 1970:
                continue
        except (ValueError, IndexError):
            continue

        sources = show.get('sources', [])
        
        for source in sources:
            sources_count += 1
            shnid = source.get('id', 'unknown')
            sets = source.get('sets', [])
            
            source_has_mismatch = False
            corrected_tracks = []

            for set_obj in sets:
                set_name = set_obj.get('n', 'Unknown Set')
                tracks = set_obj.get('t', [])
                
                for track in tracks:
                    tracks_count += 1
                    track_url = track.get('u', '')
                    title = track.get('t', '')
                    duration = track.get('d', 0)
                    
                    expected_set = None
                    reason = ""

                    # Priority 1: Check for explicit Encore patterns
                    # "e_" or "E_" or "E " or "E1_", "E2_", "E3_"
                    encore_patterns = ['e_', 'E_', 'E ', 'E1_', 'E2_', 'E3_']
                    
                    # Exclude phrases that might accidentally trigger "e_" or "E_" match
                    # e.g., "Tennessee_Jed", ", Space_" (contains " e_"), "and the_"
                    exclusions = [', Space_', 'Tennessee_', 'and the_', 'The_']
                    sanitized_url = track_url
                    for exc in exclusions:
                        if exc in sanitized_url:
                            sanitized_url = sanitized_url.replace(exc, '')

                    matched_pattern = next((x for x in encore_patterns if x in sanitized_url), None)
                    
                    if matched_pattern:
                        expected_set = 'Encore'
                        reason = f"Encore keyword '{matched_pattern}' in URL"
                    
                    # Priority 2: Check for s[1-4] pattern
                    if not expected_set:
                        match = REGEX_SET_TRACK.search(track_url)
                        if match:
                            set_num = match.group(1) # '1', '2', '3', '4'
                            expected_set = SET_MAPPING.get(set_num)
                            reason = f"s{set_num} pattern in URL"

                    final_set = set_name
                    if expected_set:
                         if set_name != expected_set:
                            # User Rule: If current is Encore, skip moving it to another set
                            if set_name == 'Encore':
                                expected_set = None # Treat as no mismatch for correction purposes? 
                                # Or just keep current set_name.
                                # The original logic verified "set_name == 'Encore'" check was to 'continue', effectively skipping it.
                                pass
                            else:
                                # Found a mismatch
                                mismatch_count += 1
                                source_has_mismatch = True
                                final_set = expected_set
                                
                                # Stats
                                if expected_set == 'Encore':
                                    encore_add_count += 1
                                if set_name == 'Encore':
                                    encore_remove_count += 1
    
                                mismatches.append({
                                    "shnid": shnid,
                                    "current_set": set_name,
                                    "expected_set": expected_set,
                                    "reason": reason,
                                    "set": set_name,
                                    "title": title,
                                    "url": track_url,
                                    "duration": duration
                                })
                    
                    # Build corrected track entry
                    corrected_tracks.append({
                        "set": final_set,
                        "title": title,
                        "url": track_url,
                        "duration": duration
                    })

            if source_has_mismatch:
                corrections.append({
                    "id": shnid,
                    "date": date_str,
                    "venue": venue,
                    "tracks": corrected_tracks
                })

    print(f"Scanned {shows_count} shows, {sources_count} sources, {tracks_count} tracks.")
    print(f"Found {mismatch_count} mismatches.")
    print(f"Stats: {encore_add_count} tracks proposed to ADD to Encore.")
    print(f"Stats: {encore_remove_count} tracks proposed to REMOVE from Encore.")

    with open(OUTPUT_PATH, 'w', encoding='utf-8') as f:
        json.dump(mismatches, f, indent=4)
    
    print(f"Results saved to {OUTPUT_PATH}")

    # Save companion corrections file
    if corrections:
        with open(CORRECTIONS_OUTPUT_PATH, 'w', encoding='utf-8') as f:
            json.dump(corrections, f, indent=4)
        print(f"Companion corrections saved to {CORRECTIONS_OUTPUT_PATH}")
    else:
        print("No corrections to save.")

if __name__ == '__main__':
    main()
