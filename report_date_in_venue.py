import json

def main():
    # checking the latest cleaned version to see what persists
    input_file = 'assets/data/output.optimized_src_cleaned_2.json' 
    output_file = 'report_date_in_venue.md'
    
    try:
        with open(input_file, 'r') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"Error: {input_file} not found.")
        print("Please ensure clean_venue_locations.py has been run.")
        return

    redundant_date_shows = []
    
    # New counters
    total_shows_with_date = 0
    total_sources_with_date_context = 0

    for show in data:
        name = show.get('name', '')
        date = show.get('date', '')
        sources = show.get('sources', [])
        
        if date:
            total_shows_with_date += 1
            total_sources_with_date_context += len(sources)
        
        if not date or not name:
            continue
            
        # Check if date is in name
        if date in name:
            redundant_date_shows.append({
                'name': name,
                'date': date,
                'id': show.get('id', 'Unknown') 
            })

    with open(output_file, 'w') as f:
        f.write('# Report: Date Redundancy & Validity\n\n')
        f.write(f'**Input File:** `{input_file}`\n')
        f.write(f'**Total Shows in File:** {len(data)}\n')
        f.write(f'**Total Shows with Valid Date Attribute:** {total_shows_with_date}\n')
        f.write(f'**Total Sources associated with Valid Dates:** {total_sources_with_date_context}\n\n')
        
        f.write(f'**Shows with Date in Venue Name:** {len(redundant_date_shows)}\n\n')
        
        f.write('| Current Name (Venue) | Date Attribute |\n')
        f.write('|---|---|\n')
        
        for entry in redundant_date_shows:
            f.write(f"| {entry['name']} | {entry['date']} |\n")

    print(f"Report generated: {output_file}")
    print(f"Found {len(redundant_date_shows)} shows with date in venue name.")

if __name__ == '__main__':
    main()
