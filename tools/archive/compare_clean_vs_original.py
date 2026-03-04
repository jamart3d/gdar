import json
from collections import Counter

def load_data(filepath):
    try:
        with open(filepath, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"File not found: {filepath}")
        return []

def get_stats(data):
    stats = {
        'total_shows': len(data),
        'total_sources': 0,
        'unique_venues': set(),
        'src_counts': Counter()
    }
    
    for show in data:
        # Venue
        venue = show.get('name', '').strip()
        stats['unique_venues'].add(venue)
        
        # Sources
        sources = show.get('sources', [])
        stats['total_sources'] += len(sources)
        
        # Src Categories
        for source in sources:
            src = source.get('src')
            stats['src_counts'][str(src)] += 1
            
    return stats

import re

def normalize_title(t):
    if not t: return ""
    t = t.lower()
    # Remove leading track numbers, dots, and hyphens: "01. Title" -> "title"
    # Also handle things like "I - Title" or "1- Title"
    t = re.sub(r'^[0-9.\s\-i]+', '', t)
    # Remove all non-alphanumeric characters for maximum fuzziness
    t = re.sub(r'[^a-z0-9]', '', t)
    return t

def get_track_data_full(data):
    # Map (date, show_name, source_id) -> list of (title, set_name, track_num)
    track_map = {}
    for show in data:
        date = show.get('date', '')
        name = show.get('name', '')
        for source in show.get('sources', []):
            sid = source.get('id', '')
            tracks = []
            if 'sets' in source:
                for set_obj in source['sets']:
                    sname = set_obj.get('n', 'Unknown Set')
                    for track in set_obj.get('t', []):
                        tracks.append({
                            't': track.get('t', ''), 
                            's': sname, 
                            'n': track.get('n', 0)
                        })
            elif 'tracks' in source:
                for track in source['tracks']:
                    tracks.append({
                        't': track.get('t', ''), 
                        's': track.get('s', 'Unknown Set'), 
                        'n': track.get('n', 0)
                    })
            
            track_map[(date, name, sid)] = tracks
    return track_map

import difflib

def fix_track_order(org_dict, last_tracks_map):
    fixed_count = 0
    fixed_details = []
    
    for show in org_dict:
        date = show.get('date', '')
        name = show.get('name', '')
        for source in show.get('sources', []):
            sid = source.get('id', '')
            key = (date, name, sid)
            
            if key in last_tracks_map:
                truth_tracks = last_tracks_map[key]
                
                # Get all current tracks
                all_current_tracks = []
                if 'sets' in source:
                    for s in source['sets']:
                        for t in s.get('t', []):
                            all_current_tracks.append(t)
                elif 'tracks' in source:
                    all_current_tracks = source['tracks']
                
                # Current display info (for the report)
                current_info = [f"[{t.get('n', '?')}] {t.get('t', '')}" for t in all_current_tracks]
                renumbered_info = [f"[{i+1}] {t.get('t', '')}" for i, t in enumerate(all_current_tracks)]
                truth_info = [f"[{t['n']}] {t['t']}" for t in truth_tracks]
                
                norm_current = [normalize_title(t.get('t', '')) for t in all_current_tracks]
                norm_truth = [normalize_title(t['t']) for t in truth_tracks]
                
                if norm_current != norm_truth:
                    # REORDER NEEDED
                    fixed_count += 1
                    
                    diff_info = {
                        'key': f"{date} {name} ({sid})",
                        'current_info': current_info,
                        'renumbered_info': renumbered_info,
                        'truth_info': truth_info,
                        'matches': [] 
                    }
                    
                    # Pool for fuzzy matching
                    norm_pool = {}
                    for t in all_current_tracks:
                        nt = normalize_title(t.get('t', ''))
                        if nt not in norm_pool: norm_pool[nt] = []
                        norm_pool[nt].append(t)
                    
                    matched_tracks = set() # Store id(track_obj)
                    new_sets_dict = {} 
                    set_order = []
                    used_indices = {} 
                    
                    # New sequence counter for "gap-free" numbering
                    next_num = 1
                    
                    for t_entry in truth_tracks:
                        t_title = t_entry['t']
                        sname = t_entry['s']
                        
                        if sname not in new_sets_dict:
                            new_sets_dict[sname] = []
                            set_order.append(sname)
                        
                        nt = normalize_title(t_title)
                        idx = used_indices.get(nt, 0)
                        
                        match_track = None
                        match_icon = "❌"
                        
                        if nt in norm_pool and idx < len(norm_pool[nt]):
                            match_track = norm_pool[nt][idx]
                            used_indices[nt] = idx + 1
                            match_icon = "✅"
                        else:
                            available_keys = [k for k in norm_pool if used_indices.get(k, 0) < len(norm_pool[k])]
                            f_matches = difflib.get_close_matches(nt, available_keys, n=1, cutoff=0.6)
                            if f_matches:
                                nt_fuzzy = f_matches[0]
                                f_idx = used_indices.get(nt_fuzzy, 0)
                                match_track = norm_pool[nt_fuzzy][f_idx]
                                used_indices[nt_fuzzy] = f_idx + 1
                                match_icon = "🟡"
                        
                        if match_track:
                            # Apply fixed sequential number
                            match_track['n'] = next_num
                            next_num += 1
                            new_sets_dict[sname].append(match_track)
                            matched_tracks.add(id(match_track))
                            diff_info['matches'].append((match_icon, match_track.get('t', '')))
                        else:
                            diff_info['matches'].append((match_icon, "-"))
                    
                    # Orphan Handling
                    orphans = [t for t in all_current_tracks if id(t) not in matched_tracks]
                    if orphans:
                        target_set = set_order[-1] if set_order else "Set 1"
                        if target_set not in new_sets_dict:
                            new_sets_dict[target_set] = []
                            set_order.append(target_set)
                        for t in orphans:
                            t['n'] = next_num
                            next_num += 1
                            new_sets_dict[target_set].append(t)
                    
                    # Reconstruct structure
                    final_sets = []
                    for sname in set_order:
                        if new_sets_dict[sname]:
                            final_sets.append({
                                "n": sname,
                                "t": new_sets_dict[sname]
                            })
                    source['sets'] = final_sets
                    if 'tracks' in source: del source['tracks']
                    fixed_details.append(diff_info)
                    
    return fixed_count, fixed_details

