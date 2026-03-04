import json
import os
from collections import Counter

def main():
    input_file = 'assets/data/output.optimized_src.json'
    report_file = 'venue_analysis_report.md'
    
    if not os.path.exists(input_file):
        print(f"Error: {input_file} not found.")
        return

    try:
        with open(input_file, 'r') as f:
            data = json.load(f)
    except Exception as e:
        print(f"Error loading JSON: {e}")
        return

    stadium_only_shows = []
    one_word_shows = []
    total_shows = len(data)

    print(f"Analyzing {total_shows} shows in {input_file} using cleaning logic...")

    for show in data:
        raw_venue = show.get('name', 'Unknown Venue')
        
        # 1. Strip date from venue
        date_str = show.get('date', '')
        if date_str and date_str in raw_venue:
            clean_raw = raw_venue.replace(date_str, '').strip()
            if clean_raw.lower().endswith(" on"):
                 clean_raw = clean_raw[:-3].strip()
            elif clean_raw.endswith(","):
                 clean_raw = clean_raw[:-1].strip()
            raw_venue = clean_raw

        # 2. Split by " - " OR ","
        idx_dash = raw_venue.find(' - ')
        idx_comma = raw_venue.find(',')
        
        split_index = -1
        separator_len = 0
        
        if idx_dash != -1 and idx_comma != -1:
            if idx_dash < idx_comma:
                split_index = idx_dash
                separator_len = 3
            else:
                split_index = idx_comma
                separator_len = 1
        elif idx_dash != -1:
            split_index = idx_dash
            separator_len = 3
        elif idx_comma != -1:
            split_index = idx_comma
            separator_len = 1
            
        clean_venue = raw_venue
        if split_index != -1:
            clean_venue = raw_venue[:split_index].strip()
            
        # Check if the resulting venue name IS ONLY "Stadium"
        if clean_venue == "Stadium":
            stadium_only_shows.append({
                'date': show.get('date', 'Unknown'),
                'original': show.get('name', ''),
                'cleaned': clean_venue
            })
            
        # Check if the resulting venue is exactly ONE word
        words = clean_venue.split()
        if len(words) == 1:
            one_word_shows.append({
                'date': show.get('date', 'Unknown'),
                'original': show.get('name', ''),
                'cleaned': clean_venue
            })

    # Tally results
    stadium_count = len(stadium_only_shows)
    one_word_count = len(one_word_shows)
    one_word_tally = Counter([s['cleaned'] for s in one_word_shows])
    
    # Sort one_word_shows for the report
    one_word_shows.sort(key=lambda x: (x['cleaned'].lower(), x['date']))

    # Generate Markdown Report
    with open(report_file, 'w') as f:
        f.write('# Venue Name Analysis Report\n\n')
        f.write(f'- **Total Shows Analyzed:** {total_shows}\n')
        f.write(f'- **Shows Named ONLY "Stadium":** {stadium_count}\n')
        f.write(f'- **Shows with SINGLE-WORD Names:** {one_word_count}\n\n')

        if one_word_count > 0:
            f.write('## Tally of Single-Word Venues\n\n')
            f.write('| Venue Name | Count |\n')
            f.write('| :--- | :--- |\n')
            # Sort tally by count descending, then name
            for name, count in sorted(one_word_tally.items(), key=lambda x: (-x[1], x[0].lower())):
                f.write(f'| {name} | {count} |\n')
            f.write('\n')

            f.write('## List of Single-Word Venue Shows\n\n')
            f.write('| Date | Cleaned Venue | Original Name |\n')
            f.write('| :--- | :--- | :--- |\n')
            for entry in one_word_shows:
                f.write(f"| {entry['date']} | **{entry['cleaned']}** | {entry['original']} |\n")

    print(f"\nAnalysis complete.")
    print(f"Report saved to: {report_file}")
    print(f"Total shows with single-word names: {one_word_count}")

if __name__ == '__main__':
    main()
