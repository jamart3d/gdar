import json
import os

def get_categories_from_url(source):
    # Construct URL from _d and first track u
    base_dir = source.get('_d', '').lower()
    tracks = source.get('tracks', [])
    first_track_u = ''
    if tracks:
        first_track_u = tracks[0].get('u', '').lower()
    
    url = f"{base_dir}/{first_track_u}"
    
    # Priority Logic for Single Category
    
    # 1. Unknown (Featured Tracks)
    has_feat = False
    for t in tracks:
        title = t.get('t', '').lower()
        if title.startswith('gd'):
            has_feat = True
            break
    if has_feat:
        return {'unk'}, url

    # 2. Ultra
    if ('ultra' in url or 
        'healy' in url or 
        'sbd-matrix' in url):
        return {'ultra'}, url

    # 3. Betty
    if 'betty' in url or 'bbd' in url:
        return {'betty'}, url
    
    # 4. Matrix
    # User Request: "keep sources with .matrix. to mtx"
    # We use 'matrix' as the label to be consistent with app logic checking 'matrix' or 'mtx'.
    if 'mtx' in url or 'matrix' in url:
        is_excluded = ('sbd-matrix' in url or 
                       'ultramatrix' in url or 
                       'ultra.mtx' in url or 
                       'ultra.matrix' in url)
        if not is_excluded:
            return {'matrix'}, url

    # 5. DSBD
    if 'dsbd' in url:
        return {'dsbd'}, url

    # 6. FM
    if 'fm' in url or 'prefm' in url or 'pre-fm' in url:
        return {'fm'}, url

    # 7. SBD / sbeok
    # User Request: "if .sbd. move to category sbd" (interpreting ".sdb." as typo for ".sbd.")
    # Also catch ".sdb." typo per latest request.
    if 'sbd' in url or '.sbeok.' in url or '.sdb.' in url:
        return {'sbd'}, url
        
    return set(), url

def main():
    input_path = 'assets/data/output.optimized.json'
    output_json_path = 'assets/data/output.optimized_src.json'
    report_path = 'report_src.md'
    
    if not os.path.exists(input_path):
        print(f"Error: {input_path} not found.")
        return

    print(f"Loading data from {input_path}...")
    with open(input_path, 'r') as f:
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
    
    uncategorized_sources = []
    matrix_without_mtx = []
    matrix_with_miller = []
    
    print(f"Processing {total_shows} shows...")

    for show in shows:
        sources = show.get('sources', [])
        total_sources += len(sources)
        show_name = show.get('name', 'Unknown Show')
        show_date = show.get('date', '')
        
        for source in sources:
            cats, url = get_categories_from_url(source)
            
            # Update source 'src' attribute
            if cats:
                # Prioritize single category (it returns a set of 1)
                cat_list = sorted(cats)
                source['src'] = cat_list[0] 
            else:
                source['src'] = '' # Clear it if no URL match found
                
            # Stats
            if not cats:
                uncategorized_sources.append({
                    'date': show_date,
                    'show': show_name,
                    'id': source.get('id', '?'),
                    'url': url
                })
            
            for cat in cats:
                if cat in category_counts:
                    category_counts[cat] += 1
                else:
                    category_counts[cat] = 1
                    
            # Check: Matrix src without 'mtx' in URL
            if 'matrix' in cats:
                if 'mtx' not in url:
                    matrix_without_mtx.append({
                        'date': show_date,
                        'show': show_name,
                        'id': source.get('id', '?'),
                        'url': url,
                        'cats': source['src']
                    })
                # Check: Matrix with 'miller' in URL
                if 'miller' in url:
                    matrix_with_miller.append({
                        'date': show_date,
                        'show': show_name,
                        'id': source.get('id', '?'),
                        'url': url
                    })

    # Save Update JSON
    print(f"Saving updated JSON to {output_json_path}...")
    with open(output_json_path, 'w') as f:
        json.dump(shows, f, separators=(',', ':'))

    # Generate Report
    print(f"Generating report at {report_path}...")
    with open(report_path, 'w') as f:
        f.write("# Source Categorization Report (URL Only)\n\n")
        f.write(f"**Total Shows:** {total_shows}  \n")
        f.write(f"**Total Sources:** {total_sources}  \n")
        f.write(f"**Method:** Single category per source driven by URL keywords. `src` updated.\n\n")
        
        f.write("## Distribution\n")
        f.write("| Category | Count | Percentage |\n")
        f.write("|---|---|---|\n")
        
        sorted_cats = sorted(category_counts.items(), key=lambda x: x[1], reverse=True)
        for cat, count in sorted_cats:
            percentage = (count / total_sources * 100) if total_sources > 0 else 0
            f.write(f"| **{cat.upper()}** | {count} | {percentage:.1f}% |\n")
            
        f.write("\n")
        f.write(f"- **Uncategorized Sources:** {len(uncategorized_sources)}\n")
        f.write(f"- **Matrix Sources without 'mtx' in URL:** {len(matrix_without_mtx)}\n")
        f.write(f"- **Matrix Sources with 'miller' in URL:** {len(matrix_with_miller)}\n\n")

        f.write("\n## Matrix Sources without 'mtx' in URL\n")
        if matrix_without_mtx:
            f.write(f"Found {len(matrix_without_mtx)} sources.\n\n")
            f.write("| Date | Show Name | Source ID | Categories | URL |\n")
            f.write("|---|---|---|---|---|\n")
            for item in matrix_without_mtx:
                f.write(f"| {item['date']} | {item['show']} | {item['id']} | {item['cats']} | {item['url']} |\n")
        else:
            f.write("None found.\n")

        f.write("\n## Matrix Sources with 'miller' in URL\n")
        if matrix_with_miller:
            f.write(f"Found {len(matrix_with_miller)} sources.\n\n")
            f.write("| Date | Show Name | Source ID | URL |\n")
            f.write("|---|---|---|---|\n")
            for item in matrix_with_miller:
                f.write(f"| {item['date']} | {item['show']} | {item['id']} | {item['url']} |\n")
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

    print("Done.")

if __name__ == "__main__":
    main()
