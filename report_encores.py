import json
import sys
import os

def load_json(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        print(f"Error loading {filepath}: {e}")
        sys.exit(1)

def analyze_encores(input_json_path, report_output_path):
    
    print(f"Loading {input_json_path}...")
    data = load_json(input_json_path)
    
    missing_encore_count = 0
    total_sources = 0
    
    # List of tuples: (date, venue, source_id, [last_track_1, last_track_2])
    results = []
    
    for show in data:
        show_date = show.get('date', 'Unknown')
        show_venue = show.get('venue', 'Unknown')
        
        for source in show.get('sources', []):
            total_sources += 1
            sid = source.get('id', 'Unknown')
            tracks = source.get('tracks', [])
            
            if not tracks:
                continue
            
            has_encore = False
            for t in tracks:
                # Check 's' key for set name
                set_name = t.get('s', t.get('set', ''))
                if set_name and 'encore' in set_name.lower():
                    has_encore = True
                    break
            
            if not has_encore:
                # Check if the last set is "Set 2" or "Set 3"
                if not tracks: continue
                
                last_track = tracks[-1]
                last_set_name = last_track.get('s', last_track.get('set', ''))
                
                # Check if last set is Set 2 or Set 3
                # We check for "Set 2" or "Set 3" in the string
                is_target_end = False
                if last_set_name:
                    lower_set = last_set_name.lower()
                    if 'set 2' in lower_set or 'set 3' in lower_set or 'second set' in lower_set or 'third set' in lower_set:
                        is_target_end = True
                
                if is_target_end:
                    missing_encore_count += 1
                    
                    # Get last two tracks
                    last_tracks = tracks[-2:]
                    last_track_titles = [t.get('t', t.get('title', 'Unknown')) for t in last_tracks]
                    
                    results.append({
                        'date': show_date,
                        'venue': show_venue,
                        'id': sid,
                        'last_set': last_set_name,
                        'last_tracks': last_track_titles
                    })

    # Sort results by date
    results.sort(key=lambda x: x['date'])

    # Tally top tracks
    from collections import Counter
    all_last_tracks = []
    for r in results:
        all_last_tracks.extend(r['last_tracks'])
    
    track_counts = Counter(all_last_tracks)
    top_forty = track_counts.most_common(40)

    with open(report_output_path, 'w', encoding='utf-8') as f:
        f.write("# Report: Sources Missing Encore Set\n")
        f.write("*(Filtered: Last Set must be Set 2 or Set 3)*\n\n")
        f.write(f"**Input File:** `{input_json_path}`\n") # Updated var name
        f.write(f"**Total Sources Checked:** {total_sources}\n")
        f.write(f"**Sources ending in Set 2/3 without 'Encore':** {missing_encore_count}\n\n")
        
        f.write("## Top 40 Missing Encore Tracks\n")
        f.write("| Track Title | Count |\n")
        f.write("| :--- | :--- |\n")
        for title, count in top_forty:
            f.write(f"| {title} | {count} |\n")
        f.write("\n")
        
        f.write("## Details (Last 2 Tracks)\n\n")
        f.write("| Date | Venue | Source ID | Last Set | Last 2 Tracks |\n")
        f.write("| :--- | :--- | :--- | :--- | :--- |\n")
        
        for r in results:
            tracks_str = ", ".join([f"`{t}`" for t in r['last_tracks']])
            f.write(f"| {r['date']} | {r['venue']} | {r['id']} | {r['last_set']} | {tracks_str} |\n")
            
    print(f"Report written to {report_output_path}")

if __name__ == "__main__":
    base_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Default path
    input_json = os.path.join(base_dir, 'assets/data/output.optimized.json')
    
    # Override if argument provided
    if len(sys.argv) > 1:
        input_json = sys.argv[1]

    # Adjust output filename based on input filename
    input_basename = os.path.basename(input_json)
    report_filename = f"report_missing_encores_{input_basename}.md"
    # Or just keep it simple if user didn't specify output
    report_file = os.path.join(base_dir, 'report_missing_encores.md')
    
    analyze_encores(input_json, report_file)
