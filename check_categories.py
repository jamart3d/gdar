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
    output_json_path = 'foo.json'
    report_path = 'src_report_fixed.md'

    print(f"Loading {input_path}...")
    try:
        data = load_json(input_path)
    except FileNotFoundError:
        print(f"File not found: {input_path}")
        return

    empty_src_sources = []
    shows_with_empty_src = set()
    total_sources = 0

    for show in data:
        show_date = show.get('date', 'Unknown')
        show_name = show.get('name', 'Unknown')
        
        for source in show.get('sources', []):
            total_sources += 1
            src_val = source.get('src', '')
            
            if not src_val: # Empty string or None
                # Get URL for report
                tracks = source.get('tracks', [])
                url = ''
                if tracks:
                    track_url = tracks[0].get('u', '')
                    base_dir = source.get('_d')
                    if base_dir and track_url and not track_url.startswith('http'):
                        url = f"https://archive.org/download/{base_dir}/{track_url}"
                    else:
                        url = track_url
                
                empty_src_sources.append({
                    'date': show_date,
                    'name': show_name,
                    'id': source.get('id', 'Unknown'),
                    'url': url
                })
                shows_with_empty_src.add(show_date + show_name)

    # --- Generate Report ---
    print(f"Generating report at {report_path}...")
    with open(report_path, 'w', encoding='utf-8') as f:
        f.write("# Source 'src' Attribute Report\n\n")
        f.write(f"- **Input**: `{input_path}`\n\n")
        
        f.write("## Summary\n")
        f.write(f"- Total Sources Checked: **{total_sources}**\n")
        f.write(f"- Sources with Empty 'src': **{len(empty_src_sources)}**\n")
        f.write(f"- Shows Affected: **{len(shows_with_empty_src)}**\n\n")
        
        if empty_src_sources:
            f.write("## Details (Empty 'src')\n")
            f.write("| Date | SHNID | Archive Details URL | First Track Path |\n")
            f.write("|---|---|---|---|\n")
            for item in empty_src_sources:
                details_url = f"https://archive.org/details/{item['id']}"
                f.write(f"| {item['date']} | `{item['id']}` | `{details_url}` | `{item['url']}` |\n")
        else:
            f.write("\n_No sources with empty 'src' found._\n")

    # --- Save JSON Output (Optional, same as before) ---
    # User asked to "save to foo.json"
    # We'll save the list of problem objects?
    print(f"Saving {output_json_path} with {len(empty_src_sources)} items...")
    save_json(empty_src_sources, output_json_path, minified=False)
    
    print("Done.")

if __name__ == "__main__":
    main()
