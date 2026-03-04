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
            
            # 3. Simulate Shift (Titles Only)
            if len(titles) >= 32:
                # Move Title at 31 to 20
                moved_title = titles.pop(31)
                titles.insert(20, moved_title)
                
                # 4. Simulate Set Restructuring
                # Apply set name changes based on new title positions
                # Triggers: Bertha -> Set 2, El Paso -> Set 3, Uncle John's Band -> Encore
                
                current_set = "Set 1"
                # Refill set_names based on triggers
                for i in range(len(titles)):
                    title_clean = titles[i].lower()
                    
                    if "bertha" in title_clean:
                        current_set = "Set 2"
                    elif "el paso" in title_clean:
                        current_set = "Set 3"
                    elif "uncle john's band" in title_clean:
                        current_set = "Encore"
                    
                    set_names[i] = current_set

                f.write("\n---\n")
                f.write("## Simulated Tracklist (Title Shift + Set Updates)\n")
                f.write("- **Shift**: Moved Title 32 ('Phil & Ned...') to Position 21.\n")
                f.write("- **Sets**: Set 2 Starts at 'Bertha', Set 3 at 'El Paso', Encore at 'Uncle John\\'s Band'.\n\n")
                
                for i in range(len(titles)):
                    f.write(f"{i+1}. **[{set_names[i]}]** {titles[i]}\n")
                    f.write(f"   - URL: `{urls[i]}`\n")
            else:
                f.write(f"\n**Simulation Error**: Not enough tracks ({len(titles)}) to perform move from index 31.\n")

    print("Done.")

if __name__ == "__main__":
    input_path = 'assets/data/output.optimized_src_encore_fix.json'
    # Fallback
    if not os.path.exists(input_path):
         input_path = 'assets/data/output.optimized_src.json'
         
    target_id = "121836"
    output_report = 'inspect_121836.md'
    inspect_shnid(input_path, target_id, output_report)
