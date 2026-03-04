import json
import os
import shutil

def optimize_source(source):
    tracks = source.get('tracks', [])
    if not tracks:
        return source, []

    report_lines = []

    # 1. Source-Level Optimization
    # Find keys common to ALL tracks with identical values
    if tracks:
        first_track = tracks[0]
        common_keys = set(first_track.keys())
        # 'n' (number), 't' (title), 'd' (duration), 's' (set) vary by definition, exclude them from global hoist
        # except maybe 's' if only 1 set? But we want 'sets' structure.
        excluded_global = {'n', 't', 'd', 's', 'u'} 
        
        # User requested looking for 'src'. 
        # Actually, let's be aggressive. If ANY key is constant, we can hoist.
        # But 'u' (url) is likely unique. 'n' is unique.
        
        candidates = common_keys - {'n', 't', 'd', 'u', 's'}
        
        for key in list(candidates):
            val = first_track[key]
            is_constant = True
            for t in tracks[1:]:
                if key not in t or t[key] != val:
                    is_constant = False
                    break
            
            if is_constant:
                # Hoist to source
                # If source already has this key, ensure it matches or we are overwriting/redundant
                if key in source and source[key] != val:
                    # Conflict: Source says X, Tracks say Y. Tracks win usually, but hoisting implies Source=Y.
                    # We will update Source to Y.
                    pass
                
                source[key] = val
                for t in tracks:
                    del t[key]
                report_lines.append(f"Hoisted constant '{key}'='{val}' to Source")

    # 2. Set Grouping
    new_sets = []
    current_set = None
    current_tracks = []

    for track in tracks:
        set_name = track.pop('s', 'Unknown Set')
        if set_name != current_set:
            if current_tracks:
                new_sets.append({
                    "n": current_set,
                    "t": current_tracks
                })
            current_set = set_name
            current_tracks = [track]
        else:
            current_tracks.append(track)

    if current_tracks:
        new_sets.append({
            "n": current_set,
            "t": current_tracks
        })

    # 3. Set-Level Optimization
    # For each set, find common keys in its tracks
    for set_obj in new_sets:
        s_tracks = set_obj['t']
        if not s_tracks:
            continue
            
        first = s_tracks[0]
        # Exclude standard track variance
        candidates = set(first.keys()) - {'n', 't', 'd', 'u'}
        
        for key in list(candidates):
            val = first[key]
            is_constant = True
            for t in s_tracks[1:]:
                if key not in t or t[key] != val:
                    is_constant = False
                    break
            
            if is_constant:
                # Hoist to set object
                set_obj[key] = val
                for t in s_tracks:
                    del t[key]
                report_lines.append(f"Hoisted constant '{key}'='{val}' to Set '{set_obj['n']}'")
        
        count = len(s_tracks)
        report_lines.append(f"{set_obj['n']} ({count} tracks)")
        for t in s_tracks:
            # t['n'] is track number, t['t'] is title
            # Safely get values just in case
            tn = t.get('n', '?')
            tt = t.get('t', 'Unknown Title')
            report_lines.append(f"    {tn}. {tt}")

    # Remove the old 'tracks' list and add 'sets'
    del source['tracks']
    source['sets'] = new_sets
    return source, report_lines

def main():
    input_file = 'assets/data/output.optimized_oldder_src_cleaned_dupfixed.json'
    output_file = 'assets/data/output.optimized_oldder_src_cleaned_dupfixed_set_opt.json'
    backup_file = 'assets/data/output.optimized_oldder_src_cleaned_dupfixed.json.pre_sets.bak'
    report_file = 'set_opt_report.md'

    if not os.path.exists(input_file):
        print(f"Error: {input_file} not found.")
        return

    # Create backup
    shutil.copy2(input_file, backup_file)
    print(f"Backup created at {backup_file}")

    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)

    print(f"Optimizing {len(data)} shows...")

    report_data = []
    total_sources = 0
    total_sets = 0
    total_hoists = 0

    total_show_attr_removed = 0

    for show in data:
        # User feedback: "1 src is per shnid , not for shows"
        if 'src' in show:
            del show['src']
            total_show_attr_removed += 1

        date = show.get('date', 'Unknown Date')
        venue = show.get('venue', 'Unknown Venue')
        
        show_info = {
            'date': date,
            'venue': venue,
            'sources': []
        }
        
        has_changes = False
        
        for source in show.get('sources', []):
            shnid = source.get('id', 'Unknown')
            optimized_source, structure = optimize_source(source)
            
            if structure:
                total_sources += 1
                sets_count = sum(1 for s in structure if not s.startswith("Hoisted"))
                hoists_count = len(structure) - sets_count
                total_sets += sets_count
                total_hoists += hoists_count
                
                has_changes = True
                show_info['sources'].append({
                    'shnid': shnid,
                    'structure': structure
                })
        
        if has_changes:
            report_data.append(show_info)

    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, separators=(',', ':'))

    original_size = os.path.getsize(backup_file)
    new_size = os.path.getsize(output_file)
    reduction_bytes = original_size - new_size
    reduction_percent = (reduction_bytes / original_size * 100) if original_size > 0 else 0

    print(f"Generating report {report_file}...")
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write("# Set Structure Optimization Report\n\n")
        f.write("## Summary\n")
        f.write(f"- **Shows Processed:** {len(data)}\n")
        f.write(f"- **Sources Optimized:** {total_sources}\n")
        f.write(f"- **Total Sets Created:** {total_sets}\n")
        f.write(f"- **Total Attributes Hoisted:** {total_hoists}\n")
        f.write(f"- **Show Attributes Removed ('src'):** {total_show_attr_removed}\n")
        f.write(f"- **Original File Size:** {original_size:,} bytes\n")
        f.write(f"- **New File Size:** {new_size:,} bytes\n")
        f.write(f"- **Reduction:** {reduction_bytes:,} bytes ({reduction_percent:.2f}%)\n\n")
        
        f.write("## Detailed Changes\n\n")
        for show in report_data:
            f.write(f"### {show['date']} - {show['venue']}\n")
            for src in show['sources']:
                f.write(f"- **SHNID {src['shnid']}**:\n")
                for s in src['structure']:
                    f.write(f"  - {s}\n")
            f.write("\n")

    print(f"Done.")
    print(f"Reduction: {reduction_percent:.2f}%")

if __name__ == '__main__':
    main()
