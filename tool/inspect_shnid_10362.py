import json
import os

def fix_soundcheck_10362(input_file, target_id, output_json, output_report):
    print(f"Reading from {input_file}...")
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"Error: Input file {input_file} not found.")
        return

    stats = {
        'tracks_moved': 0,
        'source_found': False
    }

    report_lines = []
    report_lines.append(f"# Soundcheck Fix Report: SHNID {target_id}\n")
    report_lines.append(f"- **Input File**: `{input_file}`")
    report_lines.append(f"- **Output JSON**: `{output_json}`\n")

    for show in data:
        for source in show.get('sources', []):
            if str(source.get('id')) == str(target_id):
                stats['source_found'] = True
                sets = source.get('sets', [])
                
                sc_tracks = []
                remaining_sets = []
                
                for s in sets:
                    set_name = s.get('n', 'Unknown Set')
                    sc_in_this_set = []
                    other_in_this_set = []
                    
                    for t in s.get('t', []):
                        if "Soundcheckt" in t.get('u', ''):
                            sc_tracks.append(t)
                            sc_in_this_set.append(t)
                        else:
                            other_in_this_set.append(t)
                    
                    if other_in_this_set:
                        remaining_sets.append({
                            'n': set_name,
                            't': other_in_this_set
                        })
                    
                    if sc_in_this_set:
                        report_lines.append(f"- Identified {len(sc_in_this_set)} soundcheck tracks in `{set_name}`")
                
                if sc_tracks:
                    stats['tracks_moved'] = len(sc_tracks)
                    # Create the Sc set at the beginning
                    new_sets = [{'n': 'Sc', 't': sc_tracks}] + remaining_sets
                    source['sets'] = new_sets
                    
                    report_lines.append(f"\n## New Tracklist Structure for {target_id}\n")
                    counter = 1
                    for s in new_sets:
                        report_lines.append(f"### {s['n']}")
                        for t in s['t']:
                            report_lines.append(f"{counter}. {t.get('t')} (`{t.get('u')}`)")
                            counter += 1
                        report_lines.append("")
                break
        if stats['source_found']:
            break

    if not stats['source_found']:
        print(f"Error: SHNID {target_id} not found.")
        return

    print(f"Saving new JSON to {output_json}...")
    with open(output_json, 'w', encoding='utf-8') as f:
        json.dump(data, f, separators=(',', ':'), ensure_ascii=False)

    print(f"Saving report to {output_report}...")
    with open(output_report, 'w', encoding='utf-8') as f:
        f.write("\n".join(report_lines))

    print(f"Done. Moved {stats['tracks_moved']} tracks.")

if __name__ == "__main__":
    input_path = 'assets/data/output.optimized_src_fixed_e1.json'
    target_id = "10362"
    output_json = 'assets/data/output.optimized_src_fixed_sc.json'
    output_report = 'fix_sc_10362_report.md'
    
    fix_soundcheck_10362(input_path, target_id, output_json, output_report)
