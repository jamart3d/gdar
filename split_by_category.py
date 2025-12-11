import json
import os

def load_json(filepath):
    print(f"Loading {filepath}...")
    with open(filepath, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_json(data, filepath):
    print(f"Saving {len(data)} shows to {filepath}...")
    with open(filepath, 'w', encoding='utf-8') as f:
        # Use compact separators to minimize file size
        json.dump(data, f, separators=(',', ':'))

def get_categories_for_source(source, full_url, identifier):
    cats = set()
    url_lower = full_url.lower()
    src_type = source.get('src', '').lower()
    id_lower = identifier.lower()

    # --- ULTRA ---
    # Keywords: ultra, ultramatrix, sbd-matrix, healy, ultra.mtx, ultra.matrix
    ultra_keywords = ['ultramatrix', 'sbd-matrix', 'ultra', 'healy', 'ultra.mtx', 'ultra.matrix']
    is_ultra = False
    
    if src_type == 'ultra':
        is_ultra = True
    else:
        for k in ultra_keywords:
            if k in url_lower or k in id_lower:
                is_ultra = True
                break
    
    if is_ultra:
        cats.add('ultra')

    # --- BETTY ---
    if 'betty' in url_lower or 'bbd' in url_lower:
        cats.add('betty')

    # --- MATRIX ---
    # User Rule: "mtx" or "matrix" in path or src type.
    # CRITICAL: Exclude if it contains Ultra specific keywords (sbd-matrix, ultramatrix, etc)
    # UNLESS it is just generic 'mtx'/'matrix' without the ultra qualifiers.
    
    is_matrix = False
    if src_type in ['mtx', 'matrix'] or 'mtx' in url_lower or 'matrix' in url_lower:
        # Check for exclusion
        # We use the same set of keywords that force it into Ultra (except simple 'ultra' or 'healy' might not strictly disqualify matrix? 
        # But user rule was: "ultra filter explicitly captures sbd-matrix... Matrix filter strictly excludes sbd-matrix, ultramatrix..."
        
        # Specific exclusion list from user req:
        exclusion_keywords = ['sbd-matrix', 'ultramatrix', 'ultra.mtx', 'ultra.matrix']
        
        is_excluded = False
        for k in exclusion_keywords:
            if k in url_lower or k in id_lower:
                is_excluded = True
                break
        
        if not is_excluded:
            is_matrix = True
            
    if is_matrix:
        cats.add('mtx')

    # --- DSBD ---
    if 'dsbd' in url_lower:
        cats.add('dsbd')

    # --- FM ---
    if 'fm' in url_lower or 'prefm' in url_lower or 'pre-fm' in url_lower:
        cats.add('fm')

    # --- SBD ---
    if src_type == 'sbd' or 'sbd' in url_lower:
        cats.add('sbd')
        
    return cats

def process_shows(input_path):
    data = load_json(input_path)
    
    # Categories to generate files for
    target_categories = ['ultra', 'betty', 'mtx', 'dsbd', 'fm', 'sbd', 'unk']
    
    # Storage for separated data: { 'ultra': [show1, show2...], ... }
    # Each show in user_category_list will only contain the matching sources.
    categorized_shows = {cat: [] for cat in target_categories}
    
    # Stats
    stats = {cat: {'shows': 0, 'sources': 0} for cat in target_categories}
    
    # Validation / Report Data
    mtx_analysis = []
    ultra_analysis = [] # To track triggers

    for show in data:
        show_base = {k: v for k, v in show.items() if k != 'sources'}
        
        # Temp buckets for this show
        show_buckets = {cat: [] for cat in target_categories} # cat -> list of matching sources
        
        has_gd_track = False
        
        for source in show.get('sources', []):
            identifier = source.get('_d', '')
            base_url = f"https://archive.org/download/{identifier}/" if identifier else ""
            
            # Determine Full URL for checking (use first track usually)
            tracks = source.get('tracks', [])
            if not tracks: 
                continue
                
            first_track = tracks[0]
            # Check for GD tracks (Unk category)
            for t in tracks:
                if t.get('t', t.get('title', '')).lower().startswith('gd'):
                    has_gd_track = True
                    # If any track is GD, this source contributes to UNK? 
                    # Usually UNK is show-level or source-level. usage says "unknown shows".
                    # Let's flag the source as UNK if it has these tracks.
            
            t_url = first_track.get('u', '')
            full_url = t_url
            if base_url and not t_url.startswith('http'):
                full_url = base_url + t_url
            
            # Get Categories
            cats = get_categories_for_source(source, full_url, identifier)
            
            if has_gd_track:
                cats.add('unk')
                
            # Distribute source to buckets
            for cat in cats:
                if cat in show_buckets:
                    show_buckets[cat].append(source)
                    
            # Reporting: Check for overlap in MTX (Validation)
            if 'mtx' in cats:
                # Double check we scraped out the bad ones
                lower_url = full_url.lower()
                lower_id = identifier.lower()
                bad_keys = ['sbd-matrix', 'ultramatrix', 'ultra.mtx', 'ultra.matrix']
                hit = None
                for k in bad_keys:
                    if k in lower_url or k in lower_id:
                        hit = k
                        break
                if hit:
                   mtx_analysis.append(f"WARNING: Found {hit} in MTX source: {show.get('date')} {show.get('venue')} ({source.get('id')})") 
            
            # Reporting: Analyze Ultra Triggers
            if 'ultra' in cats:
                 lower_url = full_url.lower()
                 lower_id = identifier.lower()
                 # Determine what triggered it
                 trigger = "src=ultra" if source.get('src') == 'ultra' else "unknown"
                 
                 ultra_keywords = ['ultramatrix', 'sbd-matrix', 'ultra.mtx', 'ultra.matrix', 'healy', 'ultra']
                 # Check keywords in order of specificity
                 for k in ultra_keywords:
                     if k in lower_url or k in lower_id:
                         trigger = k
                         break
                 
                 # Check if it looks like a plain Matrix (src=mtx/matrix) but got caught?
                 src_type = source.get('src', '').lower()
                 if src_type in ['mtx', 'matrix'] and trigger == 'ultra':
                     # This is the "danger zone". src=mtx and only matched 'ultra' generic keyword.
                     pass 
                     
                 # Add to analysis list
                 ultra_analysis.append(f"{trigger} | {show.get('date')} | {source.get('id')}")
 

        # Add buckets to main lists
        for cat in target_categories:
            sources_for_cat = show_buckets[cat]
            if sources_for_cat:
                # Create a show object with ONLY these sources
                new_show = show_base.copy()
                new_show['sources'] = sources_for_cat
                categorized_shows[cat].append(new_show)
                
                stats[cat]['shows'] += 1
                stats[cat]['sources'] += len(sources_for_cat)

    # Save Files
    output_dir = os.path.dirname(input_path)
    generated_files = []
    
    for cat in target_categories:
        fname = f"output.optimized.{cat}.json"
        fpath = os.path.join(output_dir, fname)
        save_json(categorized_shows[cat], fpath)
        generated_files.append((cat, fname, stats[cat]['shows'], stats[cat]['sources']))

    # Generate Combined Clean JSON (No GD Tracks)
    print("Generating combined clean JSON...")
    clean_shows = []
    for show in data:
        show_has_gd = False
        for source in show.get('sources', []):
            for t in source.get('tracks', []):
                if t.get('t', t.get('title', '')).lower().startswith('gd'):
                    show_has_gd = True
                    break
            if show_has_gd: break
        
        if not show_has_gd:
            clean_shows.append(show)
            
    clean_filename = "output.optimized.combined.no_gd.json"
    clean_path = os.path.join(output_dir, clean_filename)
    save_json(clean_shows, clean_path)

    # Report
    report_path = "report_split_categories.md"
    with open(report_path, 'w', encoding='utf-8') as f:
        f.write("# Category Split Report\n\n")
        f.write(f"**Input File:** `{input_path}`\n\n")
        f.write("| Category | Filename | Shows Count | Sources Count |\n")
        f.write("| :--- | :--- | :--- | :--- |\n")
        
        for cat, fname, shows, srcs in sorted(generated_files):
            f.write(f"| {cat.upper()} | `{fname}` | {shows} | {srcs} |\n")
        f.write("\n")
        
        f.write(f"## Combined File (No GD Tracks)\n")
        f.write(f"- **Filename:** `{clean_filename}`\n")
        f.write(f"- **Shows Count:** {len(clean_shows)}\n\n")
        
        f.write(f"## MTX Analysis: Exclusion Verification\n")
        f.write(f"Checking that 'sbd-matrix', 'ultramatrix', 'ultra.mtx', 'ultra.matrix' are NOT in MTX.\n")
        if mtx_analysis:
             f.write(f"**WARNING:** Found {len(mtx_analysis)} violations!\n")
             for line in mtx_analysis:
                 f.write(f"- {line}\n")
        else:
             f.write("**Success:** No violations found. All excluded keywords are absent from MTX category.\n")
             
        f.write("\n## Ultra Analysis: Trigger Breakdown\n")
        f.write("Trigger | Date | ID\n")
        f.write("--- | --- | ---\n")
        # Summarize triggers
        from collections import Counter
        triggers = [line.split(' | ')[0] for line in ultra_analysis]
        counts = Counter(triggers)
        for t, c in counts.most_common():
             f.write(f"**{t}**: {c}\n")
             
        f.write("\n### Details (First 50)\n")
        for line in ultra_analysis[:50]:
            f.write(f"{line}\n")

    print(f"Done. Report written to {report_path}")

if __name__ == "__main__":
    process_shows('assets/data/output.optimized.json')
