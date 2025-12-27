import json
import os

input_file = 'assets/data/output.optimized_src.json'
output_file = 'assets/data/output.cleaned_underscores.json'
report_file = 'track_cleanup_report.md'

def main():
    if not os.path.exists(input_file):
        print(f"Error: {input_file} not found.")
        return

    print("Loading data...")
    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)

    removed_tracks = []
    
    print("Processing tracks...")
    for show in data:
        show_date = show.get('date', 'Unknown Date')
        for source in show.get('sources', []):
            source_id = source.get('id', 'Unknown ID')
            for s in source.get('sets', []):
                original_tracks = s.get('t', [])
                kept_tracks = []
                for t in original_tracks:
                    track_name = t.get('t', '')
                    if track_name.count('_') > 3:
                        removed_tracks.append({
                            'date': show_date,
                            'id': source_id,
                            'set': s.get('n', 'Unknown Set'),
                            'track': track_name
                        })
                    else:
                        kept_tracks.append(t)
                s['t'] = kept_tracks

    # Save cleaned JSON
    print(f"Saving cleaned data to {output_file}...")
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, separators=(',', ':'))

    # Generate Report
    print(f"Generating report to {report_file}...")
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write("# Track Cleanup Report\n\n")
        f.write(f"Total tracks removed: **{len(removed_tracks)}**\n\n")
        
        f.write("## Removed Tracks (> 3 underscores)\n")
        f.write("| Date | Source ID | Set | Track Name |\n")
        f.write("|---|---|---|---|\n")
        for item in removed_tracks:
            f.write(f"| {item['date']} | {item['id']} | {item['set']} | {item['track']} |\n")

    print(f"Cleanup complete. Removed {len(removed_tracks)} tracks.")

if __name__ == '__main__':
    main()
