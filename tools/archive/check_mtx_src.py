import json
import os

def main():
    file_path = 'assets/data/output.optimized_src.json'
    report_path = 'report_mtx.md'
    
    if not os.path.exists(file_path):
        print(f"Error: {file_path} not found.")
        return

    print(f"Loading data from {file_path}...")
    with open(file_path, 'r') as f:
        shows = json.load(f)

    total_matrix_sources = 0
    single_track_set1_sources = []
    only_set1_sources = []

    single_track_set1_diffs = []
    
    # Store shows for the separate set1 analysis file
    shows_for_set1_analysis = []

    print("Analyzing and fixing sources...")

    for show in shows:
        show_name = show.get('name', 'Unknown Show')
        show_date = show.get('date', 'Unknown Date')
        sources = show.get('sources', [])
        
        # Track matching sources within this show for the new file
        set1_analysis_sources = []
        
        for source in sources:
            # Check if source is Matrix
            src_type = source.get('src', '').lower()
            if src_type not in ['matrix', 'mtx']:
                continue

            total_matrix_sources += 1
            source_id = source.get('id', 'Unknown ID')
            tracks = source.get('tracks', [])

            # Analyze Sets
            set1_tracks = [t for t in tracks if t.get('s') == 'Set 1']
            set2_tracks = [t for t in tracks if t.get('s') == 'Set 2']
            other_tracks = [t for t in tracks if t.get('s') != 'Set 1']

            # Condition 1: Only 1 track in Set 1
            if len(set1_tracks) == 1:
                track = set1_tracks[0]
                track_name = track.get('t', 'Unknown Track')
                
                # FIX LOGIC: Move to Set 2 if Set 2 exists
                if len(set2_tracks) > 0:
                    track['s'] = 'Set 2'  # Apply fix
                    single_track_set1_diffs.append({
                        'show': show_name,
                        'date': show_date,
                        'id': source_id,
                        'track': track_name,
                        'action': 'Moved from Set 1 to Set 2'
                    })
                else:
                    # Report as issue but didn't fix
                    single_track_set1_sources.append({
                        'show': show_name,
                        'date': show_date,
                        'id': source_id,
                        'track': track_name,
                        'total_tracks': len(tracks),
                        'note': 'No Set 2 found, skipped fix'
                    })

            # Condition 2: Only Set 1 tracks (and no other sets)
            if len(set1_tracks) > 0 and len(other_tracks) == 0:
                 only_set1_sources.append({
                    'show': show_name,
                    'date': show_date,
                    'id': source_id,
                    'track_count': len(set1_tracks)
                })
                 
                 # New Sub-Condition: > 12 tracks (for separate analysis)
                 if len(tracks) > 12:
                     set1_analysis_sources.append(source)
        
        # If this show had any matching sources for the set1 analysis, add to the list
        if set1_analysis_sources:
            # Create a shallow copy of the show with ONLY the relevant sources
            show_copy = show.copy()
            show_copy['sources'] = set1_analysis_sources
            shows_for_set1_analysis.append(show_copy)

    # Save fixed main data
    output_path = 'assets/data/output.optimized_src1.json'
    print(f"Saving updated full data to {output_path}...")
    with open(output_path, 'w') as f:
        json.dump(shows, f, separators=(',', ':')) # Minified

    # Save separate Set 1 analysis data
    set1_output_path = 'assets/data/output.optimized_set1.json'
    print(f"Saving 'Only Set 1' (>12 tracks) sources to {set1_output_path}...")
    with open(set1_output_path, 'w') as f:
        json.dump(shows_for_set1_analysis, f, indent=2) # Pretty print for easier inspection/scripting

    # Generate Report
    print(f"Generating report at {report_path}...")
    with open(report_path, 'w') as f:
        f.write("# Matrix Source Analysis & Fix Report\n\n")
        f.write(f"**Total Matrix Sources Analyzed:** {total_matrix_sources}\n\n")

        # Report Fixed Items
        f.write(f"## Fixed: Solo Set 1 Track Moved to Set 2 ({len(single_track_set1_diffs)})\n")
        if single_track_set1_diffs:
            f.write("| Date | Show Name | Source ID | Track Name | Action |\n")
            f.write("|---|---|---|---|---|\n")
            for item in single_track_set1_diffs:
                f.write(f"| {item['date']} | {item['show']} | {item['id']} | {item['track']} | {item['action']} |\n")
        else:
            f.write("No sources required this fix.\n")
        f.write("\n")

        # Report Unfixed/Issues
        f.write(f"## Unfixed: Only 1 Track in Set 1 (No Set 2 present) ({len(single_track_set1_sources)})\n")
        if single_track_set1_sources:
            f.write("| Date | Show Name | Source ID | Track Name | Note |\n")
            f.write("|---|---|---|---|---|\n")
            for item in single_track_set1_sources:
                f.write(f"| {item['date']} | {item['show']} | {item['id']} | {item['track']} | {item['note']} |\n")
        else:
            f.write("No sources found matching this criterion.\n")
        f.write("\n")

        # Report 2
        f.write(f"## Sources with Only 'Set 1' Tracks ({len(only_set1_sources)})\n")
        f.write("*(These sources have no Set 2, Encore, etc. - Left Unchanged)*\n\n")
        if only_set1_sources:
             f.write("| Date | Show Name | Source ID | Track Count | Saved for Analysis? |\n")
             f.write("|---|---|---|---|---|\n")
             for item in only_set1_sources:
                 saved = "Yes" if item['track_count'] > 12 else "No"
                 f.write(f"| {item['date']} | {item['show']} | {item['id']} | {item['track_count']} | {saved} |\n")
        else:
            f.write("No sources found matching this criterion.\n")
        
        f.write(f"\n**Note:** {len(shows_for_set1_analysis)} shows containing sources with >12 'Set 1' tracks (and no other sets) were saved to `{set1_output_path}`.")

    print("Done!")

if __name__ == "__main__":
    main()
