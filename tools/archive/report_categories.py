import json
import os

STRICT_MODE = True # Matches app setting 'useStrictSrcCategorization'

def get_categories(source):
    categories = set()
    
    # Extract source details
    src_type = source.get('src', '').lower()
    
    tracks = source.get('tracks', [])

    # App logic checks 'source.tracks.first.url'.
    # In the app, Track.url is constructed as "$baseUrl$u".
    # baseUrl comes from "_d".
    # So effectively, the search string should be "_d" + "/" + "u".
    base_dir = source.get('_d', '').lower()
    first_track_u = ''
    if tracks:
        first_track_u = tracks[0].get('u', '').lower()
    
    # This 'url' variable is used for keyword checks throughout the function.
    # It represents the effective path/URL string for categorization.
    url = f"{base_dir}/{first_track_u}"

    # Check for "Unknown" shows (featured tracks starting with 'gd') - Matches Dart Logic
    # Note: Simplistic check based on track filenames or titles if available.
    # The python script loads 'tracks' which has 't' (title) usually. 
    # Let's check if we can access titles. The JSON usually has 't' for title.
    # The dart code checks: track.title.toLowerCase().startsWith('gd')
    # In JSON, track is a dict.
    has_feat = False
    for t in tracks:
        title = t.get('t', '').lower()
        if title.startswith('gd'):
            has_feat = True
            break
    if has_feat:
        categories.add('unk')

    # Strict Mode Logic
    if STRICT_MODE:
        if src_type == 'sbd': 
            categories.add('sbd')
        if src_type == 'mtx' or src_type == 'matrix': 
            categories.add('matrix')
        if src_type == 'ultra': 
            categories.add('ultra')
        if src_type == 'dsbd':
             categories.add('dsbd')
        if src_type == 'betty':
             categories.add('betty')
        if 'fm' in src_type: # Handling 'fm' if it appears in src
             categories.add('fm')
             
        return categories

    # Standard (Loose) Logic checking URL keywords...

    # Logic 2: Ultra
    if (src_type == 'ultra' or 
        'ultra' in url or 
        'healy' in url or 
        'sbd-matrix' in url):
        categories.add('ultra')

    # Logic 3: Betty
    if 'betty' in url or 'bbd' in url:
        categories.add('betty')

    # Logic 4: Matrix (Strict)
    # Dart: if (srcType == 'mtx' || srcType == 'matrix' || url.contains('mtx') || url.contains('matrix'))
    if (src_type == 'mtx' or 
        src_type == 'matrix' or 
        'mtx' in url or 
        'matrix' in url):
        
        is_excluded = ('sbd-matrix' in url or 
                       'ultramatrix' in url or 
                       'ultra.mtx' in url or 
                       'ultra.matrix' in url)
        
        if not is_excluded:
            categories.add('matrix')

    # Logic 5: DSBD
    if 'dsbd' in url:
        categories.add('dsbd')

    # Logic 6: FM
    if 'fm' in url or 'prefm' in url or 'pre-fm' in url:
        categories.add('fm')

    # Logic 7: SBD
    if src_type == 'sbd' or 'sbd' in url:
        categories.add('sbd')
        
    return categories

