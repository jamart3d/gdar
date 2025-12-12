import json
import os

def load_json(path):
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_json(data, path, minified=False):
    with open(path, 'w', encoding='utf-8') as f:
        if minified:
            json.dump(data, f, separators=(',', ':'))
        else:
            json.dump(data, f, indent=2)

def main():
    input_path = 'assets/data/output.optimizedo_fixed.json'
    output_path = 'assets/data/output.optimizedo_final.json'
    report_path = 'removal_report.md'

    print(f"Loading {input_path}...")
    try:
        data = load_json(input_path)
    except FileNotFoundError:
        print(f"File not found: {input_path}")
        return

    cleaned_data = []
    removed_count = 0
    removed_shows_count = 0
    
    # Details for report
    removed_details = []

    for show in data:
        show_date = show.get('date', 'Unknown')
        show_name = show.get('name', 'Unknown')
        
        valid_sources = []
        show_removed_ids = []
        
        for source in show.get('sources', []):
            src_val = source.get('src', '')
            
            if src_val:
                valid_sources.append(source)
            else:
                removed_count += 1
                show_removed_ids.append(source.get('id', 'Unknown'))
        
        if show_removed_ids:
            removed_details.append({
                'date': show_date,
                'name': show_name,
                'ids': show_removed_ids,
                'fully_removed': len(valid_sources) == 0
            })
            
        if valid_sources:
            new_show = show.copy()
            new_show['sources'] = valid_sources
            cleaned_data.append(new_show)
        else:
            removed_shows_count += 1

    # --- Generate Report ---
    print(f"Generating report at {report_path}...")
    with open(report_path, 'w', encoding='utf-8') as f:
        f.write("# Empty 'src' Removal Report\n\n")
        f.write(f"- **Input**: `{input_path}`\n")
        f.write(f"- **Output**: `{output_path}`\n\n")
        
        f.write("## Summary\n")
        f.write(f"- Total Sources Removed: **{removed_count}**\n")
        f.write(f"- Shows Completely Removed: **{removed_shows_count}**\n")
        f.write(f"- Final Show Count: **{len(cleaned_data)}**\n\n")
        
        if removed_details:
            f.write("## Details\n")
            f.write("| Date | Show Name | Removed SHNIDs | Status |\n")
            f.write("|---|---|---|---|\n")
            for item in removed_details:
                ids_str = ", ".join([f"`{id}`" for id in item['ids']])
                status = "**Show Removed**" if item['fully_removed'] else "Kept (Sources Remaining)"
                f.write(f"| {item['date']} | {item['name']} | {ids_str} | {status} |\n")
        else:
            f.write("\n_No items removed._\n")

    # --- Save Output ---
    print(f"Saving {output_path}...")
    save_json(cleaned_data, output_path, minified=True)
    
    print("Done.")

if __name__ == "__main__":
    main()
