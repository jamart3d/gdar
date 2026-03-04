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
            if source.get('id') == target_id:
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
            titles = []
            urls = []
            set_names = []
            
            for set_obj in target_source.get('sets', []):
                set_name = set_obj.get('n', 'Unknown Set')
                for track in set_obj.get('t', []):
                    titles.append(track.get('t', 'Unknown Title'))
                    urls.append(track.get('u', 'No URL'))
                    set_names.append(set_name)
            
            # 2. Print Original
            f.write("\n## Original Tracklist\n\n")
            for i in range(len(titles)):
                f.write(f"{i+1}. **[{set_names[i]}]** {titles[i]}\n")
                f.write(f"   - URL: `{urls[i]}`\n")
            
    print("Done.")

if __name__ == "__main__":
    input_path = 'assets/data/output.optimized_src.json'
    target_id = "131409"
    output_report = 'inspect_131409.md'
    inspect_shnid(input_path, target_id, output_report)