def main():
    file_path = 'assets/data/output.optimized_src.json'
    report_path = 'report.md'
    
    if not os.path.exists(file_path):
        print(f"Error: {file_path} not found.")
        return

    print(f"Loading data from {file_path}...")
    with open(file_path, 'r') as f:
        shows = json.load(f)

    total_shows = len(shows)
    total_sources = 0
    
    category_counts = {
        'sbd': 0,
        'matrix': 0,
        'ultra': 0,
        'betty': 0,
        'dsbd': 0,
        'fm': 0,
        'unk': 0
    }
    
    multi_category_counts = 0
    uncategorized_counts = 0
    
    # Specific collections for the report
    matrix_without_url_keyword = []
    unknown_paths = []
    multi_category_sources = []
    uncategorized_sources = []
    multi_value_src = []

    print(f"Analyzing {total_shows} shows...")

    for show in shows:
        sources = show.get('sources', [])
        total_sources += len(sources)
        show_name = show.get('name', 'Unknown Show')
        show_date = show.get('date', '')
        
        for source in sources:
            # Reconstruct URL for checking
            base_dir = source.get('_d', '').lower()
            tracks = source.get('tracks', [])
            first_track_url = ''
            if tracks:
                first_track_url = tracks[0].get('u', '').lower()
            
            # Full logic path for checking
            path_check = f"{base_dir}/{first_track_url}"
            # Full URL for display
            url = f"https://archive.org/download/{base_dir}/{first_track_url}"
            
            cats = get_categories(source)
            
            # Helper to create source info dict
            source_info = {
                'show': show_name,
                'date': show_date,
                'id': source.get('id', '?'),
                'url': url,
                'check_path': path_check,
                'cats': ', '.join(sorted(cats)) if cats else 'None'
            }

            if not cats:
                uncategorized_counts += 1
                uncategorized_sources.append(source_info)
            elif len(cats) > 1:
                multi_category_counts += 1
                multi_category_sources.append(source_info)
                
            for cat in cats:
                if cat in category_counts:
                    category_counts[cat] += 1
                else:
                    category_counts[cat] = 1
            
            # Check 1: Matrix without 'mtx'/'matrix' in URL
            if 'matrix' in cats:
                if 'mtx' not in path_check and 'matrix' not in path_check:
                    matrix_without_url_keyword.append(source_info)

            # Check 2: Unknowns
            if 'unk' in cats:
                unknown_paths.append(source_info)

            # Check 3: Multi-value src attribute (User Request)
            # We check the raw attribute from the JSON
            raw_src = source.get('src')
            if raw_src:
                is_multi = False
                val_str = str(raw_src)
                if isinstance(raw_src, list):
                    is_multi = True
                elif isinstance(raw_src, str) and ',' in raw_src:
                    is_multi = True
                
                if is_multi:
                    multi_value_src.append({
                        'show': show_name,
                        'date': show_date,
                        'id': source.get('id', '?'),
                        'src_val': val_str
                    })

    # Generate Report
    with open(report_path, 'w') as f:
        f.write("# Category Distribution Report\n\n")
        f.write(f"**Total Shows:** {total_shows}  \n")
        f.write(f"**Total Sources:** {total_sources}  \n\n")
        
        f.write("## Distribution\n")
        f.write("| Category | Count | Percentage |\n")
        f.write("|---|---|---|\n")
        
        sorted_cats = sorted(category_counts.items(), key=lambda x: x[1], reverse=True)
        for cat, count in sorted_cats:
            percentage = (count / total_sources * 100) if total_sources > 0 else 0
            f.write(f"| **{cat.upper()}** | {count} | {percentage:.1f}% |\n")
            
        f.write("\n")
        f.write(f"- **Sources with Multiple Categories:** {multi_category_counts}\n")
        f.write(f"- **Uncategorized Sources:** {uncategorized_counts}\n\n")
        
        f.write("## Matrix Sources without 'mtx'/'matrix' in URL\n")
        if matrix_without_url_keyword:
            f.write(f"Found {len(matrix_without_url_keyword)} sources.\n\n")
            f.write("| Date | Show Name | Source ID | Path |\n")
            f.write("|---|---|---|---|\n")
            for item in matrix_without_url_keyword:
                f.write(f"| {item['date']} | {item['show']} | {item['id']} | `{item['url']}` |\n")
        else:
            f.write("None found.\n")
            
        f.write("\n## Unknown Category Paths\n")
        if unknown_paths:
            f.write(f"Found {len(unknown_paths)} sources.\n\n")
            f.write("| Date | Show Name | Source ID | Path |\n")
            f.write("|---|---|---|---|\n")
            for item in unknown_paths:
                f.write(f"| {item['date']} | {item['show']} | {item['id']} | `{item['url']}` |\n")
        else:
            f.write("None found.\n")

        f.write("\n## Sources with Multiple Categories\n")
        if multi_category_sources:
            f.write(f"Found {len(multi_category_sources)} sources.\n\n")
            f.write("| Date | Show Name | Source ID | Categories | URL |\n")
            f.write("|---|---|---|---|---|\n")
            # Limit to 500 to prevent massive file if too many
            for item in multi_category_sources[:500]: 
                f.write(f"| {item['date']} | {item['show']} | {item['id']} | {item['cats']} | {item['url']} |\n")
            if len(multi_category_sources) > 500:
                f.write(f"\n... and {len(multi_category_sources) - 500} more.\n")
        else:
            f.write("None found.\n")

        f.write("\n## Uncategorized Sources\n")
        if uncategorized_sources:
            f.write(f"Found {len(uncategorized_sources)} sources.\n\n")
            f.write("| Date | Show Name | Source ID | URL |\n")
            f.write("|---|---|---|---|\n")
            for item in uncategorized_sources[:500]:
                f.write(f"| {item['date']} | {item['show']} | {item['id']} | {item['url']} |\n")
            if len(uncategorized_sources) > 500:
                f.write(f"\n... and {len(uncategorized_sources) - 500} more.\n")
        else:
            f.write("None found.\n")

        f.write("\n## Sources with Multiple Values for 'src' Attribute\n")
        if multi_value_src:
            f.write(f"Found {len(multi_value_src)} sources.\n\n")
            f.write("| Date | Show Name | Source ID | Value |\n")
            f.write("|---|---|---|---|\n")
            for item in multi_value_src:
                  f.write(f"| {item['date']} | {item['show']} | {item['id']} | `{item['src_val']}` |\n")
        else:
            f.write("None found.\n")

    print(f"Report generated at {report_path}")

if __name__ == "__main__":
    main()
