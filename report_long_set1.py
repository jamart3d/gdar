import json
import re

def main():
    try:
        with open('assets/data/output.optimized_src.json', 'r') as f:
            data = json.load(f)
    except FileNotFoundError:
        print("Error: assets/data/output.optimized_src.json not found.")
        return

    # Categories
    sources_with_encore = []
    sources_with_tuning_middle = []
    sources_others = [] # No encore, no tuning in middle

    for show in data:
        show_date = show.get('date', 'Unknown Date')
        show_venue = show.get('name', 'Unknown Venue') # 'name' usually contains venue info or is the full title.
        # If 'v' exists, use it, otherwise use 'name'
        if 'v' in show:
             show_venue = show['v']
        
        for source in show.get('sources', []):
            tracks = source.get('tracks', [])
            source_id = source.get('id', 'Unknown ID')
            
            # Explicitly skip single-track sources
            if len(tracks) <= 1:
                continue
            
            # 1. Check for exactly 1 set
            unique_sets = set()
            for t in tracks:
                s_name = t.get('s', '').strip()
                if s_name:
                    unique_sets.add(s_name)
            
            # Proceed only if exactly 1 set found (e.g. "Set 1") and > 12 tracks
            if len(unique_sets) == 1 and len(tracks) > 12:
                has_encore = False
                has_tuning_mid = False
                
                # Check for "encore" in any track title
                for t in tracks:
                    if 'encore' in t.get('t', '').lower():
                        has_encore = True
                        break
                
                # Check for "tuning" in middle (index 3 to len-3)
                # indices: 0, 1, 2 ... [3 ... len-4] ... len-3, len-2, len-1
                if len(tracks) >= 8: # Need enough tracks to have a "middle"
                    middle_slice = tracks[3:-3] 
                    for t in middle_slice:
                        if 'tuning' in t.get('t', '').lower():
                            has_tuning_mid = True
                            break
                            
                # Add to lists
                entry = {
                    'date': show_date,
                    'venue': show_venue,
                    'id': source_id,
                    'count': len(tracks),
                    'tuning_track': None
                }
                
                if has_tuning_mid:
                     # Find which track it was for reporting?
                     middle_slice = tracks[3:-3] 
                     for t in middle_slice:
                        if 'tuning' in t.get('t', '').lower():
                            entry['tuning_track'] = t.get('t')
                            break

                if has_encore:
                    sources_with_encore.append(entry)
                
                if has_tuning_mid:
                    sources_with_tuning_middle.append(entry)
                    
                if not has_encore and not has_tuning_mid:
                    sources_others.append(entry)

    # Calculate Totals
    total_found = len(sources_with_encore) + len(sources_others) # tuning overlap makes this tricky, better to just sum unique IDs if needed, but mutually exclusive buckets helps.
    # Actually, logic above adds to independent lists. "Others" is exclusive.
    # "Encore" and "Tuning" can overlap.
    
    # Generate Report
    with open('set1report.md', 'w') as f:
        f.write('# Report: Long Single-Set Sources (>12 Tracks)\n\n')
        
        f.write('## Criteria\n')
        f.write('- Exactly 1 Set detected.\n')
        f.write('- More than 12 tracks.\n\n')
        
        f.write(f'## 1. Sources with "Encore" in Title ({len(sources_with_encore)})\n')
        for entry in sources_with_encore:
            f.write(f"- {entry['date']} - {entry['venue']} (ID: {entry['id']}) [{entry['count']} tracks]\n")
            
        f.write(f'\n## 2. Sources with "Tuning" in Middle (Index 3 to -3) ({len(sources_with_tuning_middle)})\n')
        for entry in sources_with_tuning_middle:
            track_info = f" - Found: '{entry['tuning_track']}'" if entry['tuning_track'] else ""
            f.write(f"- {entry['date']} - {entry['venue']} (ID: {entry['id']}) [{entry['count']} tracks]{track_info}\n")

        f.write(f'\n## 3. Sources with NO "Encore" and NO "Tuning" in Middle ({len(sources_others)})\n')
        for entry in sources_others:
            f.write(f"- {entry['date']} - {entry['venue']} (ID: {entry['id']}) [{entry['count']} tracks]\n")

if __name__ == '__main__':
    main()
