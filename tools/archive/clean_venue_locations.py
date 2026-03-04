import json
import os

def main():
    input_file = 'assets/data/output.optimized_oldder_src_cleaned_name1chop.json'
    output_file = 'assets/data/output.optimized_oldder_src_cleaned_name2chop.json'
    report_file = 'venue_location_clean_report.md'
    
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

    # Load Original Source Data for Fallback
    src_file = 'assets/data/output.optimized_src.json'
    src_venues = {}
    if os.path.exists(src_file):
        with open(src_file, 'r', encoding='utf-8') as f:
            src_data = json.load(f)
            for show in src_data:
                d = show.get('date')
                n = show.get('name')
                if d and n:
                    src_venues[d] = n
    else:
        print(f"Warning: {src_file} not found. Fallback to original source names unavailable.")

    for show in data:
        raw_venue = show.get('name', 'Unknown Venue')
        
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
            
            # Heuristic: Avoid cleaning to ANY single word if requested
            # User request: "if result will be single word, don't clean"
            # This is a strict rule to prevent losing context.
            
            is_single_word = ' ' not in clean_venue
            has_on = " on " in clean_venue.lower()
            
            if is_single_word or has_on:
                # Reject the split!
                split_index = -1
                
                # Try fallback to Source Original if available
                if date_str in src_venues:
                    clean_venue = src_venues[date_str]
                    location = "" # No location extracted if we revert
                    # We treat this as a "fix" but not a "split"
                    # But we need to apply it below if we want to save it.
                    # Let's set split_index back to -1 to fall through to the 'else' logic?
                    # No, let's handle it here.
                    
                    show['name'] = clean_venue
                    show['l'] = "" # Clear location if we revert
                    if 'v' in show: show['v'] = clean_venue
                    
                    updated_count += 1
                    report_entries.append({
                        'original': show.get('name', ''), 
                        'venue': clean_venue + " (Reverted to Source)",
                        'location': '[Reverted]'
                    })
                    continue # Skip the standard apply block
                else:
                    # No fallback, just revert to input implicitly by doing nothing?
                    # Or explicit revert?
                    clean_venue = ""
                    location = ""
            
            if split_index != -1 and clean_venue and location:
                # Check strict single word rule again for the final candidate (redundant but safe)
                if ' ' not in clean_venue:
                     # This shouldn't be reached if logic above is correct, but for safety:
                     split_index = -1
                else:
                    show['name'] = clean_venue
                    show['l'] = location
                    
                    if 'v' in show:
                        show['v'] = clean_venue
                    
                    updated_count += 1
                    report_entries.append({
                        'original': show.get('name', ''), 
                        'venue': clean_venue,
                        'location': location
                    })

        # Check for date-only cleaned cases (no split) or fallback logic
        if split_index == -1:
            candidate_name = raw_venue
            original_input_name = show.get('name', '')
            
            # Check for bad outcome: Single Word OR " on "
            is_single_word = ' ' not in candidate_name
            has_on = " on " in candidate_name.lower()
            
            if (is_single_word or has_on) and date_str in src_venues:
                 # Fallback to Source
                 candidate_name = src_venues[date_str]
            elif (is_single_word or has_on):
                 # Revert to input if no source available (better than single word 'Gym')
                 # But input might be 'Gym'... assume input is 'Pritchard Gym'? No..
                 # If input was 'Ballroom on 1969', and we stripped it to 'Ballroom'.
                 # We revert to 'Ballroom on 1969'.
                 candidate_name = original_input_name

            # Apply if still different
            if candidate_name != original_input_name:
                 show['name'] = candidate_name
                 if 'v' in show:
                     show['v'] = candidate_name
                 updated_count += 1
                 # Add to report as "Date Cleaned Only" (no location extracted)
                 report_entries.append({
                    'original': original_input_name + " (Date Cleaned/Fallback)",
                    'venue': candidate_name,
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
