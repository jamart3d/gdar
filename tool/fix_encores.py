import json
import os

def fix_encores_and_closers(input_file, output_file, report_file):
    print(f"Reading from {input_file}...")
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"Error: Input file {input_file} not found.")
        return

    actions_log = []

    satisfaction_count = 0
    sugar_mag_count = 0

    for show in data:
        show_date = show.get('date', 'Unknown Date')
        venue = show.get('venue', 'Unknown Venue')
        
        for source in show.get('sources', []):
            source_id = source.get('id', 'Unknown ID')
            sets = source.get('sets', [])
            
            # --- Pass 1: Fix Satisfaction (Set 2 -> Encore) ---
            # We do this first because if Set 2 ends with Satisfaction and Encore is Sugar Mag,
            # we want Satisfaction to end up in the Encore (likely after Sugar Mag if Sugar Mag stays, 
            # or alone if Sugar Mag moves).
            
            set2_index = -1
            encore_index = -1
            
            for i, set_obj in enumerate(sets):
                name = set_obj.get('n', '').lower()
                if "set 2" in name or "set ii" in name:
                    set2_index = i
                elif "encore" in name:
                    encore_index = i
            
            if set2_index != -1:
                set2 = sets[set2_index]
                set2_tracks = set2.get('t', [])
                if set2_tracks:
                    last_track = set2_tracks[-1]
                    title = last_track.get('t', '').lower()
                    
                    if "satisfaction" in title:
                        # Move to Encore
                        popped_track = set2_tracks.pop()
                        
                        if encore_index != -1:
                            sets[encore_index]['t'].append(popped_track)
                            action_detail = "Moved 'Satisfaction' from Set 2 to existing Encore."
                        else:
                            # Create new Encore
                            new_encore = {
                                "n": "Encore",
                                "t": [popped_track]
                            }
                            sets.append(new_encore)
                            encore_index = len(sets) - 1 # Update index for next pass
                            action_detail = "Moved 'Satisfaction' from Set 2 to NEW Encore."
                        
                        satisfaction_count += 1
                        actions_log.append({
                            'date': show_date,
                            'id': source_id,
                            'action': 'Move Satisfaction',
                            'detail': action_detail,
                            'track': popped_track.get('t', '')
                        })

            # --- Pass 2: Fix Sugar Magnolia (Encore -> Set 2) ---
            # Re-find indices in case Encore was added
            set2_index = -1
            encore_index = -1
             # Note: sets list might have changed length
            for i, set_obj in enumerate(sets):
                name = set_obj.get('n', '').lower()
                if "set 2" in name or "set ii" in name:
                    set2_index = i
                elif "encore" in name:
                    encore_index = i
            
            if encore_index != -1 and set2_index != -1:
                encore_set = sets[encore_index]
                encore_tracks = encore_set.get('t', [])
                
                sugar_mag_track = None
                
                # Condition A: Single track "Sugar Magnolia"
                if len(encore_tracks) == 1:
                    if "sugar magnolia" in encore_tracks[0].get('t', '').lower():
                        sugar_mag_track = encore_tracks.pop(0)
                        
                # Condition B: 2 tracks, First is "Sugar Magnolia"
                elif len(encore_tracks) == 2:
                    if "sugar magnolia" in encore_tracks[0].get('t', '').lower():
                        sugar_mag_track = encore_tracks.pop(0)
                
                if sugar_mag_track:
                    # Move to Set 2
                    sets[set2_index]['t'].append(sugar_mag_track)
                    
                    sugar_mag_count += 1
                    actions_log.append({
                        'date': show_date,
                        'id': source_id,
                        'action': 'Move Sugar Magnolia',
                        'detail': "Moved 'Sugar Magnolia' from Encore to Set 2.",
                        'track': sugar_mag_track.get('t', '')
                    })
                
                # Cleanup: If Encore is empty, remove it
                if not encore_tracks:
                    sets.pop(encore_index)

    # Save Output
    print(f"Saving modified data to {output_file}...")
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, separators=(',', ':'))

    # Generate Report
    print(f"Performed {satisfaction_count} Satisfaction moves.")
    print(f"Performed {sugar_mag_count} Sugar Magnolia moves.")
    print(f"Generating report to {report_file}...")
    
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write("# Encore Structure Fix Report\n\n")
        f.write(f"- **Input File**: `{input_file}`\n")
        f.write(f"- **Output File**: `{output_file}`\n")
        f.write(f"- **Satisfaction Moves**: {satisfaction_count}\n")
        f.write(f"- **Sugar Magnolia Moves**: {sugar_mag_count}\n")
        f.write("---\n\n")

        if not actions_log:
            f.write("No actions taken.\n")
        else:
            # Sort by date
            actions_log.sort(key=lambda x: (x['date'], x['id']))
            
            for item in actions_log:
                f.write(f"- **{item['date']}** [{item['id']}] **{item['action']}**: {item['detail']} (`{item['track']}`)\n")

    print("Done.")

if __name__ == "__main__":
    input_path = 'assets/data/output.optimized_src.json'
    output_path = 'assets/data/output.optimized_src_encore_fix.json'
    report_path = 'fix_encores_report.md'
    fix_encores_and_closers(input_path, output_path, report_path)

    print("Done.")