def main():
    original_file = 'assets/data/output.optimized_src_last.json'
    new_file = 'assets/data/output.optimized_src.json'
    report_file = 'comparison_report.md'
    fixed_file = 'assets/data/output.optimized_src_fixed.json'
    
    print(f"Loading Original (Truth): {original_file}")
    org_data = load_data(original_file)
    print(f"Loading New (To Fix): {new_file}")
    new_data = load_data(new_file)
    
    org_stats = get_stats(org_data)
    new_stats = get_stats(new_data)
    last_tracks_map = get_track_data_full(org_data)
    
    fixed_count, fixed_details = fix_track_order(new_data, last_tracks_map)
    
    report_lines = []
    report_lines.append("# 📊 Comparison & Fix Report\n")
    report_lines.append("> [!NOTE]")
    report_lines.append(f"> **Truth Source:** `{original_file}`")
    report_lines.append(f"> **Target File:** `{new_file}`")
    report_lines.append(f"> **Fixed Output:** `{fixed_file}`")
    report_lines.append("> **Action:** Fixed track order and sequentialized track numbers to remove gaps.\n")
    
    report_lines.append("## 📈 1. Metadata Overview\n")
    w1, w2, w3, w4 = 25, 12, 12, 12
    report_lines.append(f"| {'Metric':<{w1}} | {'Original':>{w2}} | {'New':>{w3}} | {'Difference':<{w4}} |")
    report_lines.append(f"| :{'-'*(w1-1)} | {'-'*(w2-1)}: | {'-'*(w3-1)}: | :{'-'*(w4-1)} |")
    
    diff_shows = new_stats['total_shows'] - org_stats['total_shows']
    s_diff = f"+{diff_shows}" if diff_shows > 0 else str(diff_shows)
    report_lines.append(f"| {'**Total Shows**':<{w1}} | {org_stats['total_shows']:>{w2}} | {new_stats['total_shows']:>{w3}} | `{s_diff:<10}` |")
    
    diff_sources = new_stats['total_sources'] - org_stats['total_sources']
    src_diff = f"+{diff_sources}" if diff_sources > 0 else str(diff_sources)
    report_lines.append(f"| {'**Total Sources**':<{w1}} | {org_stats['total_sources']:>{w2}} | {new_stats['total_sources']:>{w3}} | `{src_diff:<10}` |")
    
    org_venues = len(org_stats['unique_venues'])
    new_venues = len(new_stats['unique_venues'])
    diff_venues = new_venues - org_venues
    v_diff = f"+{diff_venues}" if diff_venues > 0 else str(diff_venues)
    report_lines.append(f"| {'**Unique Venues**':<{w1}} | {org_venues:>{w2}} | {new_venues:>{w3}} | `{v_diff:<10}` |\n")
    
    report_lines.append("## 🛠 2. Track Order Rehabilitation (Fuzzy + Gap Fix)\n")
    report_lines.append(f"**{fixed_count}** sources were found with mismatched track sequences. Report includes sequential renumbering impact.\n")
    
    if fixed_details:
        report_lines.append("### 🔍 Detailed Diff Examples\n")
        
        for detail in fixed_details[:5]:
            report_lines.append(f"#### 🎵 {detail['key']}")
            
            # Determine column widths
            c1_w = 4
            c2_w = max([len(x) for x in detail['current_info'][:15]] + [len("Original (Current)")]) + 2
            c3_w = max([len(x) for x in detail['renumbered_info'][:15]] + [len("Renumbered (Gap Fix)")]) + 2
            c4_w = max([len(x) for x in detail['truth_info'][:15]] + [len("Truth (Target)")]) + 2
            c5_w = 7
            
            header = f"| {'#':<{c1_w}} | {'Original (Current)':<{c2_w}} | {'Renumbered (Gap Fix)':<{c3_w}} | {'Truth (Target)':<{c4_w}} | {'Match':^{c5_w}} |"
            sep = f"| :{'-'*(c1_w-1)} | :{'-'*(c2_w-1)} | :{'-'*(c3_w-1)} | :{'-'*(c4_w-1)} | {('-'*(c5_w-2)).center(c5_w, ':')} |"
            report_lines.append(header)
            report_lines.append(sep)
            
            display_limit = 15
            max_rows = max(len(detail['current_info']), len(detail['truth_info']))
            
            for i in range(min(max_rows, display_limit)):
                cur = detail['current_info'][i] if i < len(detail['current_info']) else "-"
                ren = detail['renumbered_info'][i] if i < len(detail['renumbered_info']) else "-"
                tru = detail['truth_info'][i] if i < len(detail['truth_info']) else "-"
                icon = detail['matches'][i][0] if i < len(detail['matches']) else " "
                
                report_lines.append(f"| {i+1:<{c1_w}} | {cur:<{c2_w}} | {ren:<{c3_w}} | {tru:<{c4_w}} | {icon:^{c5_w}} |")
            
            if max_rows > display_limit:
                report_lines.append(f"| {'...':<{c1_w}} | {'...':<{c2_w}} | {'...':<{c3_w}} | {'...':<{c4_w}} | {'...':^{c5_w}} |")
            report_lines.append("\n")
            
        report_lines.append("### 📂 All Reordered Sources (Grouped)\n")
        report_lines.append("> Legend: ✅ Exact/Normalized, 🟡 Fuzzy Match, ❌ Unmatched Truth Entry\n")
        by_year = {}
        for d in fixed_details:
            year = d['key'][:4]
            if year not in by_year: by_year[year] = []
            by_year[year].append(d['key'])
        for year in sorted(by_year.keys()):
            report_lines.append(f"#### {year}")
            report_lines.append(", ".join([f"`{k.split(' ', 1)[1]}`" for k in by_year[year]]))
            report_lines.append("")
            
    report_lines.append("\n## 📋 3. Source Category Audit\n")
    report_lines.append(f"| {'Category':<{w1}} | {'Original':>{w2}} | {'New':>{w3}} | {'Diff':<{w4}} |")
    report_lines.append(f"| :{'-'*(w1-1)} | {'-'*(w2-1)}: | {'-'*(w3-1)}: | :{'-'*(w4-1)} |")
    
    all_keys = set(org_stats['src_counts'].keys()) | set(new_stats['src_counts'].keys())
    sorted_keys = sorted(all_keys, key=lambda k: new_stats['src_counts'][k], reverse=True)
    for k in sorted_keys:
        v_org = org_stats['src_counts'][k]
        v_new = new_stats['src_counts'][k]
        diff = v_new - v_org
        d_str = f"+{diff}" if diff > 0 else str(diff)
        report_lines.append(f"| {k:<{w1}} | {v_org:>{w2}} | {v_new:>{w3}} | `{d_str:<10}` |")
    
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write("\n".join(report_lines))
    print(f"Report saved to {report_file}")
    
    with open(fixed_file, 'w', encoding='utf-8') as f:
        json.dump(new_data, f, separators=(',', ':'))
    print(f"Fixed JSON saved to {fixed_file}")

if __name__ == "__main__":
    main()
