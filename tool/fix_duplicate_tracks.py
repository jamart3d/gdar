import json
import os
from collections import Counter



def main():
    INPUT_FILE = 'assets/data/output.optimized_oldder_src_cleaned_dupfixed_set_opt.json'
    OUTPUT_FILE = 'assets/data/output.optimized_oldder_src_cleaned_dupfixed2_set_opt.json'
    REPORT_FILE = 'dup_fix_report.md'

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
            
            # Extract tracks from Sets
            sets = source.get('sets', [])
            all_tracks = []
            
            # We need to map tracks back to sets later.
            # Or simplified: Flatten, clean, then what?
            # If we flatten, we lose set boundaries unless we track them.
            # But duplicate removal logic is "keep first occurrence".
            # If duplicates are across sets (e.g. Set 1 is repeated), we might lose entire Sets.
            
            # Helper to access tracks
            for set_obj in sets:
                for t in set_obj.get('t', []):
                    # Annotate temporarily with set reference to restore later if needed?
                    # Actually, if we just clean the list, we can just rebuild the sets?
                    # No, we need to know WHICH set a track belongs to.
                    t['_set_ref'] = set_obj
                    all_tracks.append(t)
            
            # If no sets/tracks, skip
            if not all_tracks:
                continue
            
            # Create list of (normalized_name, duration) tuples
            track_identities = [(normalize_title(t.get('t')), t.get('d', 0)) for t in all_tracks if t.get('t')]
            
            if not track_identities:
                continue

            # RELAXED FILTER: Fix if total tracks are >= 1.5x unique tracks.
            unique_identities = set(track_identities)
            
            if len(track_identities) >= 1.5 * len(unique_identities):
                seen_identities = set()
                removed_names = []
                skipped_indices = []
                
                # Iterate and mark for keeping/removing
                # We can modify the set objects directly since we have references!
                
                # To handle "removal", we can build NEW set lists.
                cleaned_sets_map = {id(s): [] for s in sets} # Map SetObjectID -> NewTrackList
                
                cleaned_tracks_report = []

                for idx, t in enumerate(all_tracks, 1):
                    norm_name = normalize_title(t.get('t'))
                    t_dur = t.get('d', 0)
                    identity = (norm_name, t_dur)
                    url = t.get('u', '')
                    is_vbr = "_vbr.mp3" in url.lower()
                    
                    set_obj = t.pop('_set_ref') # Retrieve and remove temp ref
                    
                    if is_vbr:
                        removed_names.append(f"#{idx} {t.get('t', '').strip()} ({t_dur}s) [VBR]")
                        skipped_indices.append(idx)
                        continue

                    if identity not in seen_identities:
                        cleaned_sets_map[id(set_obj)].append(t)
                        cleaned_tracks_report.append(f"[Orig #{idx}] {t.get('t', '').strip()} ({t.get('d', 0)}s) [URL: {t.get('u', 'N/A')}]")
                        seen_identities.add(identity)
                    else:
                        removed_names.append(f"#{idx} {t.get('t', '').strip()} ({t_dur}s) [Duplicate]")
                        skipped_indices.append(idx)
                
                # Reconstruct Sets
                new_sets = []
                for s in sets:
                    kept_tracks = cleaned_sets_map[id(s)]
                    if kept_tracks: # Only keep set if it has tracks? Or keep empty sets?
                        # Let's keep empty sets if they existed, or maybe remove them.
                        # Usually empty set is useless.
                        s['t'] = kept_tracks
                        new_sets.append(s)
                
                source['sets'] = new_sets
                
                fixed_sources.append({
                    'date': date,
                    'shnid': shnid,
                    'original_count': len(all_tracks),
                    'new_count': len(cleaned_tracks_report),
                    'tracks_removed': len(all_tracks) - len(cleaned_tracks_report),
                    'cleaned_tracks': cleaned_tracks_report,
                    'removed_names': removed_names,
                    'skipped_indices': skipped_indices
                })
            else:
                # Need to remove the _set_ref if we skipped fixing
                for t in all_tracks:
                    t.pop('_set_ref', None)

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
            f.write(f"- **Tracks Removed:** {item['tracks_removed']}\n")
            
            # Simplify skipping report: ranges or commas? Commas are fine.
            skips_str = ", ".join(map(str, item['skipped_indices']))
            f.write(f"- **Skipped Track Numbers:** {skips_str if skips_str else 'None'}\n\n")
            
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
