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

def get_categories(source):
    categories = set()
    
    # Safely get tracks
    tracks = source.get('tracks', [])
    if not tracks:
        # Some sources might be empty or malformed?
        # Logic says url from first track
        url = ''
    else:
        # Optimized key 'u' for url
        url = tracks[0].get('u', '').lower()
        
    # Source type 'src' might not be in optimized input? 
    # Input file 1 source keys: ['id', 'published', 'tracks'] (from earlier probe)
    # So 'src' might be missing in input. Logic relies on URL mostly then.
    # We'll check if 'src' exists anyway.
    src_type = source.get('src', '').lower()

    # Check for "Unknown" (feat track starting with 'gd')
    # Optimized key 't' for title
    has_feat_track = False
    for t in tracks:
        title = t.get('t', '').lower()
        if title.startswith('gd'):
            has_feat_track = True
            break
            
    if has_feat_track:
        categories.add('unk')

    if src_type == 'ultra' or 'ultra' in url or 'healy' in url or 'sbd-matrix' in url:
        categories.add('ultra')

    if 'betty' in url or 'bbd' in url:
        categories.add('betty')

    # Matrix
    if src_type == 'mtx' or src_type == 'matrix' or 'mtx' in url or 'matrix' in url:
        # Strict excludes
        is_excluded = 'sbd-matrix' in url or 'ultramatrix' in url or 'ultra.mtx' in url or 'ultra.matrix' in url
        if not is_excluded:
            categories.add('matrix')

    if 'dsbd' in url:
        categories.add('dsbd')

    if 'fm' in url or 'prefm' in url or 'pre-fm' in url:
        categories.add('fm')

    if src_type == 'sbd' or 'sbd' in url:
        categories.add('sbd')

    return categories

def main():
    new_data_path = 'assets/data/archive_tracks_shnid_opt.json'
    old_data_path = 'assets/data/output.optimized.json'
    output_path = 'assets/data/output.optimized6.json'
    updated_report_path = 'updated.json'
    markdown_report_path = 'comparison_report.md'

    print(f"Loading {new_data_path}...")
    new_data = load_json(new_data_path)
    print(f"Loading {old_data_path}...")
    old_data = load_json(old_data_path)

    old_shows_by_date = {show['date']: show for show in old_data}
    
    old_source_ids = set()
    for show in old_data:
        for source in show.get('sources', []):
            old_source_ids.add(source['id'])

    new_shows_found = []
    updated_shows_info = [] 
    
    result_data = old_data 
    
    total_new_sources = 0

    for show in new_data:
        date = show.get('date')
        if not date:
            continue
            
        if date not in old_shows_by_date:
            # --- NEW SHOW ---
            result_data.append(show)
            
            # Analyze categories for new show sources
            show_cats = []
            sources = show.get('sources', [])
            for s in sources:
                old_source_ids.add(s['id'])
                cats = get_categories(s)
                s_info = {
                    'id': s['id'],
                    'categories': list(cats)
                }
                show_cats.append(s_info)
            
            new_shows_found.append({
                'show': show,
                'source_details': show_cats
            })
            total_new_sources += len(sources)
                
        else:
            # --- EXISTING SHOW ---
            existing_show = old_shows_by_date[date]
            existing_sources = existing_show.get('sources', [])
            
            added_source_details = []
            
            for source in show.get('sources', []):
                if source['id'] not in old_source_ids:
                    # New source
                    existing_sources.append(source)
                    old_source_ids.add(source['id'])
                    
                    cats = get_categories(source)
                    added_source_details.append({
                        'id': source['id'],
                        'categories': list(cats)
                    })
                    
                    total_new_sources += 1
            
            if added_source_details:
                existing_show['sources'] = existing_sources
                
                updated_shows_info.append({
                    'date': existing_show.get('date'),
                    'name': existing_show.get('name'),
                    'added_sources': added_source_details,
                    'full_object': existing_show
                })

    # --- Generate Markdown Report ---
    with open(markdown_report_path, 'w', encoding='utf-8') as report:
        report.write(f"# JSON Comparison Report\n\n")
        report.write(f"- **New Data**: `{new_data_path}`\n")
        report.write(f"- **Old Data**: `{old_data_path}`\n\n")
        
        report.write(f"## Summary\n")
        report.write(f"- Total Shows in Result: **{len(result_data)}**\n")
        report.write(f"- New Shows Added: **{len(new_shows_found)}**\n")
        report.write(f"- Existing Shows Updated: **{len(updated_shows_info)}**\n")
        report.write(f"- Total New Sources (SHNIDs) Found: **{total_new_sources}**\n\n")

        if new_shows_found:
            report.write(f"## New Shows Added\n")
            report.write(f"| Date | Name | new SHNID (Categories) |\n")
            report.write(f"|---|---|---|\n")
            for item in new_shows_found:
                s = item['show']
                details = item['source_details']
                # Format: SHNID (cat1, cat2)
                details_str = ", ".join([f"`{d['id']}` ({', '.join(d['categories']) if d['categories'] else 'None'})" for d in details])
                report.write(f"| {s.get('date')} | {s.get('name')} | {details_str} |\n")
            report.write("\n")
        
        if updated_shows_info:
            report.write(f"## Updated Shows (New Sources)\n")
            for item in updated_shows_info:
                report.write(f"### {item['date']} - {item['name']}\n")
                for source in item['added_sources']:
                    cats_str = ", ".join(source['categories']) if source['categories'] else "None"
                    report.write(f"- Added SHNID: `{source['id']}` - Categories: **{cats_str}**\n")
                report.write("\n")

    # --- Save optimized output ---
    print(f"Saving {output_path}...")
    save_json(result_data, output_path, minified=True)

    # --- Save updated.json ---
    updates_collection = [item['show'] for item in new_shows_found] + [u['full_object'] for u in updated_shows_info]
    print(f"Saving {updated_report_path} with {len(updates_collection)} items...")
    save_json(updates_collection, updated_report_path, minified=False)

    print(f"Report generated at {markdown_report_path}")

if __name__ == "__main__":
    main()
