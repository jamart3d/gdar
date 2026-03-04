import json
import os
import sys

def inspect_and_fix_shnid(input_file, target_id, correction_file, output_db_file):
    print(f"Reading from {input_file}...")
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"Error: Input file {input_file} not found.")
        return

    # Find the target source
    target_show = None
    target_source = None
    
    for show in data:
        for source in show.get('sources', []):
            if source.get('id') == target_id:
                target_show = show
                target_source = source
                break
        if target_source:
            break

    if not target_source:
        print(f"Error: Source ID {target_id} not found in dataset.")
        return

    print(f"Found SHNID {target_id} in {target_show.get('date')} - {target_show.get('venue')}")

    # Mode 1: Generate Correction File if it doesn't exist
    if not os.path.exists(correction_file):
        print(f"Correction file '{correction_file}' not found. Generating template...")
        
        flat_tracks = []
        for set_obj in target_source.get('sets', []):
            set_name = set_obj.get('n', 'Unknown Set')
            for track in set_obj.get('t', []):
                flat_tracks.append({
                    "set": set_name,
                    "title": track.get('t'),
                    "url": track.get('u'),
                    "duration": track.get('d') 
                })
        
        with open(correction_file, 'w', encoding='utf-8') as f:
            json.dump(flat_tracks, f, indent=4)
            
        print(f"Successfully created '{correction_file}'.")
        print("ACTION REQUIRED: Edit this file to adjust 'set' names or reorder tracks, then rerun this script.")
        return

    # Mode 2: Apply Corrections
    else:
        print(f"Found correction file '{correction_file}'. Applying changes...")
        
        try:
            with open(correction_file, 'r', encoding='utf-8') as f:
                corrected_tracks = json.load(f)
        except json.JSONDecodeError:
            print(f"Error: Failed to parse '{correction_file}'. Please check JSON syntax.")
            return

        # Reconstruct sets
        new_sets = []
        current_set_name = None
        current_set_tracks = []

        for track in corrected_tracks:
            track_set = track.get('set', 'Unknown Set')
            
            # Start a new set if the name changes
            if track_set != current_set_name:
                # Close previous set if exists
                if current_set_name is not None:
                    new_sets.append({
                        "n": current_set_name,
                        "t": current_set_tracks
                    })
                
                # Start new set
                current_set_name = track_set
                current_set_tracks = []
            
            # Add track to current set
            t_obj = {
                "t": track.get('title'),
                "u": track.get('url')
            }
            if track.get('duration'):
                t_obj['d'] = track.get('duration')
                
            current_set_tracks.append(t_obj)

        # Append final set
        if current_set_name is not None:
            new_sets.append({
                "n": current_set_name,
                "t": current_set_tracks
            })

        # Update the source in the main data
        target_source['sets'] = new_sets
        
        # Save output
        print(f"Saving modified dataset to '{output_db_file}'...")
        with open(output_db_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, separators=(',', ':')) 
            
        print("Success! New dataset saved.")
        
        # Method to generate report
        report_file = correction_file.replace('.json', '_report.md')
        with open(report_file, 'w', encoding='utf-8') as f:
            f.write(f"# Fix Report for SHNID {target_id}\n\n")
            f.write(f"Source: {correction_file}\n\n")
            for i, s in enumerate(new_sets):
                f.write(f"## {s['n']}\n")
                for t in s['t']:
                    f.write(f"- {t['t']}\n")
        print(f"Verification report saved to '{report_file}'.")

if __name__ == "__main__":
    input_path = 'assets/data/output.optimized_src.json'
    target_id = "170209"
    
    correction_map = 'tool/corrections_170209.json'
    
    # We output to a new file to stay safe, can be renamed later
    output_path = 'assets/data/output.optimized_src_fixed_170209.json'
    
    inspect_and_fix_shnid(input_path, target_id, correction_map, output_path)
