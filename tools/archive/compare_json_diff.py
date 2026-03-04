import json
import argparse
import sys
from collections import defaultdict

def format_markdown_table(headers, rows):
    if not rows:
        return ""
    
    # Calculate max width for each column
    col_widths = [len(h) for h in headers]
    for row in rows:
        for i, cell in enumerate(row):
            col_widths[i] = max(col_widths[i], len(str(cell)))
            
    # Build the table
    header_row = "| " + " | ".join(h.ljust(col_widths[i]) for i, h in enumerate(headers)) + " |"
    sep_row = "| " + " | ".join("-" * col_widths[i] for i in range(len(headers))) + " |"
    
    table_lines = [header_row, sep_row]
    for row in rows:
        formatted_row = "| " + " | ".join(str(cell).ljust(col_widths[i]) for i, cell in enumerate(row)) + " |"
        table_lines.append(formatted_row)
        
    return "\n".join(table_lines) + "\n"

def detailed_source_diff(s_old, s_new):
    diffs = []
    # Keys
    all_keys = sorted(list(set(s_old.keys()) | set(s_new.keys())))
    for k in all_keys:
        if k in ['sets', 'source_sets', 'id']:
            continue # Handle separately or skip
        
        v_old = s_old.get(k)
        v_new = s_new.get(k)
        if v_old != v_new:
            diffs.append((f"Source Field: `{k}`", v_old if v_old is not None else "[Missing]", f"**{v_new}**" if v_new is not None else "**[Missing]**"))
            
    # Sets
    sets_old = s_old.get('sets') or s_old.get('source_sets') or []
    sets_new = s_new.get('sets') or s_new.get('source_sets') or []
    
    if len(sets_old) != len(sets_new):
        diffs.append(("Total Sets", len(sets_old), f"**{len(sets_new)}**"))
    
    # Iterate over min length to compare existing sets
    min_len = min(len(sets_old), len(sets_new))
    for i in range(min_len):
        set_o = sets_old[i]
        set_n = sets_new[i]
        
        name_o = set_o.get('n', 'Unknown')
        name_n = set_n.get('n', 'Unknown')
        
        if name_o != name_n:
             diffs.append((f"Set {i+1} Name", name_o, f"**{name_n}**"))
        
        tracks_o = set_o.get('t', [])
        tracks_n = set_n.get('t', [])
        
        if len(tracks_o) != len(tracks_n):
            diffs.append((f"Set '{name_n}' Track Count", len(tracks_o), f"**{len(tracks_n)}**"))
            
        min_tracks = min(len(tracks_o), len(tracks_n))
        for j in range(min_tracks):
            t_o = tracks_o[j]
            t_n = tracks_n[j]
            title_o = t_o.get('t')
            title_n = t_n.get('t')
            if title_o != title_n:
                diffs.append((f"Set '{name_n}' Track {j+1}", title_o, f"**{title_n}**"))
                
    return diffs

def compare_shows(old_show, new_show):
    show_diffs = []
    
    # Show Level Fields
    for key in ['name', 'l', 'date', 'artist']:
        old_val = old_show.get(key)
        new_val = new_show.get(key)
        
        if old_val != new_val:
            show_diffs.append((f"Show Field: `{key}`", old_val, f"**{new_val}**"))

    # Sources
    old_sources_map = {s['id']: s for s in old_show.get('sources', []) if 'id' in s}
    new_sources_map = {s['id']: s for s in new_show.get('sources', []) if 'id' in s}
    
    all_shnids = sorted(list(set(old_sources_map.keys()) | set(new_sources_map.keys())), key=lambda x: str(x))
    
    source_results = {}
    
    for shnid in all_shnids:
        if shnid not in old_sources_map:
            source_results[shnid] = [("Source Status", "[Not Present]", "**[ADDED]**")]
        elif shnid not in new_sources_map:
            source_results[shnid] = [("Source Status", "[Present]", "**[REMOVED]**")]
        else:
            s_old = old_sources_map[shnid]
            s_new = new_sources_map[shnid]
            
            # Quick check using sorted dump
            if json.dumps(s_old, sort_keys=True) != json.dumps(s_new, sort_keys=True):
                source_diffs = detailed_source_diff(s_old, s_new)
                if source_diffs:
                    source_results[shnid] = source_diffs
                        
    return show_diffs, source_results

def main():
    parser = argparse.ArgumentParser(description='Compare two optimized JSON files.')
    parser.add_argument('new_file', nargs='?', default='assets/data/output.optimized_src_new.json', help='New JSON file')
    parser.add_argument('old_file', nargs='?', default='assets/data/output.optimized_src.json', help='Old JSON file (reference)')
    parser.add_argument('--report', help='Path to save Markdown report file')
    
    args = parser.parse_args()
    
    output_lines = []
    
    def log(msg):
        print(msg)
        output_lines.append(msg)
    
    log(f"# JSON Comparison Report\n")
    log(f"This report compares codebase changes between two Grateful Dead show data files.")
    log(f"- **OLD**: `{args.old_file}`")
    log(f"- **NEW**: `{args.new_file}`\n")
    
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
    
    total_diff_shows = 0
    
    headers = ["Component/Field", "Old Value (OLD)", "New Value (NEW)"]
    
    for date in all_dates:
        olds = old_by_date[date]
        news = new_by_date[date]
        
        old_map = {s.get('name', 'Unknown'): s for s in olds}
        new_map = {s.get('name', 'Unknown'): s for s in news}
        
        all_names = sorted(list(set(old_map.keys()) | set(new_map.keys())))
        
        for name in all_names:
            if name not in old_map:
                log(f"## [{date}] {name} (ADDED)")
                log(format_markdown_table(headers, [("Show", "[Not Present]", "**[ADDED]**")]))
                total_diff_shows += 1
            elif name not in new_map:
                log(f"## [{date}] {name} (REMOVED)")
                log(format_markdown_table(headers, [("Show", "[Present]", "**[REMOVED]**")]))
                total_diff_shows += 1
            else:
                show_diffs, source_results = compare_shows(old_map[name], new_map[name])
                
                if show_diffs or source_results:
                    log(f"## [{date}] {name}")
                    total_diff_shows += 1
                    
                    if show_diffs:
                        log(f"### Show Metadata Changes")
                        log(format_markdown_table(headers, show_diffs))
                        
                    for shnid, s_diffs in source_results.items():
                        log(f"### Source: `{shnid}` Changes")
                        log(format_markdown_table(headers, s_diffs))
                    
                    log("---\n")
                    
    if total_diff_shows == 0:
        log("\n**No differences found between the datasets.**")
    else:
        log(f"\n**Total shows with differences identified:** {total_diff_shows}")

    if args.report:
        try:
            with open(args.report, 'w', encoding='utf-8') as f:
                f.write("\n".join(output_lines) + "\n")
            print(f"\nComparison complete. Report saved to: {args.report}")
        except Exception as e:
            print(f"Error saving report to {args.report}: {e}")

if __name__ == "__main__":
    main()
