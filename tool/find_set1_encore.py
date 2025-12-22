import json
import os

def main():
    json_path = os.path.join('assets', 'data', 'output.optimized_src.json')
    report_path = 'report_set1_enc.md'

    if not os.path.exists(json_path):
        print(f"Error: {json_path} not found.")
        return

    print(f"Reading {json_path}...")
    try:
        with open(json_path, 'r', encoding='utf-8') as f:
            shows = json.load(f)
    except Exception as e:
        print(f"Error reading JSON: {e}")
        return

    matches_encore = []
    matches_tuning = []
    matches_neither = []
    
    print(f"Analyzing {len(shows)} shows...")

    for show in shows:
        show_date = show.get('date', 'Unknown Date')
        venue = show.get('name', 'Unknown Venue')
        
        for source in show.get('sources', []):
            tracks = source.get('tracks', [])
            
            # Check for > 12 tracks
            if len(tracks) <= 12:
                continue

            # Check for only 1 set
            set_names = set()
            for t in tracks:
                s_name = t.get('s', '').strip()
                if s_name:
                    set_names.add(s_name)
            
            # If > 1 *distinct* set names found, skip.
            if len(set_names) > 1:
                continue
                
            # Check for "encore" in track title
            has_encore = False
            for t in tracks:
                title = t.get('t', '').lower()
                if 'encore' in title:
                    has_encore = True
                    break
            
            # Check for "Tuning" in middle tracks (index 3 to len-3)
            has_tuning_in_middle = False
            if len(tracks) >= 7:
                for i in range(3, len(tracks) - 3):
                    title = tracks[i].get('t', '').lower()
                    if 'tuning' in title:
                        has_tuning_in_middle = True
                        break

            match_data = {
                'date': show_date,
                'venue': venue,
                'source_id': source.get('id', 'Unknown ID'),
                'track_count': len(tracks),
                'set_names': list(set_names),
                'reasons': []
            }
            
            added_to_any = False

            if has_encore:
                match_data_copy = match_data.copy()
                match_data_copy['reasons'] = ["Encore"]
                matches_encore.append(match_data_copy)
                added_to_any = True
            
            if has_tuning_in_middle:
                match_data_copy = match_data.copy()
                match_data_copy['reasons'] = ["Tuning in Middle"]
                matches_tuning.append(match_data_copy)
                added_to_any = True
            
            if not has_encore and not has_tuning_in_middle:
                match_data['reasons'] = ["No Encore, No Tuning"]
                matches_neither.append(match_data)
                added_to_any = True


    total_count = len(matches_encore) + len(matches_tuning) + len(matches_neither)
    print(f"Found {total_count} total entries across categories.")
    print(f"  Encore: {len(matches_encore)}")
    print(f"  Tuning: {len(matches_tuning)}")
    print(f"  Neither: {len(matches_neither)}")

    # Generate JSON Output (Single File)
    json_output_path = 'set1_matches.json'
    json_matches = []
    
    print("Generating single JSON output...")
    for show in shows:
        valid_sources = []
        for source in show.get('sources', []):
            tracks = source.get('tracks', [])
            if len(tracks) <= 12: continue
            
            set_names = set()
            for t in tracks:
                s_name = t.get('s', '').strip()
                if s_name: set_names.add(s_name)
            if len(set_names) > 1: continue
            
            # If it passes the above checks, it matches the primary criteria (>12 tracks, single set)
            # We include it regardless of whether it has "encore", "tuning", or neither.
            valid_sources.append(source)
        
        if valid_sources:
             show_copy = show.copy()
             show_copy['sources'] = valid_sources
             json_matches.append(show_copy)

    with open(json_output_path, 'w', encoding='utf-8') as f:
        # Use separators to mimic "optimized" minified format (no whitespace)
        json.dump(json_matches, f, separators=(',', ':'))
    print(f"JSON matches written to {json_output_path}")

    with open(report_path, 'w', encoding='utf-8') as f:
        f.write(f"# Analysis Report: Set 1 Analysis\n")
        f.write(f"Criteria: >12 Tracks, Single Set (or no set info)\n\n")
        
        f.write(f"## 1. Matches with 'Encore' in Track Title ({len(matches_encore)})\n")
        for m in matches_encore:
             f.write(f"- **{m['date']}** - {m['venue']} (Source: {m['source_id']})\n")
             f.write(f"  - Tracks: {m['track_count']}\n")
             f.write(f"  - Sets found: {', '.join(m['set_names']) if m['set_names'] else 'None (Implicit Set 1)'}\n")

        f.write(f"\n## 2. Matches with 'Tuning' in Middle Tracks ({len(matches_tuning)})\n")
        f.write(f"*(Index 3 to Length-3)*\n")
        for m in matches_tuning:
             f.write(f"- **{m['date']}** - {m['venue']} (Source: {m['source_id']})\n")
             f.write(f"  - Tracks: {m['track_count']}\n")
             f.write(f"  - Sets found: {', '.join(m['set_names']) if m['set_names'] else 'None (Implicit Set 1)'}\n")

        f.write(f"\n## 3. Matches with NO 'Encore' and NO 'Tuning' in Middle ({len(matches_neither)})\n")
        for m in matches_neither:
             f.write(f"- **{m['date']}** - {m['venue']} (Source: {m['source_id']})\n")
             f.write(f"  - Tracks: {m['track_count']}\n")
             f.write(f"  - Sets found: {', '.join(m['set_names']) if m['set_names'] else 'None (Implicit Set 1)'}\n")

    print(f"Report written to {report_path}")

if __name__ == "__main__":
    main()
