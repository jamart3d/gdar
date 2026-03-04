import json
import os
import re

# Use the output from the final encoding cleanup as input
input_file = 'assets/data/output.cleaned_final.json'
# Fallback
if not os.path.exists(input_file):
    input_file = 'assets/data/output.cleaned_durations.json'

output_file = 'assets/data/output.cleaned_trailing.json'
report_file = 'trailing_duration_cleanup_report.md'

def main():
    if not os.path.exists(input_file):
        print(f"Error: {input_file} not found.")
        return

    print(f"Loading data from {input_file}...")
    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)

    fixed_tracks = []
    
    # Regex for trailing duration: 
    # Looks for whitespace(s) followed by M:SS or MM:SS at the end of the string
    regex_duration = re.compile(r'\s+\d{1,2}:\d{2}$')
    
    # Regex for leading dot+space:
    # Looks for a dot at the start followed by whitespace
    regex_leading_dot = re.compile(r'^\.\s+')
    
    # Regex for curly brace duration {M.SS} or {M:SS}
    # Matches optional whitespace, { then digits then . or : then digits then }, optional whitespace at end
    regex_curly = re.compile(r'\s*\{\d{1,2}[.:]\d{2}\}\s*$')

    # Regex for duration in parens with optional milliseconds (MM:SS.mm)
    # Matches optional whitespace, ( then digits : digits optional (. digits) then ), optional whitespace at end
    regex_parens_ms = re.compile(r'\s*\(\d{1,2}:\d{2}(?:\.\d{1,3})?\)\s*$')

    # Regex for disc prefixes (e.g., "d1-", "d2-", "d01-")
    # Matches start of string, "d", one or more digits, "-", optional whitespace
    regex_disc_prefix = re.compile(r'^d\d+-\s*')

    print("Processing tracks...")
    for show in data:
        show_date = show.get('date', 'Unknown Date')
        for source in show.get('sources', []):
            source_id = source.get('id', 'Unknown ID')
            for s in source.get('sets', []):
                for t in s.get('t', []):
                    track_name = t.get('t', '')
                    original_name = track_name
                    new_name = track_name
                    
                    # 1. Remove disc prefix (d2-)
                    if regex_disc_prefix.search(new_name):
                        new_name = regex_disc_prefix.sub('', new_name)

                    # 2. Remove trailing duration (standard)
                    if regex_duration.search(new_name):
                        new_name = regex_duration.sub('', new_name)
                    
                    # 3. Remove curly brace duration
                    if regex_curly.search(new_name):
                        new_name = regex_curly.sub('', new_name)

                    # 4. Remove parens duration (including ms)
                    if regex_parens_ms.search(new_name):
                        new_name = regex_parens_ms.sub('', new_name)

                    # 5. Remove leading dot+space
                    if regex_leading_dot.search(new_name):
                        new_name = regex_leading_dot.sub('', new_name)
                        
                    # 6. Strip trailing whitespace (covers "2 or more empty chars at end")
                    new_name = new_name.rstrip()
                    
                    if new_name != original_name:
                        t['t'] = new_name
                        
                        fixed_tracks.append({
                            'date': show_date,
                            'id': source_id,
                            'set': s.get('n', 'Unknown Set'),
                            'original': original_name,
                            'fixed': new_name
                        })

    # Save cleaned JSON
    print(f"Saving cleaned data to {output_file}...")
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, separators=(',', ':'))

    # Generate Report
    print(f"Generating report to {report_file}...")
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write("# Trailing Duration Timestamp Cleanup Report\n\n")
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
                # Escape backticks in content just in case
                orig = item['original'].replace('`', "'")
                fixed = item['fixed'].replace('`', "'")
                f.write(f"- **{item['set']}**: `{orig}` -> `{fixed}`\n")
            f.write("\n")

    print(f"Cleanup complete. Fixed {len(fixed_tracks)} tracks.")

if __name__ == '__main__':
    main()
