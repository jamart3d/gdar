import json

def main():
    input_file = 'assets/data/output.optimized_src.json'
    output_file = 'venue_cleaning_report.md'
    
    try:
        with open(input_file, 'r') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"Error: {input_file} not found.")
        return

    affected_venues = []
    
    unique_venues_processed = set()

    for show in data:
        raw_venue = show.get('name', 'Unknown Venue')
        if 'v' in show:
             raw_venue = show['v']
        
        # Avoid processing the exact same string multiple times if many shows have it
        if raw_venue in unique_venues_processed:
            continue
        unique_venues_processed.add(raw_venue)

        clean_venue = raw_venue
        location = None
        
        # Logic: Split by " - " OR ","
        # We prioritize the first occurrence of either.
        
        # Find indices
        idx_dash = raw_venue.find(' - ')
        idx_comma = raw_venue.find(',')
        
        split_index = -1
        separator_len = 0
        
        if idx_dash != -1 and idx_comma != -1:
            # Both exist, take the first one
            if idx_dash < idx_comma:
                split_index = idx_dash
                separator_len = 3 # " - "
            else:
                split_index = idx_comma
                separator_len = 1 # ","
        elif idx_dash != -1:
            split_index = idx_dash
            separator_len = 3
        elif idx_comma != -1:
            split_index = idx_comma
            separator_len = 1
            
        if split_index != -1:
            clean_venue = raw_venue[:split_index].strip()
            location = raw_venue[split_index + separator_len:].strip()
            
            # Additional check: If the resulting clean venue is empty, maybe don't clean it?
            # Or if it's very short? For now, just report it.
            
            affected_venues.append({
                'original': raw_venue,
                'cleaned': clean_venue,
                'location': location
            })

    # Sort alphabetcially by original name
    affected_venues.sort(key=lambda x: x['original'])

    with open(output_file, 'w') as f:
        f.write('# Report: Venue Name Cleaning Preview\n\n')
        f.write(f'**Unique Venues Analyzed:** {len(unique_venues_processed)}\n')
        f.write(f'**Venues matching criteria:** {len(affected_venues)}\n\n')
        
        f.write('| Original Venue | New Venue Name | Extracted Location |\n')
        f.write('|---|---|---|\n')
        
        for entry in affected_venues:
            f.write(f"| {entry['original']} | **{entry['cleaned']}** | *{entry['location']}* |\n")

    print(f"Report generated: {output_file}")
    print(f"Found {len(affected_venues)} venues that would be cleaned.")

if __name__ == '__main__':
    main()
