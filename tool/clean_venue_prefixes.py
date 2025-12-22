import json
import re

def main():
    input_file = 'assets/data/output.optimized_src.json'
    output_file = 'assets/data/output.optimized_src_cleaned.json'
    
    try:
        with open(input_file, 'r') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"Error: {input_file} not found.")
        return

    updated_count = 0
    total_shows = len(data)

    print(f"Processing {total_shows} shows...")

    for show in data:
        original_name = show.get('name', '')
        
        # Split by " at " case-insensitive, maxsplit=1
        parts = re.split(r'\s+at\s+', original_name, maxsplit=1, flags=re.IGNORECASE)
        
        if len(parts) > 1:
            # Take the part after " at "
            new_name = parts[1].strip()
            
            # If finding " on " followed by a date-like structure at the end, we might want to trim that too?
            # The prompt strictly asked for "name being whats after at". 
            # "Grateful Dead at Winterland Arena on 1978-10-17" -> "Winterland Arena on 1978-10-17"
            # The app's Show.fromJson parser splits by " on " as well. 
            # If we only remove " at ", the " on [Date]" part might remain.
            # But the user asked strictly for "whats after at". 
            # I will stick to the user's specific request for now.
            
            if new_name != original_name:
                show['name'] = new_name
                updated_count += 1

    # Save the cleaned data
    with open(output_file, 'w') as f:
        json.dump(data, f, separators=(',', ':')) # Minified format to match "optimized" style

    print(f"Done. Updated {updated_count} shows.")
    print(f"Saved to {output_file}")

if __name__ == '__main__':
    main()
