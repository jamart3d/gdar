import json
import os

def inspect_shnid(input_file, target_id, report_file):
    print(f"Reading from {input_file}...")
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"Error: Input file {input_file} not found.")
        return

    target_source = None
    target_show_date = None
    target_venue = None

    for show in data:
        for source in show.get('sources', []):
            if str(source.get('id')) == str(target_id):
                target_source = source
                target_show_date = show.get('date', 'Unknown Date')
                target_venue = show.get('venue', 'Unknown Venue')
                break
        if target_source:
            break

    print(f"Generating comprehensive report for SHNID {target_id} to {report_file}...")
    
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write(f"# Inspection Report: SHNID {target_id}\n\n")
        f.write(f"- **Input File**: `{input_file}`\n")
        
        if not target_source:
            f.write(f"\n**Error**: Source ID `{target_id}` not found in the dataset.\n")
            print(f"Source ID {target_id} not found.")
        else:
            f.write(f"- **Date**: {target_show_date}\n")
            f.write(f"- **Venue**: {target_venue}\n")
            
            # 1. Collect Data
            f.write("\n## Tracklist\n\n")
            
            track_counter = 1
            for set_obj in target_source.get('sets', []):
                set_name = set_obj.get('n', 'Unknown Set')
                f.write(f"### {set_name}\n\n")
                for track in set_obj.get('t', []):
                    title = track.get('t', 'Unknown Title')
                    url = track.get('u', 'No URL')
                    f.write(f"{track_counter}. {title}\n")
                    f.write(f"   - URL: `{url}`\n")
                    track_counter += 1
                f.write("\n")

    print("Done.")

if __name__ == "__main__":
    input_path = 'assets/data/output.optimized_src.json'
    if not os.path.exists(input_path):
         input_path = '../assets/data/output.optimized_src.json'
         
    target_id = "135505"
    output_report = 'inspect_135505.md'
    inspect_shnid(input_path, target_id, output_report)
