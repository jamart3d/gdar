import json
import os
import re
from collections import Counter

def normalize_title(title):
    if not title:
        return ""
    # Remove backslash escapes (e.g., \> -> >, \( -> ()
    norm = re.sub(r'\\(.)', r'\1', title)
    # Normalize whitespace
    norm = re.sub(r'\s+', ' ', norm)
    norm = norm.strip()
    return norm.lower()

def audit_duplicates():
    input_file = 'assets/data/output.optimized_oldder_src_cleaned_dupfixed_set_opt.json'
    output_file = 'assets/data/output.optimized_oldder_src_cleaned_dupfixed2_set_opt.json'
    report_file = 'dup_names_audit.md'
    
    if not os.path.exists(input_file):
        print(f"Error: {input_file} not found.")
        return

    REMOVE_VBR = True
    REMOVE_CONSECUTIVE_DUPES = False

    print(f"Loading {input_file}...")
    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)

    report_data = []

    for show in data:
        show_date = show.get('date', 'Unknown')
        show_venue = show.get('venue', 'Unknown')
        
        for source in show.get('sources', []):
            shnid = source.get('id', 'Unknown')
            
            # 1. Flatten tracks for analysis (preserving set info)
            sets = source.get('sets', [])
            flat_tracks = []
            for s in sets:
                for t in s.get('t', []):
                    t['_set_ref'] = s # Temp ref
                    flat_tracks.append(t)
            
            if not flat_tracks:
                continue

            vbr_removed = []
            dupes_found = []
            kept_tracks = []

            # 2. Filter VBR
            non_vbr_tracks = []
            for i, t in enumerate(flat_tracks, 1):
                url = t.get('u', '')
                if REMOVE_VBR and '_vbr.mp3' in url.lower():
                    vbr_removed.append({
                        'idx': i,
                        'title': t.get('t', ''),
                        'dur': t.get('d', 0),
                        'url': url
                    })
                else:
                    non_vbr_tracks.append(t)

            # 3. Filter/Audit Consecutive Dupes
            if non_vbr_tracks:
                prev_track = None
                prev_norm = None
                
                for i, t in enumerate(non_vbr_tracks):
                    curr_norm = normalize_title(t.get('t', ''))
                    curr_url = t.get('u', '')
                    
                    is_dupe = False
                    if prev_track:
                        if curr_norm == prev_norm and curr_norm != "":
                            # User Request: "don't include if dup track names url don't match"
                            prev_url = prev_track.get('u', '')
                            if curr_url == prev_url:
                                is_dupe = True
                    
                    if is_dupe:
                        # Found duplicate
                        dupe_info = {
                            'title': t.get('t', ''),
                            'dur': t.get('d', 0),
                            'url': t.get('u', '')
                        }
                        
                        if REMOVE_CONSECUTIVE_DUPES:
                            dupes_found.append(dupe_info) 
                            # Do not append to kept_tracks, do not update prev_track
                        else:
                            dupes_found.append(dupe_info)
                            kept_tracks.append(t)
                            prev_track = t
                            prev_norm = curr_norm
                    else:
                        kept_tracks.append(t)
                        prev_track = t
                        prev_norm = curr_norm
            else:
                kept_tracks = non_vbr_tracks

            # 4. Reconstruct Sets
            # Clear old tracks from sets
            for s in sets:
                s['t'] = []
            
            # Distribute kept tracks back
            for t in kept_tracks:
                s = t.pop('_set_ref') # Remove temp ref
                s['t'].append(t)
            
            if vbr_removed or dupes_found:
                report_data.append({
                    'date': show_date,
                    'venue': show_venue,
                    'id': shnid,
                    'vbr_count': len(vbr_removed),
                    'dupe_count': len(dupes_found),
                    'vbr_details': vbr_removed,
                    'dupe_details': dupes_found
                })

    # Generate Report
    print(f"Generating report {report_file}...")
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write("# Cleanup & Audit Report\n\n")
        f.write(f"- **Sources Modified/Audited:** {len(report_data)}\n")
        f.write(f"- **Remove VBR:** {'ON' if REMOVE_VBR else 'OFF'}\n")
        f.write(f"- **Remove Consecutive Dupes:** {'ON' if REMOVE_CONSECUTIVE_DUPES else 'OFF (Audit Only)'}\n")
        f.write("\n")
        
        for item in report_data:
            f.write(f"## {item['date']} - {item['venue']} (SHNID: {item['id']})\n")
            
            if item['vbr_details']:
                f.write(f"### Removed {item['vbr_count']} VBR Tracks\n")
                for v in item['vbr_details']:
                    f.write(f"- {v['title']} ({v['dur']}s) [URL: {v['url']}]\n")
                f.write("\n")
            
            if item['dupe_details']:
                action = "Removed" if REMOVE_CONSECUTIVE_DUPES else "Found (Not Removed)"
                f.write(f"### {action} {item['dupe_count']} Consecutive Duplicates\n")
                for d in item['dupe_details']:
                    f.write(f"- {d['title']} ({d['dur']}s) [URL: {d['url']}]\n")
                f.write("\n")

    # Save to output
    print(f"Saving to {output_file}...")
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, separators=(',', ':'))
    
    print("Done.")

if __name__ == '__main__':
    audit_duplicates()
