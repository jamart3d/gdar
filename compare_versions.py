import json
import os
import re

FILE1 = 'assets/data/output.optimized_src.json'
FILE2 = 'assets/data/output.optimized_src3.json'
REPORT_FILE = 'comparison_report_src_vs_src3.txt'
ENCORE_REPORT_FILE = 'encores.md'

def load_json(filepath):
    print(f"Loading {filepath}...")
    with open(filepath, 'r', encoding='utf-8') as f:
        return json.load(f)

def get_track_map(show):
    track_map = {}
    for source in show.get('sources', []):
        source_id = source.get('id')
        # Handle cases where source might not have an id or tracks
        if not source_id: continue
        
        for track in source.get('tracks', []):
            # Key by source_id + track filename (u) to match tracks
            key = f"{source_id}_{track.get('u')}"
            track_map[key] = track
    return track_map

def extract_venue(show_name):
    # Format: Grateful Dead Live at [Venue] on [Date]
    match = re.search(r'Grateful Dead Live at (.+?) on \d{4}-\d{2}-\d{2}', show_name)
    if match:
        return match.group(1)
    return "Unknown Venue"

def compare_files():
    data1 = load_json(FILE1)
    data2 = load_json(FILE2)

    # Create a map of shows by date for faster lookup
    shows1_map = {show['date']: show for show in data1 if 'date' in show}
    shows2_map = {show['date']: show for show in data2 if 'date' in show}

    changed_shows_count = 0
    total_tracks_updated = 0
    
    report_lines = []
    report_lines.append(f"Comparison Report: {FILE1} vs {FILE2}\n")
    report_lines.append("="*80 + "\n")

    # Iterate through shows in the NEW file (assuming we care about updates in the new one)
    
    all_dates = sorted(list(set(shows1_map.keys()) | set(shows2_map.keys())))

    for date in all_dates:
        show1 = shows1_map.get(date)
        show2 = shows2_map.get(date)

        if not show1 or not show2:
            continue # Skip if show not in both (or added/deleted) for now

        # Compare tracks
        tracks1 = get_track_map(show1)
        tracks2 = get_track_map(show2)
        
        show_has_changes = False
        show_changes = []

        for key, track2 in tracks2.items():
            track1 = tracks1.get(key)
            if track1:
                set1 = track1.get('s')
                set2 = track2.get('s')
                
                if set1 != set2:
                    show_has_changes = True
                    total_tracks_updated += 1
                    # Try to get source ID from key
                    src_id = key.split('_')[0]
                    track_name = track2.get('t', 'Unknown Track')
                    show_changes.append(f"    Source {src_id}: Track '{track_name}' ({track2.get('u')}) set changed: '{set1}' -> '{set2}'")
        
        if show_has_changes:
            changed_shows_count += 1
            venue = show2.get('venue')
            if not venue:
                venue = extract_venue(show2.get('name', ''))
            
            report_lines.append(f"SHOW: {date} @ {venue}")
            report_lines.extend(show_changes)
            report_lines.append("-" * 40 + "\n")

    summary = (
        f"SUMMARY:\n"
        f"Total Shows Processed: {len(all_dates)}\n"
        f"Total Shows Changed: {changed_shows_count}\n"
        f"Total Tracks Updated: {total_tracks_updated}\n"
    )
    
    # Prepend summary
    report_lines.insert(2, summary + "\n")
    
    # Encore Analysis
    report_lines.append("\n" + "="*80)
    report_lines.append("ENCORE ANALYSIS")
    report_lines.append("="*80 + "\n")
    
    shows_with_multiple_encores = 0
    sources_with_multi_track_encore = 0
    multi_track_encore_details = []

    for show in data2:
        encore_set_names = set()
        for source in show.get('sources', []):
            encore_track_count = 0
            encore_tracks_info = []

            for track in source.get('tracks', []):
                set_name = track.get('s', '')
                if 'encore' in set_name.lower():
                    encore_set_names.add(set_name)
                    encore_track_count += 1
                    encore_tracks_info.append(track.get('t', 'Unknown'))
            
            if encore_track_count > 1:
                sources_with_multi_track_encore += 1
                
                venue = show.get('venue')
                if not venue:
                    venue = extract_venue(show.get('name', ''))

                multi_track_encore_details.append({
                    'date': show.get('date'),
                    'venue': venue,
                    'shnid': source.get('id'),
                    'count': encore_track_count,
                    'tracks': encore_tracks_info
                })

        if len(encore_set_names) > 1:
            shows_with_multiple_encores += 1
            report_lines.append(f"  Show {show.get('date')} has multiple encore sets: {encore_set_names}")

    report_lines.append(f"Shows with more than 1 distinct 'Encore' set: {shows_with_multiple_encores}")
    report_lines.append(f"Sources/SHNIDs with more than 1 track in 'Encore' set: {sources_with_multi_track_encore}")

    print(f"Writing report to {REPORT_FILE}...")
    with open(REPORT_FILE, 'w', encoding='utf-8') as f:
        f.writelines([line + '\n' for line in report_lines])
        
    # Generate dedicated Encore report
    print(f"Writing encore report to {ENCORE_REPORT_FILE}...")
    with open(ENCORE_REPORT_FILE, 'w', encoding='utf-8') as f:
        f.write("# Sources with Multiple Encore Tracks\n\n")
        f.write(f"**Total Sources:** {sources_with_multi_track_encore}\n\n")
        f.write("| Date | Venue | SHNID | Track Count | Encore Tracks |\n")
        f.write("|---|---|---|---|---|\n")
        for item in multi_track_encore_details:
            tracks_str = ", ".join(item['tracks'])
            # Escape pipes in venue or tracks
            venue_safe = item['venue'].replace('|', '-')
            tracks_safe = tracks_str.replace('|', '-')
            f.write(f"| {item['date']} | {venue_safe} | {item['shnid']} | {item['count']} | {tracks_safe} |\n")

    print("Done.")

if __name__ == '__main__':
    compare_files()
