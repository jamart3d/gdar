import json
import os
from collections import Counter

INPUT_FILE = 'assets/data/output.optimized_src_vbr_cleaned.json'
OUTPUT_FILE = 'assets/data/output.optimized_src_fixed.json'
REPORT_FILE = 'dup_fix_report.md'

def main():
    if not os.path.exists(INPUT_FILE):
        print(f"Error: {INPUT_FILE} not found.")
        return

    print(f"Loading {INPUT_FILE}...")
    try:
        with open(INPUT_FILE, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        print(f"Error reading JSON: {e}")
        return

    fixed_sources = []

    import re
    def normalize_title(title):
        if not title:
            return ""
        # Remove backslash escapes (e.g., \> -> >, \( -> ()
        norm = re.sub(r'\\(.)', r'\1', title)
        # Normalize whitespace
        norm = re.sub(r'\s+', ' ', norm)
        norm = norm.strip()
        # Remove trailing transition markers like '-', '\' or ';'
        norm = re.sub(r'\s*[-\\;]+$', '', norm)
        return norm.strip()

    for show in data:
        date = show.get('date', 'Unknown')
        venue = show.get('venue', 'Unknown Venue')
        
        for source in show.get('sources', []):
            shnid = source.get('id', 'Unknown')
            tracks = source.get('tracks', [])
            
            # Create list of (normalized_name, duration) tuples
            track_identities = [(normalize_title(t.get('t')), t.get('d', 0)) for t in tracks if t.get('t')]
            
            if not track_identities:
                continue

            # RELAXED FILTER: Fix if total tracks are >= 1.5x unique tracks.
            # Now checking distinct (Normalized Name, Duration) pairs.
            unique_identities = set(track_identities)
            
            if len(track_identities) >= 1.5 * len(unique_identities):
                # Construct unique_tracks list maintaining order, EXCLUDING all VBR tracks.
                unique_tracks = []
                seen_identities = set()
                removed_names = []
                
                for t in tracks:
                    norm_name = normalize_title(t.get('t'))
                    t_dur = t.get('d', 0)
                    identity = (norm_name, t_dur)
                    url = t.get('u', '')
                    is_vbr = "_vbr.mp3" in url.lower()
                    
                    if is_vbr:
                        removed_names.append(f"{t.get('t', '').strip()} ({t_dur}s) [URL: {url}]")
                        continue

                    if identity not in seen_identities:
                        unique_tracks.append(t)
                        seen_identities.add(identity)
                    else:
                        # Identical Name+Duration already added from a previous non-VBR entry
                        removed_names.append(f"{t.get('t', '').strip()} ({t_dur}s) [URL: {url}]")
                
                # Update the source's tracks with the deduplicated non-VBR set
                source['tracks'] = unique_tracks
                
                fixed_sources.append({
                    'date': date,
                    'shnid': shnid,
                    'original_count': len(tracks),
                    'new_count': len(unique_tracks),
                    'tracks_removed': len(tracks) - len(unique_tracks),
                    'cleaned_tracks': [f"{t.get('t', '').strip()} ({t.get('d', 0)}s) [URL: {t.get('u', 'N/A')}]" for t in unique_tracks],
                    'removed_names': removed_names
                })

    print(f"Fixed {len(fixed_sources)} sources.")
    
    print(f"Saving to {OUTPUT_FILE}...")
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, separators=(',', ':'))

    print(f"Generating report {REPORT_FILE}...")
    with open(REPORT_FILE, 'w', encoding='utf-8') as f:
        f.write("# Duplicate Track Fix Report\n\n")
        f.write(f"**Total Sources Fixed:** {len(fixed_sources)}\n\n")
        
        for item in fixed_sources:
            f.write(f"## {item['date']} (SHNID: {item['shnid']})\n")
            f.write(f"- **Original Count:** {item['original_count']}\n")
            f.write(f"- **New Count:** {item['new_count']}\n")
            f.write(f"- **Tracks Removed:** {item['tracks_removed']}\n\n")
            
            f.write("<details>\n")
            f.write("<summary>View Cleaned Track List</summary>\n\n")
            for i, t in enumerate(item['cleaned_tracks'], 1):
                f.write(f"{i}. {t}\n")
            f.write("\n</details>\n\n")
            
            f.write("<details>\n")
            f.write("<summary>View REMOVED Tracks</summary>\n\n")
            for i, t in enumerate(item['removed_names'], 1):
                f.write(f"- {t}\n")
            f.write("\n</details>\n\n")

            f.write("---\n\n")

    print("Done.")

if __name__ == '__main__':
    main()
