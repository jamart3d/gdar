import json
import os

def fix_shnid_121836(input_file, output_file):
    print(f"Reading from {input_file}...")
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"Error: Input file {input_file} not found.")
        return

    target_id = "121836"
    target_source = None
    
    # Locate Source
    for show in data:
        for source in show.get('sources', []):
            if source.get('id') == target_id:
                target_source = source
                break
        if target_source:
            break
            
    if not target_source:
        print(f"Error: SHNID {target_id} not found.")
        return

    report_lines = []
    report_lines.append(f"# Fix Report for SHNID {target_id}\n")
    print(f"Found SHNID {target_id}. Processing...")

    def print_sets(label, sets):
        header = f"\n### {label}\n"
        print(header.strip())
        report_lines.append(header)
        
        for s in sets:
            set_header = f"**[{s.get('n', 'Unknown Set')}]**\n"
            print(f"[{s.get('n', 'Unknown Set')}]")
            report_lines.append(set_header)
            
            for i, t in enumerate(s.get('t', [])):
                line = f"{i+1}. {t.get('t', 'Unknown Title')}"
                print(f"  {line}")
                report_lines.append(f"{i+1}. {t.get('t', 'Unknown Title')}\n")
            report_lines.append("\n")
        
        sep = "---\n"
        print("------------------\n")
        report_lines.append(sep)

    # Report Before
    print_sets("BEFORE FIX", target_source.get('sets', []))

    # 1. Flatten all tracks to work with them easily
    all_tracks = []
    for set_obj in target_source.get('sets', []):
        for track in set_obj.get('t', []):
            all_tracks.append(track)
            
    # 2. Extract Titles to perform the Shift
    # We only shift titles, keeping other metadata (URLs, durations, etc.) in place on the objects
    titles = [t.get('t', '') for t in all_tracks]
    
    # Check if we have enough tracks
    if len(titles) >= 32:
        # Move Title at 31 (originally "Phil & Ned Jam...") to 20 (originally "El Paso")
        moved_title = titles.pop(31)
        titles.insert(20, moved_title)
        msg = f"Applied Title Shift: Moved '{moved_title}' (Index 31) to Index 20."
        print(msg)
        report_lines.append(f"\n> {msg}\n")
        
        # Write titles back to the track objects
        for i, title in enumerate(titles):
            all_tracks[i]['t'] = title
    else:
        err = f"Error: Not enough tracks ({len(titles)}) to perform shift."
        print(err)
        report_lines.append(f"\n> **{err}**\n")
        return

    # 3. Restructure Sets based on Triggers
    new_sets = []
    
    # Triggers
    # Default starts at Set 1
    current_set_name = "Set 1"
    current_set_tracks = []
    
    for track in all_tracks:
        title_lower = track.get('t', '').lower()
        
        # Check for set boundaries
        if "bertha" in title_lower:
            # Finish previous set if mostly full, or just switch?
            # Standard logic: Close current set (if not empty), start new one
            if current_set_tracks:
                new_sets.append({"n": current_set_name, "t": current_set_tracks})
            current_set_name = "Set 2"
            current_set_tracks = []
            
        elif "el paso" in title_lower:
             if current_set_tracks:
                new_sets.append({"n": current_set_name, "t": current_set_tracks})
             current_set_name = "Set 3"
             current_set_tracks = []
             
        elif "uncle john's band" in title_lower:
             if current_set_tracks:
                new_sets.append({"n": current_set_name, "t": current_set_tracks})
             current_set_name = "Encore"
             current_set_tracks = []
        
        current_set_tracks.append(track)
        
    # Append final set
    if current_set_tracks:
        new_sets.append({"n": current_set_name, "t": current_set_tracks})
        
    # Report After
    print_sets("AFTER FIX", new_sets)

    # 4. Update Source
    target_source['sets'] = new_sets
    
    # Save Report
    report_file = "fix_shnid_121836_report.md"
    print(f"Saving report to {report_file}...")
    with open(report_file, 'w', encoding='utf-8') as f:
        f.writelines(report_lines)

    # Save Output
    print(f"Saving modified data to {output_file}...")
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, separators=(',', ':'))
        
    print("Done. Fix applied.")

if __name__ == "__main__":
    input_path = 'assets/data/output.optimized_src_api.json'
    output_path = 'assets/data/output.optimized.json'
    
    # Fallback input for testing
    if not os.path.exists(input_path):
         print(f"Warning: {input_path} not found, trying previous version.")
         input_path = 'assets/data/output.optimized_src.json'

    fix_shnid_121836(input_path, output_path)
