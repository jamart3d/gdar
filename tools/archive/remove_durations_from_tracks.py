import json
import os
import re

# Use the output from the previous step as input
input_file = 'assets/data/output.cleaned_encoding.json'
# Fallback
if not os.path.exists(input_file):
    input_file = 'assets/data/output.optimize_src.json'

output_file = 'assets/data/output.cleaned_durations.json'
report_file = 'duration_cleanup_report.md'

# Regex to match [MM:SS], (MM:SS), [M:SS], (M:SS)
# Allows for optional spaces inside brackets/parens
duration_pattern = re.compile(r'\s*([\[\(]\s*\d{1,2}:\d{2}\s*[\]\)])\s*')

def main():
    if not os.path.exists(input_file):
        print(f"Error: {input_file} not found.")
        return

    print(f"Loading data from {input_file}...")
    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)

    fixed_tracks = []
    
    print("Processing tracks...")
    for show in data:
        show_date = show.get('date', 'Unknown Date')
        for source in show.get('sources', []):
            source_id = source.get('id', 'Unknown ID')
            for s in source.get('sets', []):
                for t in s.get('t', []):
                    track_name = t.get('t', '')
                    
                    # Search for the pattern
                    match = duration_pattern.search(track_name)
                    if match:
                        original_name = track_name
                        # Remove the matched pattern and strip extra whitespace
                        new_name = duration_pattern.sub('', track_name).strip()
                        
                        # Double check we didn't empty the name completely (unlikely but possible if name was ONLY the duration)
                        if not new_name:
                             new_name = original_name # Revert if empty? Or keep matched? Assuming we want to keep it empty if it was just a timestamp.
                        
                        t['t'] = new_name
                        
                        fixed_tracks.append({
                            'date': show_date,
                            'id': source_id,
                            'set': s.get('n', 'Unknown Set'),
                            'original': original_name,
                            'fixed': new_name,
                            'removed': match.group(1) # The timestamp part
                        })

    # Save cleaned JSON
    print(f"Saving cleaned data to {output_file}...")
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, separators=(',', ':'))

    # Generate Report
    print(f"Generating report to {report_file}...")
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write("# Duration Timestamp Cleanup Report\n\n")
        f.write(f"Total tracks fixed: **{len(fixed_tracks)}**\n\n")
        
        f.write("## Cleanup Details\n")
        
        # Group by Date and Source ID
        grouped = {}
        for item in fixed_tracks:
            key = (item['date'], item['id'])
            if key not in grouped:
                grouped[key] = []
            grouped[key].append(item)
            
        # Sort by date
        sorted_keys = sorted(grouped.keys())
        
        for date, source_id in sorted_keys:
            f.write(f"### {date} (Source ID: {source_id})\n")
            
            items = grouped[(date, source_id)]
            for item in items:
                # Format: - **Set Name**: `Original` -> `Fixed`
                # Escape backticks in content just in case, though unlikely in filenames
                orig = item['original'].replace('`', "'")
                fixed = item['fixed'].replace('`', "'")
                f.write(f"- **{item['set']}**: `{orig}` -> `{fixed}`\n")
            f.write("\n")

    print(f"Cleanup complete. Fixed {len(fixed_tracks)} tracks.")

if __name__ == '__main__':
    main()
