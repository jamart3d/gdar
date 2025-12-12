import json
import os

def load_json(path):
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_json(data, path, minified=False):
    with open(path, 'w', encoding='utf-8') as f:
        if minified:
            # Use separators to remove whitespace for optimization
            json.dump(data, f, separators=(',', ':'))
        else:
            json.dump(data, f, indent=2)

def main():
    input_path = 'assets/data/output.optimized6.json'
    output_path = 'assets/data/output.optimized7.json'
    report_path = 'cleaning_report.md'

    print(f"Loading {input_path}...")
    data = load_json(input_path)

    cleaned_data = []
    removed_sources_count = 0
    removed_shows_count = 0
    
    # Store details for report
    # List of { 'date': ..., 'name': ..., 'removed_shnids': [] }
    removal_details = []

    for show in data:
        show_date = show.get('date', 'Unknown Date')
        show_name = show.get('name', 'Unknown Name')
        
        original_sources = show.get('sources', [])
        kept_sources = []
        removed_shnids_for_show = []

        for source in original_sources:
            should_remove = False
            tracks = source.get('tracks', [])
            
            # Check tracks for titles starting with 'gd'
            # Optimized JSON uses 't' for title
            for track in tracks:
                title = track.get('t', '').lower()
                if title.startswith('gd'):
                    should_remove = True
                    break
            
            if should_remove:
                removed_sources_count += 1
                source_id = source.get('id', 'Unknown ID')
                removed_shnids_for_show.append(source_id)
            else:
                kept_sources.append(source)

        if removed_shnids_for_show:
            removal_details.append({
                'date': show_date,
                'name': show_name,
                'removed_shnids': removed_shnids_for_show,
                'is_show_removed': len(kept_sources) == 0
            })

        if kept_sources:
            # Create a copy of the show with filtered sources
            # To avoid mutating validity of usage elsewhere if any
            new_show = show.copy()
            new_show['sources'] = kept_sources
            cleaned_data.append(new_show)
        else:
            # All sources removed, so show is removed
            removed_shows_count += 1

    # --- Generate Report ---
    print(f"Generating report at {report_path}...")
    with open(report_path, 'w', encoding='utf-8') as f:
        f.write("# Data Cleaning Report\n\n")
        f.write(f"- **Input**: `{input_path}`\n")
        f.write(f"- **Output**: `{output_path}`\n\n")
        
        f.write("## Summary\n")
        f.write(f"- Total Sources Removed: **{removed_sources_count}**\n")
        f.write(f"- Total Shows Removed (became empty): **{removed_shows_count}**\n")
        f.write(f"- Final Show Count: **{len(cleaned_data)}**\n\n")
        
        if removal_details:
            f.write("## Removed Items Details\n")
            f.write("| Date | Show Name | Removed SHNIDs | Show Status |\n")
            f.write("|---|---|---|---|\n")
            for item in removal_details:
                shnids_str = ", ".join([f"`{id}`" for id in item['removed_shnids']])
                status = "**Removed Completely**" if item['is_show_removed'] else "Kept (Partial)"
                f.write(f"| {item['date']} | {item['name']} | {shnids_str} | {status} |\n")
        else:
            f.write("\n_No items matched removal criteria._\n")

    # --- Save Output ---
    print(f"Saving {output_path}...")
    save_json(cleaned_data, output_path, minified=True)
    
    print("Done.")

if __name__ == "__main__":
    main()
