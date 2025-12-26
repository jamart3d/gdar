import json
import os

def fix_long_encores():
    input_file = 'assets/data/output.optimized_oldder_src_cleaned_dupfixed2_set_opt.json'
    output_file = 'assets/data/output.optimized_oldder_src_cleaned_dupfixed2_set_opt_enc1.json'
    report_file = 'long_encore_fix_report.md'
    
    if not os.path.exists(input_file):
        print(f"Error: {input_file} not found.")
        return

    print(f"Loading {input_file}...")
    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)

    report_lines = []
    
    total_fixed = 0

    for show in data:
        show_date = show.get('date', 'Unknown')
        show_venue = show.get('venue', 'Unknown')
        
        for source in show.get('sources', []):
            shnid = source.get('id', 'Unknown')
            sets = source.get('sets', [])
            
            if not sets:
                continue
                
            # Iterate sets. Finding "Encore" sets.
            # We assume indices are stable during iteration if we don't insert/delete sets.
            # But here we might modify contents of Sets[i-1] and Sets[i].
            
            # Iterate sets. Finding "Encore" sets.
            # We assume indices are stable during iteration if we don't insert/delete sets.
            # But here we might modify contents of Sets[i-1] and Sets[i].
            
            for i, s in enumerate(sets):
                set_name = s.get('n', '').lower()
                tracks = s.get('t', [])
                if not tracks:
                     continue

                if "encore" in set_name:
                    
                    # New Logic: "remove the encore set from and source that has more than 20 track in encore set, move to set before"
                    if len(tracks) > 20:
                        if i > 0:
                            prev_set = sets[i-1]
                            prev_set['t'].extend(tracks)
                            s['t'] = [] # Empty it, will filter later
                            
                            total_fixed += 1
                            report_lines.append(f"## {show_date} - {show_venue} (SHNID: {shnid})")
                            report_lines.append(f"- **Merged Large Encore Set:** {s.get('n', 'Encore')} ({len(tracks)} tracks)")
                            report_lines.append(f"- **Action:** Moved ALL tracks to previous set ({prev_set.get('n', 'Previous Set')}) and removed Encore set.")
                            report_lines.append("")
                        continue    

                    # Logic: "adjust any Long Encores (>2 tracks) but no more than 5"
                    if len(tracks) > 2 and len(tracks) <= 5:
                        
                        # "containing 'Encore' in title"
                        # Find the first track with "encore" in title
                        encore_track_idx = -1
                        for idx, t in enumerate(tracks):
                            if "encore" in t.get('t', '').lower():
                                encore_track_idx = idx
                                break
                        
                        # Only proceed if found AND there are tracks BEFORE it
                        if encore_track_idx > 0:
                            # Move tracks before encore_track_idx to previous set
                            if i > 0: # Ensure there is a previous set
                                prev_set = sets[i-1]
                                
                                tracks_to_move = tracks[:encore_track_idx]
                                tracks_to_keep = tracks[encore_track_idx:]
                                
                                # Move
                                prev_set['t'].extend(tracks_to_move)
                                s['t'] = tracks_to_keep
                                
                                total_fixed += 1
                                
                                report_lines.append(f"## {show_date} - {show_venue} (SHNID: {shnid})")
                                report_lines.append(f"- **Fixed Split Encore:** {s.get('n', 'Encore')}")
                                report_lines.append(f"- **Moved {len(tracks_to_move)} tracks** to previous set ({prev_set.get('n', 'Previous Set')}):")
                                for m in tracks_to_move:
                                    report_lines.append(f"  - {m.get('t', '')}")
                                report_lines.append(f"- **Remaining Encore Tracks:**")
                                for k in tracks_to_keep:
                                    report_lines.append(f"  - {k.get('t', '')}")
                                report_lines.append("")

            # Cleanup empty sets
            source['sets'] = [s for s in sets if s.get('t')]

    # Generate Report
    print(f"Generating report {report_file}...")
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write("# Long Encore Fix Report\n\n")
        f.write(f"**Total Sets Fixed:** {total_fixed}\n\n")
        
        if report_lines:
            f.write("\n".join(report_lines))
        else:
            f.write("No Long Encores matching criteria found.\n")

    # Save Output
    print(f"Saving to {output_file}...")
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, separators=(',', ':'))
    
    print("Done.")

if __name__ == '__main__':
    fix_long_encores()
