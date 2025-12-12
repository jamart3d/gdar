import json
import sys
import os

def load_json(path):
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

def main():
    if len(sys.argv) < 2:
        print("Usage: python src_report.py <input_json_file>")
        sys.exit(1)

    input_path = sys.argv[1]
    report_path = 'src_report.md'

    print(f"Loading {input_path}...")
    try:
        data = load_json(input_path)
    except FileNotFoundError:
        print(f"File not found: {input_path}")
        return

    empty_src_sources = []
    shows_with_empty_src = set()
    total_sources = 0

    # Handle both list of shows or dict (if data structure is different, but assuming list of shows based on previous script)
    if isinstance(data, dict) and 'shows' in data:
         shows_iter = data['shows']
    elif isinstance(data, list):
         shows_iter = data
    else:
         shows_iter = [] # Or handle error

    for show in shows_iter:
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
                # Escape pipe characters in fields to prevent markdown table breakage
                url_display = item['url'].replace('|', '\|')
                f.write(f"| {item['date']} | `{item['id']}` | `{details_url}` | `{url_display}` |\n")
        else:
            f.write("\n_No sources with empty 'src' found._\n")

    print("Done.")

if __name__ == "__main__":
    main()
