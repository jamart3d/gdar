import json
import os

INPUT_FILE = r'c:\Users\jeff\StudioProjects\gdar\assets\data\output.optimized_src.json'
OUTPUT_FILE = r'c:\Users\jeff\StudioProjects\gdar\assets\data\output.optimized_src_empty1clean.json'

def remove_empty_sources():
    print(f"Loading {INPUT_FILE}...")
    try:
        with open(INPUT_FILE, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        print(f"Error loading JSON: {e}")
        return

    total_shows = len(data)
    total_sources_before = 0
    total_sources_after = 0
    removed_sources_count = 0
    
    print(f"Processing {total_shows} shows...")

    for show in data:
        if 'sources' not in show:
            continue
            
        original_sources = show['sources']
        total_sources_before += len(original_sources)
        
        valid_sources = []
        for source in original_sources:
            # Criteria for empty source: missing 'sets' key or empty 'sets' list
            if 'sets' in source and source['sets'] and len(source['sets']) > 0:
                 valid_sources.append(source)
            else:
                sid = source.get('id', 'UNKNOWN')
                print(f"Removing empty source {sid} from show {show.get('date', 'UNKNOWN')}")
                removed_sources_count += 1
        
        show['sources'] = valid_sources
        total_sources_after += len(valid_sources)

    print("-" * 30)
    print(f"Total Sources Before: {total_sources_before}")
    print(f"Total Sources After:  {total_sources_after}")
    print(f"Removed Sources:      {removed_sources_count}")
    print("-" * 30)

    try:
        with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
            json.dump(data, f, separators=(',', ':')) # Minified output similar to input style often used here
        print(f"Cleaned data saved to {OUTPUT_FILE}")
    except Exception as e:
        print(f"Error saving JSON: {e}")

if __name__ == '__main__':
    remove_empty_sources()
