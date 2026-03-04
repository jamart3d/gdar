import json
import re
import os
import sys

def audit_and_fix_set_structure(input_file, report_file, correction_file, output_db_file):
    print(f"Reading from {input_file}...")
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"Error: Input file {input_file} not found.")
        return

    # Regex to capture s1 set markers
    disc_regex = re.compile(r'[a-z0-9](s)(\d+)[t_]')

    # ---------------------------------------------------------
    # MODE 1: Apply Corrections if file exists
    # ---------------------------------------------------------
    if os.path.exists(correction_file):
        print(f"Found correction file '{correction_file}'. Applying changes to dataset...")
        try:
            with open(correction_file, 'r', encoding='utf-8') as f:
                corrections = json.load(f)
        except json.JSONDecodeError:
            print(f"Error: Failed to parse '{correction_file}'.")
            return

        # Map flagged sources for quick lookup
        # We need to find the source in 'data' by ID.
        # To be efficient, let's create a map of ID -> Source Object, or just iterate.
        # Since 'corrections' might be large, we'll iterate the corrections.
        
        applied_count = 0
        
        # Create a lookup for the main data to avoid O(N*M)
        source_lookup = {}
        for show in data:
            for source in show.get('sources', []):
                source_lookup[source.get('id')] = source

        for item in corrections:
            shnid = item.get('id')
            new_tracks = item.get('tracks')
            
            target_source = source_lookup.get(shnid)
            if not target_source:
                print(f"Warning: SHNID {shnid} from correction file not found in main dataset.")
                continue

            # Reconstruct sets from flat track list
            new_sets = []
            current_set_name = None
            current_set_tracks = []

            for track in new_tracks:
                track_set = track.get('set', 'Unknown Set')
                
                if track_set != current_set_name:
                    if current_set_name is not None:
                        new_sets.append({
                            "n": current_set_name,
                            "t": current_set_tracks
                        })
                    current_set_name = track_set
                    current_set_tracks = []
                
                # Copy track data
                t_obj = {
                    "t": track.get('title'),
                    "u": track.get('url')
                }
                if track.get('duration'):
                    t_obj['d'] = track.get('duration')
                
                current_set_tracks.append(t_obj)

            if current_set_name is not None:
                new_sets.append({
                    "n": current_set_name,
                    "t": current_set_tracks
                })

            # Apply
            target_source['sets'] = new_sets
            applied_count += 1

        print(f"Applied fixes to {applied_count} sources.")
        print(f"Saving new dataset to '{output_db_file}'...")
        with open(output_db_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, separators=(',', ':'))
        print("Done.")
        return

    # ---------------------------------------------------------
    # MODE 2: Audit & Generate Correction File
    # ---------------------------------------------------------
    print(f"Correction file not found. Running audit (Post-1970) to generate it...")
    
    issues = []
    correction_data = [] # List of objects for the JSON file
    
    total_sources = 0
    flagged_sources = 0

    for show in data:
        show_date = show.get('date', 'Unknown')
        
        # Filter Pre-1970
        if show_date < "1970":
            continue

        show_venue = show.get('venue', 'Unknown')
        
        for source in show.get('sources', []):
            total_sources += 1
            source_id = source.get('id', 'Unknown')
            sets = source.get('sets', [])
            if not sets:
                continue

            # Analysis
            source_has_issues = False
            set_analysis = []
            all_indicators = set()

            for set_obj in sets:
                set_name = set_obj.get('n', 'Unknown').strip()
                tracks = set_obj.get('t', [])
                
                set_indicators = set()
                indicator_files = {} 
                
                for t in tracks:
                    url = t.get('u', '')
                    match = disc_regex.search(url)
                    if match:
                        indicator_num = int(match.group(2))
                        set_indicators.add(indicator_num)
                        all_indicators.add(indicator_num)
                        
                        if indicator_num not in indicator_files:
                            indicator_files[indicator_num] = []
                        if len(indicator_files[indicator_num]) < 3:
                            indicator_files[indicator_num].append(url)
                
                set_analysis.append({
                    "name": set_name,
                    "indicators": sorted(list(set_indicators)),
                    "files": indicator_files
                })

                # CHECK 1: "Set 2+" with "s1"
                is_set_2_plus = set_name.lower().startswith("set 2") or \
                                set_name.lower().startswith("set 3") or \
                                set_name.lower().startswith("second set")
                
                if is_set_2_plus and 1 in set_indicators:
                    source_has_issues = True
                    set_analysis[-1]['issue'] = f"Contains Disc/Set 1 tracks in '{set_name}'"

                # CHECK 2: Mixed sets
                if len(set_indicators) >= 3:
                     source_has_issues = True
                     set_analysis[-1]['issue'] = f"Contains tracks from {len(set_indicators)} different discs/sets"

                # CHECK 3: Set 1 with late discs
                is_set_1 = set_name.lower().startswith("set 1") or set_name.lower().startswith("first set")
                if is_set_1 and set_indicators and min(set_indicators) >= 2:
                     source_has_issues = True
                     set_analysis[-1]['issue'] = f"'{set_name}' contains ONLY Disc/Set {min(set_indicators)}+ tracks"

            # Aggregate suspicious single sets
            if len(sets) == 1 and len(all_indicators) >= 2:
                if len(all_indicators) >= 3:
                    source_has_issues = True
                    set_analysis[0]['issue'] = getattr(set_analysis[0], 'issue', "") + " [Suspicious: Single set object contains 3+ discs]"

            if source_has_issues:
                flagged_sources += 1
                
                # Add to Report
                issues.append({
                    "id": source_id,
                    "date": show_date,
                    "venue": show_venue,
                    "sets": set_analysis
                })
                
                # Add to Correction JSON
                # Flatten tracks
                flat_tracks = []
                for set_obj in sets:
                    s_name = set_obj.get('n', 'Unknown')
                    for t in set_obj.get('t', []):
                        # Default to existing set name
                        guessed_set = s_name
                        
                        # Apply User Rules for Pre-Fixing
                        # s1 -> Set 1
                        # s4 -> Encore
                        match = disc_regex.search(t.get('u', ''))
                        if match:
                            ind = match.group(2)
                            if ind == '1':
                                guessed_set = "Set 1"
                            elif ind == '2':
                                guessed_set = "Set 2"
                            elif ind == '3':
                                guessed_set = "Set 3"
                            elif ind == '4':
                                guessed_set = "Encore"

                        flat_tracks.append({
                            "set": guessed_set,
                            "title": t.get('t'),
                            "url": t.get('u'),
                            "duration": t.get('d', 0)
                        })
                
                correction_data.append({
                    "id": source_id,
                    "date": show_date,
                    "venue": show_venue,
                    "tracks": flat_tracks
                })

    # Output Report
    print(f"Analyzed {total_sources} post-1970 sources. Found {flagged_sources} issues.")
    
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write("# Set Structure Audit Report (Post-1970)\n\n")
        f.write(f"- **Input File**: `{input_file}`\n")
        f.write(f"- **Issues Found**: {flagged_sources}\n\n")
        
        for item in issues:
            f.write(f"## {item['date']} - SHNID {item['id']}\n")
            f.write(f"**Venue**: {item['venue']}\n\n")
            for s in item['sets']:
                issue_str = f" **⚠️ {s.get('issue')}**" if s.get('issue') else ""
                indicators_str = ", ".join([str(i) for i in s['indicators']])
                f.write(f"- **{s['name']}**: Markers [{indicators_str}]{issue_str}\n")
                if s.get('indicators'):
                    f.write("  > *Example Files*:\n")
                    for ind in s['indicators']:
                        files = s['files'].get(ind, [])
                        file_list = ", ".join([f"`{x}`" for x in files])
                        f.write(f"    - Marker {ind}: {file_list}\n")
            f.write("\n---\n")

    print(f"Report saved to {report_file}")
    
    # Output Correction JSON
    with open(correction_file, 'w', encoding='utf-8') as f:
        json.dump(correction_data, f, indent=4)
    print(f"Generated companion correction file: '{correction_file}'")
    print("ACTION REQUIRED: Edit the 'set' fields in this JSON file to fix the issues, then run this script again to apply changes.")

if __name__ == "__main__":
    input_path = 'assets/data/output.optimized_src.json'
    report_path = 'tool/set_structure_audit.md'
    correction_path = 'tool/set_structure_corrections.json'
    output_db_path = 'assets/data/output.optimized_src_fixed_structure.json'
    
    audit_and_fix_set_structure(input_path, report_path, correction_path, output_db_path)
