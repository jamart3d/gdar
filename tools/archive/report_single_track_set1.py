import json

def main():
    input_file = 'assets/data/output.optimized_src.json'
    output_file = 'set1_1_report.md'
    
    try:
        with open(input_file, 'r') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"Error: {input_file} not found.")
        return

    single_track_set1_sources = []

    for show in data:
        show_date = show.get('date', 'Unknown Date')
        show_venue = show.get('name', 'Unknown Venue')
        if 'v' in show:
             show_venue = show['v']
        
        for source in show.get('sources', []):
            tracks = source.get('tracks', [])
            source_id = source.get('id', 'Unknown ID')
            
            # Filter tracks that belong to "Set 1"
            set1_tracks = [t for t in tracks if t.get('s') == 'Set 1']
            
            if len(set1_tracks) == 1 and len(tracks) > 1:
                track_name = set1_tracks[0].get('t', 'Unknown Track')
                entry = {
                    'date': show_date,
                    'venue': show_venue,
                    'id': source_id,
                    'track': track_name,
                    'total_tracks': len(tracks)
                }
                single_track_set1_sources.append(entry)

    # Generate Report
    with open(output_file, 'w') as f:
        f.write('# Report: Sources with Exactly 1 Track in Set 1\n\n')
        f.write(f'**Total Sources Found:** {len(single_track_set1_sources)}\n\n')
        
        for entry in single_track_set1_sources:
            f.write(f"- **{entry['date']}** - {entry['venue']} (ID: {entry['id']})\n")
            f.write(f"  - Track: `{entry['track']}`\n")
            f.write(f"  - Total tracks in source: {entry['total_tracks']}\n\n")

if __name__ == '__main__':
    main()
