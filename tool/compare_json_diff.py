import json
import argparse
import sys
from collections import defaultdict

def detailed_source_diff(s_old, s_new):
    diffs = []
    # Keys
    all_keys = set(s_old.keys()) | set(s_new.keys())
    for k in all_keys:
        if k == 'sets' or k == 'source_sets':
            continue # Handle separately
        
        v_old = s_old.get(k)
        v_new = s_new.get(k)
        if v_old != v_new:
            diffs.append(f"Field '{k}': '{v_old}' -> '{v_new}'")
            
    # Sets
    sets_old = s_old.get('sets') or s_old.get('source_sets') or []
    sets_new = s_new.get('sets') or s_new.get('source_sets') or []
    
    if len(sets_old) != len(sets_new):
        diffs.append(f"Sets count: {len(sets_old)} -> {len(sets_new)}")
    
    # Iterate over min length to compare existing sets
    min_len = min(len(sets_old), len(sets_new))
    for i in range(min_len):
        set_o = sets_old[i]
        set_n = sets_new[i]
        
        name_o = set_o.get('n', 'Unknown')
        name_n = set_n.get('n', 'Unknown')
        
        if name_o != name_n:
             diffs.append(f"Set {i} name: '{name_o}' -> '{name_n}'")
        
        tracks_o = set_o.get('t', [])
        tracks_n = set_n.get('t', [])
        
        if len(tracks_o) != len(tracks_n):
            diffs.append(f"Set '{name_n}' track count: {len(tracks_o)} -> {len(tracks_n)}")
            # If counts differ, detailed track list diff might be too noisy, but let's try
            
        min_tracks = min(len(tracks_o), len(tracks_n))
        for j in range(min_tracks):
            t_o = tracks_o[j]
            t_n = tracks_n[j]
            title_o = t_o.get('t')
            title_n = t_n.get('t')
            if title_o != title_n:
                diffs.append(f"Set '{name_n}' Track {j+1}: '{title_o}' -> '{title_n}'")
                
    return diffs

def compare_shows(old_show, new_show):
    diffs = []
    
    # Show Level Fields
    for key in ['name', 'l', 'date', 'artist']:
        old_val = old_show.get(key)
        new_val = new_show.get(key)
        
        if old_val != new_val:
            diffs.append(f"  Show Field '{key}': '{old_val}' -> '{new_val}'")

    # Sources
    old_sources_map = {s['id']: s for s in old_show.get('sources', []) if 'id' in s}
    new_sources_map = {s['id']: s for s in new_show.get('sources', []) if 'id' in s}
    
    all_shnids = sorted(list(set(old_sources_map.keys()) | set(new_sources_map.keys())), key=lambda x: str(x))
    
    for shnid in all_shnids:
        if shnid not in old_sources_map:
            diffs.append(f"  Source {shnid} [ADDED]")
        elif shnid not in new_sources_map:
            diffs.append(f"  Source {shnid} [REMOVED]")
        else:
            s_old = old_sources_map[shnid]
            s_new = new_sources_map[shnid]
            
            # Quick check using sorted dump for hashable content
            if json.dumps(s_old, sort_keys=True) != json.dumps(s_new, sort_keys=True):
                source_diffs = detailed_source_diff(s_old, s_new)
                if source_diffs:
                    diffs.append(f"  Source {shnid} changed:")
                    for sd in source_diffs:
                        diffs.append(f"    - {sd}")
                        
    return diffs

def main():
    parser = argparse.ArgumentParser(description='Compare two optimized JSON files.')
    parser.add_argument('new_file', nargs='?', default='assets/data/output.optimized_src_new.json', help='New JSON file')
    parser.add_argument('old_file', nargs='?', default='assets/data/output.optimized_src.json', help='Old JSON file (reference)')
    
    args = parser.parse_args()
    
    print(f"Comparing NEW: {args.new_file}")
    print(f"       vs OLD: {args.old_file}\n")
    
    try:
        with open(args.old_file, 'r', encoding='utf-8') as f:
            old_data = json.load(f)
    except Exception as e:
        print(f"Error loading {args.old_file}: {e}")
        sys.exit(1)
        
    try:
        with open(args.new_file, 'r', encoding='utf-8') as f:
            new_data = json.load(f)
    except Exception as e:
        print(f"Error loading {args.new_file}: {e}")
        sys.exit(1)

    # Index by date
    old_by_date = defaultdict(list)
    for show in old_data:
        old_by_date[show.get('date', 'UNKNOWN')].append(show)

    new_by_date = defaultdict(list)
    for show in new_data:
        new_by_date[show.get('date', 'UNKNOWN')].append(show)
        
    all_dates = sorted(list(set(old_by_date.keys()) | set(new_by_date.keys())))
    
    total_diffs = 0
    
    for date in all_dates:
        olds = old_by_date[date]
        news = new_by_date[date]
        
        # Determine mapping based on name
        old_map = {}
        for s in olds:
            name = s.get('name', 'Unknown')
            # Handle potential duplicate names on same date by appending index?
            # For now, simplistic map:
            if name in old_map:
                # Append shnids to name to differentiate? 
                # This script is for quick diffs, collision is rare.
                pass 
            old_map[name] = s
            
        new_map = {}
        for s in news:
            name = s.get('name', 'Unknown')
            new_map[name] = s
        
        all_names = sorted(list(set(old_map.keys()) | set(new_map.keys())))
        
        for name in all_names:
            if name not in old_map:
                print(f"[{date}] Show ADDED: '{name}'")
                total_diffs += 1
            elif name not in new_map:
                print(f"[{date}] Show REMOVED: '{name}'")
                total_diffs += 1
            else:
                s_old = old_map[name]
                s_new = new_map[name]
                
                diffs = compare_shows(s_old, s_new)
                if diffs:
                    print(f"[{date}] {name}:")
                    for d in diffs:
                        print(d)
                    total_diffs += 1
                    
    if total_diffs == 0:
        print("No differences found.")
    else:
        print(f"\nTotal shows with differences: {total_diffs}")

if __name__ == "__main__":
    main()
