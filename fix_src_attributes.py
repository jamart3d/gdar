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

def get_base_url(source):
    # Only if needed, but we used this for reporting before.
    # We mainly need the logic to derive src from URL text.
    tracks = source.get('tracks', [])
    if not tracks:
        return ''
    
    track_url = tracks[0].get('u', '').lower()
    base_dir = source.get('_d')
    if base_dir and track_url and not track_url.startswith('http'):
        return f"https://archive.org/download/{base_dir}/{track_url}".lower()
    
    return track_url

def derive_src(url, existing_src):
    # Determine implied categories
    categories = set()
    url = url.lower()
    
    # Logic mirroring ShowListProvider roughly + check_categories.py
    
    if 'ultra' in url or 'healy' in url or 'sbd-matrix' in url:
        categories.add('ultra')

    if 'mtx' in url or 'matrix' in url:
        is_excluded = 'sbd-matrix' in url or 'ultramatrix' in url or 'ultra.mtx' in url or 'ultra.matrix' in url
        if not is_excluded:
            categories.add('mtx')

    if 'fm' in url or 'prefm' in url or 'pre-fm' in url:
        categories.add('fm')

    if 'sbd' in url or 'dsbd' in url or 'betty' in url or 'bbd' in url:
        categories.add('sbd')
        
    # Unk logic: checked track titles starting with 'gd'
    # But usually 'src' field implies the recording type (SBD/AUD/MTX).
    # 'unk' is a specific category in provider though.
    # We'll stick to recording types for 'src' attribute.
    
    # Priority Resolution
    # Ultra often overrides SBD/Matrix labels or is a distinct quality
    if 'ultra' in categories:
        return 'ultra'
    if 'mtx' in categories:
        return 'mtx'
    if 'sbd' in categories:
        return 'sbd'
    if 'fm' in categories:
        return 'fm'
        
    return '' # No change if nothing found

def main():
    input_path = 'assets/data/output.optimizedo.json'
    output_path = 'assets/data/output.optimizedo_fixed.json'
    report_path = 'src_fix_report.md'

    print(f"Loading {input_path}...")
    try:
        data = load_json(input_path)
    except FileNotFoundError:
        print(f"File not found: {input_path}")
        return

    updated_count = 0
    updates_log = [] # List of {date, id, old_src, new_src, url}

    for show in data:
        show_date = show.get('date', 'Unknown')
        
        for source in show.get('sources', []):
            current_src = source.get('src', '')
            
            # Use full URL string for checking
            full_url_for_check = get_base_url(source)
            
            # Check for track title 'gd' check?
            # Script check_categories.py checked track titles for 'unk'.
            # User said "assign src attr from looking at first track path".
            # So primarily URL.
            
            new_src = derive_src(full_url_for_check, current_src)
            
            if new_src and new_src != current_src:
                source['src'] = new_src
                updated_count += 1
                updates_log.append({
                    'date': show_date,
                    'id': source.get('id'),
                    'new_src': new_src,
                    'url': full_url_for_check
                })

    # --- Generate Report ---
    print(f"Generating report at {report_path}...")
    with open(report_path, 'w', encoding='utf-8') as f:
        f.write("# Source 'src' Attribute Fix Report\n\n")
        f.write(f"- **Input**: `{input_path}`\n")
        f.write(f"- **Output**: `{output_path}`\n\n")
        
        f.write("## Summary\n")
        f.write(f"- Total Sources Updated: **{updated_count}**\n\n")
        
        if updates_log:
            f.write("## Details\n")
            f.write("| Date | SHNID | Assigned 'src' | Evidence (URL snippet) |\n")
            f.write("|---|---|---|---|\n")
            # Limit log if massive? 6000 items might be too big for a single MD file to read comfortably, 
            # but user wants report. We'll list valid updates.
            for item in updates_log:
                # Truncate URL for readability in table?
                url_snippet = item['url']
                if len(url_snippet) > 80:
                    url_snippet = "..." + url_snippet[-75:]
                f.write(f"| {item['date']} | `{item['id']}` | **{item['new_src']}** | `{url_snippet}` |\n")
        else:
            f.write("\n_No updates made._\n")

    # --- Save Output ---
    print(f"Saving {output_path}...")
    save_json(data, output_path, minified=True)
    
    print("Done.")

if __name__ == "__main__":
    main()
