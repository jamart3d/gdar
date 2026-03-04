import json
import os

def main():
    file_original = 'assets/data/output.optimized_src.json'
    file_cleaned = 'assets/data/output.optimized_oldder_src_cleaned_name2chop.json'
    report_file = 'venue_diff_report.md'

    print(f"Loading {file_original}...")
    try:
        with open(file_original, 'r') as f:
            data_orig = json.load(f)
    except Exception as e:
        print(f"Error loading original file: {e}")
        return

    print(f"Loading {file_cleaned}...")
    try:
        with open(file_cleaned, 'r') as f:
            data_clean = json.load(f)
    except Exception as e:
        print(f"Error loading cleaned file: {e}")
        return

    print("Indexing cleaned data by date...")
    clean_by_date = {}
    for show in data_clean:
        d = show.get('date', 'Unknown')
        if d not in clean_by_date:
            clean_by_date[d] = []
        clean_by_date[d].append(show)

    diffs = []
    processed_dates = set()
    unchanged_count = 0
    
    print("Comparing venues by date...")

    for orig in data_orig:
        date = orig.get('date', 'Unknown')
        if date in processed_dates:
            continue # Handle duplicates in original only once per date group? 
                     # Or iterate strictly. Original might have dupes too.
        
        # Get all original shows for this date
        orig_shows = [s for s in data_orig if s.get('date') == date]
        processed_dates.add(date)
        
        clean_shows = clean_by_date.get(date)
        
        if not clean_shows:
            # Date not in cleaned dataset
            continue
            
        # Strategy: Align list of shows for this date.
        # Simple heuristic: align by order if counts match.
        # If counts mismatch, try to fuzzy match or just compare first to first.
        
        limit_k = min(len(orig_shows), len(clean_shows))
        
        for k in range(limit_k):
            o_show = orig_shows[k]
            c_show = clean_shows[k]
            
            n_orig = o_show.get('name', '[No Name]')
            n_clean = c_show.get('name', '[No Name]')
            l_clean = c_show.get('l', '')
            
            # Extract SHNID
            sources = o_show.get('sources', [])
            shnid = 'Unknown'
            if sources:
                shnid = sources[0].get('id', 'Unknown')
            
            has_location = bool(l_clean)
            name_changed = (n_orig != n_clean)
            
            if name_changed or has_location:
                diffs.append({
                    'date': date,
                    'shnid': shnid,
                    'original': n_orig,
                    'cleaned': n_clean,
                    'location': l_clean
                })
            else:
                unchanged_count += 1

    print(f"Found {len(diffs)} differences on matching dates.")
    print(f"Generating report {report_file}...")
    
    # Sort diffs by date
    diffs.sort(key=lambda x: x['date'])
    
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write("# Venue Name & Location Comparison Report\n\n")
        f.write(f"- **Original File**: `{file_original}`\n")
        f.write(f"- **Cleaned File**: `{file_cleaned}`\n")
        f.write(f"- **Common Dates Processed**: {len(processed_dates)}\n")
        f.write(f"- **Changed Venues**: {len(diffs)}\n\n")
        
        f.write("## Detailed Changes (Aligned by Date)\n\n")
        f.write("| Date | SHNID | Original Venue Name | Cleaned Venue Name | Extracted Location |\n")
        f.write("|---|---|---|---|---|\n")
        
        for d in diffs:
            loc_str = f"**{d['location']}**" if d['location'] else ""
            f.write(f"| {d['date']} | {d['shnid']} | {d['original']} | {d['cleaned']} | {loc_str} |\n")


    print("Done.")

if __name__ == '__main__':
    main()
