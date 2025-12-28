
import json
import os

def analyze_sugar_magnolia_encores(input_file, report_file):
    print(f"Reading from {input_file}...")
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"Error: Input file {input_file} not found.")
        return

    matches = []

    for show in data:
        show_date = show.get('date', 'Unknown Date')
        venue = show.get('venue', 'Unknown Venue')
        
        for source in show.get('sources', []):
            source_id = source.get('id', 'Unknown ID')
            sets = source.get('sets', [])
            
            for set_obj in sets:
                set_name = set_obj.get('n', '')
                tracks = set_obj.get('t', [])
                
                # Check for Encore
                if "encore" in set_name.lower():
                    # Check for exactly 2 tracks
                    if len(tracks) == 2:
                        first_track = tracks[0]
                        first_track_title = first_track.get('t', '')
                        
                        # Check if first track is Sugar Magnolia
                        if "sugar magnolia" in first_track_title.lower():
                            second_track = tracks[1]
                            match = {
                                'date': show_date,
                                'venue': venue,
                                'id': source_id,
                                'set_name': set_name,
                                'track1': first_track_title,
                                'track2': second_track.get('t', ''),
                                'track1_url': first_track.get('u', ''),
                                'track2_url': second_track.get('u', '')
                            }
                            matches.append(match)

    # Generate Report
    print(f"Found {len(matches)} matches. Generating report to {report_file}...")
    
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write("# Sugar Magnolia Encore Report\n\n")
        f.write("Analysis of encores with exactly 2 tracks where the first track is 'Sugar Magnolia'.\n\n")
        f.write(f"- **Input File**: `{input_file}`\n")
        f.write(f"- **Total Matches**: {len(matches)}\n\n")
        f.write("---\n\n")
        
        if not matches:
            f.write("No matches found.\n")
        else:
            # Sort by date
            matches.sort(key=lambda x: (x['date'], x['id']))
            
            for m in matches:
                f.write(f"### {m['date']} - {m['venue']}\n")
                f.write(f"- **Source ID**: `{m['id']}`\n")
                f.write(f"- **Set Name**: {m['set_name']}\n")
                f.write(f"- **Tracks**:\n")
                f.write(f"    1. {m['track1']} (`{m['track1_url']}`)\n")
                f.write(f"    2. {m['track2']} (`{m['track2_url']}`)\n")
                f.write("\n")

    print("Done.")

if __name__ == "__main__":
    input_path = 'assets/data/output.optimized_src.json'
    output_report = 'sugar_magnolia_encores_report.md'
    analyze_sugar_magnolia_encores(input_path, output_report)
