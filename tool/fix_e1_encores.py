import json
import os
import re

def fix_e1_encores(input_path, output_path, report_path):
    print(f"Loading {input_path}...")
    
    # Pattern to match E1: variations
    # Variations: "E1:", "E1 ", "E1-", "E1.", "E1 :", "E1_", "E1" at start of string
    e1_pattern = re.compile(r'^E1[:\.\-\s_]?\s*', re.IGNORECASE)
    
    try:
        with open(input_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        print(f"Error loading JSON: {e}")
        return

    stats = {
        'sources_affected': 0,
        'tracks_moved': 0,
        'tracks_cleaned': 0
    }
    
    report_lines = []
    report_lines.append("# E1: Encore Fix Report\n")
    report_lines.append(f"- **Input File**: `{input_path}`")
    report_lines.append(f"- **Output File**: `{output_path}`\n")
    
    detailed_changes = []

    for show in data:
        show_date = show.get('date', 'Unknown')
        show_name = show.get('name', 'Unknown')
        
        for source in show.get('sources', []):
            shnid = source.get('id')
            sets = source.get('sets', [])
            
            source_changed = False
            moved_in_source = []
            
            # We want to identify every E1 track and move it to an Encore set.
            # To preserve order relative to other tracks, we'll collect ALL tracks,
            # then split them into non-encore and encore.
            # However, if there are multiple sets (Set 1, Set 2), we should only move
            # E1 tracks to Encore, and leave others in their respective sets.
            
            # Step 1: Collect all tracks and their original set index
            all_tracks = []
            for s_idx, s in enumerate(sets):
                set_name = s.get('n', 'Unknown')
                for t in s.get('t', []):
                    all_tracks.append({
                        'track_obj': t,
                        'original_set_idx': s_idx,
                        'original_set_name': set_name
                    })
            
            # Step 2: Separate E1 tracks
            non_encore_tracks = []
            encore_tracks = []
            
            for item in all_tracks:
                track_name = item['track_obj'].get('t', '')
                if e1_pattern.match(track_name):
                    # It's an E1 track
                    cleaned_name = e1_pattern.sub('', track_name).strip()
                    item['track_obj']['t'] = cleaned_name
                    stats['tracks_cleaned'] += 1
                    
                    # Check if it's already in a set called "Encore"
                    if item['original_set_name'].lower() == 'encore':
                        # Already in encore, no need to move
                        non_encore_tracks.append(item)
                    else:
                        encore_tracks.append(item)
                        source_changed = True
                        moved_in_source.append(item)
                else:
                    non_encore_tracks.append(item)
            
            if source_changed:
                stats['sources_affected'] += 1
                stats['tracks_moved'] += len(encore_tracks)
                
                # Step 3: Reconstruct sets
                # Filter out E1 tracks from original sets
                for s in sets:
                    s['t'] = [t for t in s['t'] if not e1_pattern.match(t.get('t', ''))]
                
                # Remove empty sets
                new_sets = [s for s in sets if s['t']]
                
                # Ensure an Encore set exists and add the E1 tracks to it
                encore_set = next((s for s in new_sets if s.get('n', '').lower() == 'encore'), None)
                if encore_set:
                    # Append E1 tracks to existing encore
                    encore_set['t'].extend([item['track_obj'] for item in encore_tracks])
                else:
                    # Create new Encore set
                    new_sets.append({
                        'n': 'Encore',
                        't': [item['track_obj'] for item in encore_tracks]
                    })
                
                source['sets'] = new_sets
                
                detailed_changes.append(f"### {show_date} - {show_name} (SHNID: {shnid})")
                for m in moved_in_source:
                    detailed_changes.append(f"- Moved `{m['track_obj'].get('t')}` from `{m['original_set_name']}` to `Encore`")
                detailed_changes.append("")

    # Build final report
    report_stats = [
        "## Statistics\n",
        f"- **Sources Affected**: {stats['sources_affected']}",
        f"- **Tracks Moved**: {stats['tracks_moved']}",
        f"- **Tracks Cleaned (Names Stripped)**: {stats['tracks_cleaned']}\n",
        "## Detailed Changes\n"
    ]
    
    with open(report_path, 'w', encoding='utf-8') as f:
        f.write("\n".join(report_lines + report_stats + detailed_changes))
        
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, separators=(',', ':'), ensure_ascii=False)
        
    print(f"Fixed {stats['tracks_moved']} tracks in {stats['sources_affected']} sources.")
    print(f"Report saved to {report_path}")
    print(f"New JSON saved to {output_path}")

if __name__ == "__main__":
    input_file = '/home/jam/StudioProjects/gdar/assets/data/output.optimized_src.json'
    output_file = '/home/jam/StudioProjects/gdar/assets/data/output.optimized_src_fixed_e1.json'
    report_file = '/home/jam/StudioProjects/gdar/fix_e1_report.md'
    
    fix_e1_encores(input_file, output_file, report_file)
