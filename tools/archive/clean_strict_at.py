import json
import re

def main():
    input_file = 'assets/data/output.optimized_src.json'
    output_file = 'assets/data/output.optimized_src_strict.json'
    
    try:
        with open(input_file, 'r') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"Error: {input_file} not found.")
        return

    updated_count = 0
    total_shows = len(data)
    
    print(f"Processing {total_shows} shows...")
    
    # Regex look for " at " surrounded by spaces, case insensitive
    # We want to keep everything AFTER the FIRST occurrence of " at ".
    # Example: "Live at Fillmore East (Early Show)" -> "Fillmore East (Early Show)"
    
    for show in data:
        original_name = show.get('name', '')
        
        # re.split with maxsplit=1 finds the first occurrence
        parts = re.split(r'\s+at\s+', original_name, maxsplit=1, flags=re.IGNORECASE)
        
        if len(parts) > 1:
            # New name is the second part (everything after the first " at ")
            new_name = parts[1].strip()
            
            if new_name and new_name != original_name:
                show['name'] = new_name
                updated_count += 1

    # Save the cleaned data to a new file first for verification
    with open(output_file, 'w') as f:
        json.dump(data, f, separators=(',', ':'))

    print(f"Done. Updated {updated_count} shows.")
    print(f"Saved to {output_file}")

if __name__ == '__main__':
    main()
