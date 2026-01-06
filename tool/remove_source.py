import json
import os

def remove_source(target_id, output_file):
    input_file = 'assets/data/output.optimized_src.json'
    if not os.path.exists(input_file):
        print(f"Error: {input_file} not found.")
        return

    with open(input_file, 'r') as f:
        data = json.load(f)

    removed_count = 0
    shows_removed = 0
    
    cleaned_data = []

    for show in data:
        original_sources = show.get('sources', [])
        new_sources = [s for s in original_sources if s.get('id') != target_id]
        
        if len(new_sources) < len(original_sources):
            removed_count += (len(original_sources) - len(new_sources))
            print(f"Removed source {target_id} from show on {show.get('date')}")
        
        if new_sources:
            show['sources'] = new_sources
            cleaned_data.append(show)
        else:
            print(f"Show on {show.get('date')} has no sources left and will be removed.")
            shows_removed += 1

    if removed_count > 0:
        with open(output_file, 'w') as f:
            json.dump(cleaned_data, f, separators=(',', ':')) # Minified to keep similar format? Or indent? 
            # The original file name "optimized" suggests minified. 
            # I will use separators=(',', ':') to minify. 
        print(f"Successfully removed {removed_count} instance(s) of source {target_id}.")
        print(f"Saved cleaned data to {output_file}")
    else:
        print(f"Source {target_id} not found in data.")

if __name__ == "__main__":
    remove_source('166928', 'assets/data/output.optimized_src_cleaned.json')
