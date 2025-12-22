import json

def main():
    input_file = 'assets/data/output.optimized_src_strict.json'
    output_file = 'assets/data/output.optimized_final.json'
    report_file = 'venue_location_report.md'
    
    try:
        with open(input_file, 'r') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"Error: {input_file} not found.")
        return

    updated_count = 0
    total_shows = len(data)
    
    report_entries = []

    print(f"Processing {total_shows} shows for location extraction...")

    for show in data:
        raw_venue = show.get('name', 'Unknown Venue')
        # We process 'name' as that is what holds the venue now (after prefix cleaning)
        # Note: The 'v' attribute might still exist and be stale, but we should probably sync them or just update 'name' and 'v'?
        # The prompt implies we are working on the 'name', effectively.
        # But wait, earlier we decided to use 'name' as the primary venue source in Show.dart.
        
        # Strip date from venue first, before splitting location
        date_str = show.get('date', '')
        if date_str and date_str in raw_venue:
            # Remove date and any " on " prefixing it
            # Simple replace first
            clean_raw = raw_venue.replace(date_str, '').strip()
            
            # Remove trailing " on" or " on " or ","
            if clean_raw.lower().endswith(" on"):
                 clean_raw = clean_raw[:-3].strip()
            elif clean_raw.endswith(","):
                 clean_raw = clean_raw[:-1].strip()
            
            # Update raw_venue for subsequent splitting
            raw_venue = clean_raw
            # We don't update show['name'] yet, we do it after split check logic below
            # to keep logic consistent.

        # Logic: Split by " - " OR ","
        idx_dash = raw_venue.find(' - ')
        idx_comma = raw_venue.find(',')
        
        split_index = -1
        separator_len = 0
        
        if idx_dash != -1 and idx_comma != -1:
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
            
            if clean_venue and location:
                show['name'] = clean_venue
                show['l'] = location # 'l' for location (optimized)
                
                if 'v' in show:
                     show['v'] = clean_venue
                
                updated_count += 1
                report_entries.append({
                    'original': show.get('name', ''), # Original name from file
                    'venue': clean_venue,
                    'location': location
                })
        else:
            # If no split happened, but we DID remove the date, we should still update the name!
            # e.g. "Venue on Date" with no location.
            if raw_venue != show.get('name', ''):
                 show['name'] = raw_venue
                 if 'v' in show:
                     show['v'] = raw_venue
                 updated_count += 1
                 # Add to report as "Date Cleaned Only" (no location extracted)
                 report_entries.append({
                    'original': show.get('name') + " (Date Cleaned)",
                    'venue': raw_venue,
                    'location': '[None]'
                 })

    # Save the cleaned data
    with open(output_file, 'w') as f:
        json.dump(data, f, separators=(',', ':'))

    # Generate Report
    report_entries.sort(key=lambda x: x['original'])
    with open(report_file, 'w') as f:
        f.write('# Report: Venue Location Extraction\n\n')
        f.write(f'**Total Shows:** {total_shows}\n')
        f.write(f'**Updated Shows:** {updated_count}\n\n')
        f.write('| Original Name | Extracted Venue | Extracted Location |\n')
        f.write('|---|---|---|\n')
        for entry in report_entries:
             f.write(f"| {entry['original']} | **{entry['venue']}** | *{entry['location']}* |\n")

    print(f"Done. Updated {updated_count} shows.")
    print(f"Saved to {output_file}")
    print(f"Report saved to {report_file}")

if __name__ == '__main__':
    main()
