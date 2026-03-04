import json
import os
import re

def normalize_title(t):
    if not t: return ""
    t = t.lower()
    t = re.sub(r'^[0-9\.\s\-]+', '', t) # Remove leading numbers/dots
    t = re.sub(r'[^a-z0-9]', '', t)    # Remove punctuation
    return t

def normalize_tracks():
    input_file = 'assets/data/output.optimized_src.json'
    truth_file = 'assets/data/output.optimized_src_last.json'
    output_file = 'assets/data/output.optimized_src_normalized.json'
    report_file = 'track_normalization_report.md'

    if not os.path.exists(input_file):
        print(f"Error: {input_file} not found.")
        return

    print(f"Loading {input_file}...")
    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)

    truth_map = {}
    if os.path.exists(truth_file):
        print(f"Loading Truth Data: {truth_file}...")
        with open(truth_file, 'r', encoding='utf-8') as f:
            truth_data = json.load(f)
            for show in truth_data:
                for src in show.get('sources', []):
                    sid = src.get('id')
                    tracks = []
                    if 'sets' in src:
                        for s_obj in src['sets']:
                            for t in s_obj.get('t', []):
                                tracks.append((normalize_title(t.get('t')), t.get('n')))
                    elif 'tracks' in src:
                        for t in src['tracks']:
                            tracks.append((normalize_title(t.get('t')), t.get('n')))
                    truth_map[sid] = tracks

    changes = []
    total_sources = 0
    fixed_sources = 0
    skip_1_pattern_count = 0

    for show in data:
        date = show.get('date', 'Unknown Date')
        name = show.get('name', 'Unknown Show')
        for source in show.get('sources', []):
            total_sources += 1
            sid = str(source.get('id', 'Unknown ID'))
            
            track_objs = []
            if 'sets' in source:
                for s_obj in source['sets']:
                    for t in s_obj.get('t', []):
                        track_objs.append(t)
            elif 'tracks' in source:
                track_objs = source['tracks']
            
            if not track_objs:
                continue

            # Check for gaps/non-sequential
            original_nums = [t.get('n') for t in track_objs]
            expected_nums = list(range(1, len(track_objs) + 1))
            
            if original_nums != expected_nums:
                fixed_sources += 1
                
                # Check for "just skip 1 number" pattern (Increment of 2)
                is_skip_1 = False
                divergences = []
                if len(original_nums) > 1:
                    diffs = [original_nums[i] - original_nums[i-1] for i in range(1, len(original_nums))]
                    is_skip_1 = all(d == 2 for d in diffs)
                    if is_skip_1:
                        skip_1_pattern_count += 1
                    else:
                        # Record where it diverged (indices where diff != 2)
                        for i, d in enumerate(diffs):
                            if d != 2:
                                divergences.append(i + 1) # index in original_nums

                # Merged track list for irregular sources
                merged_tracks = []
                if not is_skip_1 and sid in truth_map:
                    t_tracks = truth_map[sid] # List of (norm_title, n)
                    new_tracks_info = [(normalize_title(t['t']), t['n'], t['t']) for t in track_objs]
                    
                    matched_new_indices = set()
                    for tt, tn in t_tracks:
                        # Find match in new_tracks_info
                        match = None
                        for idx, (nt, nn, nt_raw) in enumerate(new_tracks_info):
                            if idx not in matched_new_indices and nt == tt:
                                match = (nt, nn, nt_raw, idx)
                                matched_new_indices.add(idx)
                                break
                        
                        if match:
                            merged_tracks.append({
                                'title': match[2],
                                'original': match[1],
                                'normalized': '?', # Will fill in
                                'truth': tn,
                                'status': '✅' if match[1] == tn else '🚩'
                            })
                        else:
                            merged_tracks.append({
                                'title': f"[MISSING] {tt}",
                                'original': "-",
                                'normalized': "-",
                                'truth': tn,
                                'status': '❌'
                            })
                    
                    # Append unmatched new tracks
                    for idx, (nt, nn, nt_raw) in enumerate(new_tracks_info):
                        if idx not in matched_new_indices:
                            merged_tracks.append({
                                'title': nt_raw,
                                'original': nn,
                                'normalized': '?',
                                'truth': "-",
                                'status': '➕'
                            })
                
                changes.append({
                    'id': f"{date} {name} ({sid})",
                    'sid': sid,
                    'before': original_nums,
                    'after': expected_nums,
                    'titles': [t.get('t', '') for t in track_objs],
                    'is_skip_1': is_skip_1,
                    'divergences': divergences,
                    'merged': merged_tracks if merged_tracks else None
                })
                # Apply changes (sequential numbering 1, 2, 3...)
                for idx, t_obj in enumerate(track_objs):
                    t_obj['n'] = idx + 1

    # Save Normalized JSON
    print(f"Saving normalized data to {output_file}...")
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, separators=(',', ':'))

    # Build Report
    print(f"Generating report {report_file}...")
    changes.sort(key=lambda x: (x['is_skip_1'], x['id']))
    irregular_count = fixed_sources - skip_1_pattern_count
    
    report = [
        "# 🔢 Track Number Normalization Report\n",
        f"> [!IMPORTANT]",
        f"> This script fixes sequential gaps in track numbers within `assets/data/output.optimized_src.json`.",
        f"> It does **not** reorder tracks; it simply ensures they are numbered 1, 2, 3... in their existing order.\n",
        f"- **Input File:** `{input_file}`",
        f"- **Output File:** `{output_file}`",
        f"- **Truth File:** `{truth_file}`\n",
        "## 📈 Summary Statistics\n",
        f"| Metric | Count |",
        f"| :--- | :--- |",
        f"| Total Sources Scanned | {total_sources} |",
        f"| Sources Requiring Normalization | **{fixed_sources}** |",
        f"| - 'Skip-1' Pattern (step=2) | {skip_1_pattern_count} |",
        f"| - Irregular Patterns (Non-standard gaps) | **{irregular_count}** |\n",
        "## ⚠️ Irregular Sources (Require Review)\n",
        f"The following {irregular_count} sources had gaps that did not follow the standard 'skip-1' increment. "
        "The **Truth (Last)** column shows track numbers from the truth file for reference.\n"
    ]

    for c in [x for x in changes if not x['is_skip_1']]:
        report.append(f"### 🎵 {c['id']} (Irregular Pattern 🚩)")
        
        if c['merged']:
            # Use merged list
            max_t_len = max([len(m['title']) for m in c['merged']] + [len("Track Title")]) + 2
            report.append(f"| # | Original | Truth (Last) | Track Title | Status |")
            report.append(f"| :-- | :--------- | :----------- | :{'--'*(max_t_len//2)} | :----: |")
            for i, m in enumerate(c['merged']):
                report.append(f"| {i+1:<3} | {str(m['original']):<10} | {str(m['truth']):<12} | {m['title']:<{max_t_len}} | {m['status']:^8} |")
        else:
            # Fallback for no merged data
            max_t_len = max([len(t) for t in c['titles']] + [len("Track Title")]) + 2
            report.append(f"| # | Original | Normalized | Track Title | Status |")
            report.append(f"| :-- | :--------- | :--------- | :{'--'*(max_t_len//2)} | :----: |")
            for i in range(len(c['before'])):
                b, a, t = c['before'][i], c['after'][i], c['titles'][i]
                status = "🚩" if b != a else "✅"
                # Flag divergence if interval isn't 2 (if it was mostly skip-1)
                if i > 0 and (b - c['before'][i-1] != 2):
                    status = "⚠️ Div"
                report.append(f"| {i+1:<3} | {str(b):<10} | {str(a):<10} | {t:<{max_t_len}} | {status:^8} |")
        report.append("\n")

    report.append("## ⏭️ Standard 'Skip-1' Sources\n")
    report.append(f"The following {skip_1_pattern_count} sources followed the common increment-by-2 pattern.\n")

    for c in [x for x in changes if x['is_skip_1']]:
        report.append(f"### 🎵 {c['id']} (Skip-1 ⏭️)")
        max_t_len = max([len(t) for t in c['titles']] + [len("Track Title")]) + 2
        report.append(f"| {'#':<3} | {'Original':<10} | {'Normalized':<10} | {'Track Title':<{max_t_len}} | {'Status':^8} |")
        report.append(f"| :-- | :--------- | :--------- | :{'--'*(max_t_len//2)} | :----: |")
        for i in range(len(c['before'])):
            b, a, t = c['before'][i], c['after'][i], c['titles'][i]
            status = "🔄" if b != a else "✅"
            report.append(f"| {i+1:<3} | {str(b):<10} | {str(a):<10} | {t:<{max_t_len}} | {status:^8} |")
        report.append("\n")

    with open(report_file, 'w', encoding='utf-8') as f:
        f.write("\n".join(report))
    
    print(f"Normalization complete. {fixed_sources} sources fixed.")

if __name__ == "__main__":
    normalize_tracks()
