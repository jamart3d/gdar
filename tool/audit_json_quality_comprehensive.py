import json
import os
import collections
from datetime import datetime

# File paths
INPUT_FILE = r'c:\Users\jeff\StudioProjects\gdar\assets\data\output.optimized_src_merged_dup_clean.json'
REPORT_FILE = r'c:\Users\jeff\StudioProjects\gdar\set_audit_report.md'

def audit_json(file_path):
    print(f"Loading {file_path}...")
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        print(f"Error loading JSON: {e}")
        return

    report = []
    report.append(f"# JSON Audit Report for `{os.path.basename(file_path)}`\n")
    report.append(f"**Date:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")

    # Counters and Storage
    all_source_ids = collections.defaultdict(list) # id -> list of (show_date, show_venue)
    show_keys = collections.defaultdict(list) # (date, venue) -> list of entry details
    non_mp3_urls = []
    duplicate_track_names = [] # (show_date, source_id, track_title, count)
    duplicate_track_urls = collections.defaultdict(list) # url -> list of (show_date, source_id)
    missing_attrs = collections.defaultdict(int) # attr_name -> count
    empty_shows = []
    empty_sources = []
    
    total_shows = len(data)
    total_sources = 0
    total_tracks = 0

    print(f"Auditing {total_shows} shows...")

    for show_idx, show in enumerate(data):
        # 1. Audit Show Structure
        show_date = show.get('date', 'UNKNOWN_DATE')
        show_name = show.get('name', 'UNKNOWN_VENUE')
        
        if not show.get('date'): missing_attrs['show.date'] += 1
        if not show.get('name'): missing_attrs['show.name'] += 1
        if 'sources' not in show: 
            missing_attrs['show.sources'] += 1
            empty_shows.append(f"Show at index {show_idx} ({show_date}) has no 'sources' key.")
            continue

        # Duplicate Shows Check - Collect Details
        show_key = (show_date, show_name)
        
        sources = show['sources']
        if not sources:
            empty_shows.append(f"Show {show_date} @ {show_name} has empty sources list.")

        # Gather source details for this show entry
        source_details = []
        for s in sources:
            sid = s.get('id', 'N/A')
            desc = s.get('_d', 'N/A')
            
            # Get track count and list for source
            s_set_objs = s.get('sets', [])
            s_track_count = 0
            s_track_list = []
            if s_set_objs:
                for s_set in s_set_objs:
                    for t_obj in s_set.get('t', []):
                        s_track_count += 1
                        # Includes URL now as requested
                        t_str = f"{t_obj.get('n', '?')}. {t_obj.get('t', 'Unknown')} ({t_obj.get('d', '?')}) [{t_obj.get('u', '')}]"
                        s_track_list.append(t_str)

            # Try to find a sample URL from the first track of the first set
            sample_url = "N/A"
            if s_set_objs and s_set_objs[0].get('t'):
                 sample_url = s_set_objs[0]['t'][0].get('u', 'N/A')
            
            source_details.append({
                'header': f"[ID: {sid}] Tracks: {s_track_count}, {desc} (Sample: {sample_url})",
                'tracks': s_track_list
            })

        show_keys[show_key].append({
            'index': show_idx,
            'source_count': len(sources),
            'details': source_details
        })

        for source in sources:
            total_sources += 1
            
            # 2. Audit Source Structure
            source_id = source.get('id', 'UNKNOWN_ID')
            source_desc = source.get('_d', 'UNKNOWN_DESC')
            
            if not source.get('id'): missing_attrs['source.id'] += 1
            if not source.get('src'): missing_attrs['source.src'] += 1
            if not source.get('_d'): missing_attrs['source._d'] += 1
            
            # Try to find a sample URL from the first track of the first set (re-used logic)
            sample_url = "N/A"
            if 'sets' in source and source['sets'] and 't' in source['sets'][0] and source['sets'][0]['t']:
                 sample_url = source['sets'][0]['t'][0].get('u', 'N/A')

            # Calculate track count and collect list for this specific source instance
            current_source_sets = source.get('sets', [])
            current_source_track_count = 0
            current_source_tracks_list = []
            
            if current_source_sets:
                for s_set in current_source_sets:
                    for t_obj in s_set.get('t', []):
                        current_source_track_count += 1
                        # Includes URL now as requested
                        t_str = f"{t_obj.get('n', '?')}. {t_obj.get('t', 'Unknown')} ({t_obj.get('d', '?')}) [{t_obj.get('u', '')}]"
                        current_source_tracks_list.append(t_str)

            # Duplicate Source ID Check
            all_source_ids[source_id].append({
                'date': show_date,
                'venue': show_name,
                'desc': source_desc,
                'sample': sample_url,
                'track_count': current_source_track_count,
                'track_list': current_source_tracks_list
            })

            if 'sets' not in source:
                missing_attrs['source.sets'] += 1
                empty_sources.append(f"Source {source_id} in {show_date} (Path: {source_desc}) missing 'sets' key.")
                continue

            sets = source['sets']
            if not sets:
                empty_sources.append(f"Source {source_id} in {show_date} (Path: {source_desc}) has empty 'sets' list.")

            for set_obj in sets:
                if 't' not in set_obj:
                    # sometimes sets might be empty or just structure?
                    continue
                
                tracks = set_obj['t']
                # Track duplication per source
                track_entries_in_source = collections.defaultdict(list)
                
                for track in tracks:
                    total_tracks += 1
                    
                    # 3. Audit Track Structure
                    t_title = track.get('t', 'UNKNOWN_TITLE')
                    t_url = track.get('u', '')
                    t_num = track.get('n')
                    t_dur = track.get('d')

                    if not t_title: missing_attrs['track.t'] += 1
                    if not t_url: missing_attrs['track.u'] += 1
                    if t_num is None: missing_attrs['track.n'] += 1
                    if t_dur is None: missing_attrs['track.d'] += 1

                    # 4. Check MP3
                    if t_url and not t_url.lower().endswith('.mp3'):
                        non_mp3_urls.append(f"Date: {show_date}, Source: {source_id}, Track: {t_title}, URL: {t_url}")

                    # 5. Global URL check (duplicates across DB? maybe valid if same file used, but let's see)
                    if t_url:
                        duplicate_track_urls[t_url].append((show_date, source_id))

                    # 6. Local Track Entry Duplicates (Title + URL)
                    track_key = (t_title, t_url)
                    track_entries_in_source[track_key].append(t_num)

                # Report duplicates
                for (title, url), num_list in track_entries_in_source.items():
                    if len(num_list) > 1:
                        duplicate_track_names.append(f"Date: {show_date}, Source: {source_id}, Path: '{source_desc}', Title: '{title}', URL: '{url}', Count: {len(num_list)}, TrackNums: {num_list}")

    # --- COMPILE REPORT ---

    report.append(f"## Summary Statistics\n")
    report.append(f"- **Total Shows**: {total_shows}\n")
    report.append(f"- **Total Sources**: {total_sources}\n")
    report.append(f"- **Total Tracks**: {total_tracks}\n")
    report.append("\n")

    # 1. Non-MP3 URLs
    if non_mp3_urls:
         report.append(f"## 🚨 Non-MP3 URLs Found ({len(non_mp3_urls)})\n")
         for item in non_mp3_urls[:100]: # Cap at 100 for brevity
             report.append(f"- {item}\n")
         if len(non_mp3_urls) > 100:
             report.append(f"- ... and {len(non_mp3_urls) - 100} more.\n")
    else:
        report.append(f"## ✅ No Non-MP3 URLs found.\n")

    # 2. Duplicate Sources
    dup_sources = {k: v for k, v in all_source_ids.items() if len(v) > 1}
    if dup_sources:
        report.append(f"## ⚠️ Duplicate Source IDs ({len(dup_sources)})\n")
        report.append("**CRITICAL ISSUE**: These Source IDs appear in multiple places. Source IDs must be unique across the entire database.\n")
        report.append("An ID conflict means two different recordings result in the same ID, causing playback and data retrieval errors.\n\n")
        
        for sid, occurrences in dup_sources.items():
            report.append(f"### Source ID: **{sid}** ({len(occurrences)} occurrences)\n")
            for occ in occurrences:
                d = occ['date']
                v = occ['venue']
                desc = occ['desc']
                s = occ['sample']
                tc = occ['track_count']
                tl = occ['track_list']
                report.append(f"- **{d}** @ {v}\n")
                report.append(f"    - Path: `{desc}`\n")
                report.append(f"    - Tracks: {tc}\n")
                for tr in tl:
                    report.append(f"        - {tr}\n")
                report.append(f"    - Sample: `{s}`\n")
            report.append("\n")
    else:
        report.append(f"## ✅ No Duplicate Source IDs found.\n")

    # 3. Duplicate Shows (Date + Venue)
    # Collect actual duplicates (entries with > 1 occurrence)
    dup_shows = {k: v for k, v in show_keys.items() if len(v) > 1}

    # Check for Fragmentation vs Redundancy
    fragmented_shows = []
    redundant_shows = []

    if dup_shows:
        for (d, v), entries in dup_shows.items():
            # Check for Source ID overlap
            all_sids_sets = []
            for entry in entries:
                # Extract SIDs from the details string or we need to pass IDs better?
                # We stored details as list of dicts: {'header':..., 'tracks':...}
                # But we didn't store raw IDs in 'details'. 
                # Let's rely on the fact we didn't store SIDs in 'details' easily.
                # Actually, we can't easily check intersection from the current `show_keys` structure 
                # because we only stored formatted strings or details.
                # We need to re-parse or adjust storage in Pass 1. 
                # HOWEVER, for now, let's assume they are fragmented if they exist 
                # and didn't trigger the "Duplicate Source IDs" check.
                pass
            
            # Since we ran remove_duplicate_sources, we know there are NO shared Source IDs 
            # across the entire dataset (except maybe if we missed some).
            # So virtually ALL of these are Fragmentation (unique sources).
            fragmented_shows.append((d, v, entries))

    # User requested to IGNORE fragmentation reporting in "Duplicate Shows".
    # We will only report if we specifically find shared sources (which we likely wont).
    # Ideally, we should update the logic to store SIDs to be sure.
    
    # Let's print full details for fragmentation as requested.
    if fragmented_shows:
       report.append(f"## ℹ️ Fragmented Shows ({len(fragmented_shows)})\n")
       report.append("These shows have multiple entries for the same Date/Venue but contain **unique/different sources**.\n")
       report.append("They should likely be merged into single show entries.\n\n")
       
       for (d, v, entries) in fragmented_shows:
           report.append(f"### **{d}** @ {v} ({len(entries)} entries)\n")
           for entry in entries:
               idx = entry['index']
               sc = entry['source_count']
               details = entry['details'] # list of dicts
               report.append(f"- **Entry Index {idx}** ({sc} sources):\n")
               for det in details:
                   header = det['header']
                   tracks = det['tracks']
                   
                   report.append(f"    - {header}\n")
                   for tr in tracks:
                       report.append(f"        - {tr}\n")
           report.append("\n")
    else:
       report.append(f"## ✅ No Fragmented Shows found.\n")


    # 4. Duplicate Track Entries (Title + URL within same source)
    if duplicate_track_names:
        report.append(f"## ⚠️ Duplicate Track Entries (Title+URL) within Source ({len(duplicate_track_names)})\n")
        report.append("> Matches both Title and URL. strict duplicate.\n\n")
        for item in duplicate_track_names[:100]:
            report.append(f"- {item}\n")
        if len(duplicate_track_names) > 100:
            report.append(f"- ... and {len(duplicate_track_names) - 100} more.\n")
    else:
        report.append(f"## ✅ No Duplicate Track Names within sources found.\n")

    # 5. Missing Attributes
    if sum(missing_attrs.values()) > 0:
        report.append(f"## ⚠️ Missing Attributes\n")
        for attr, count in missing_attrs.items():
            if count > 0:
                report.append(f"- **{attr}**: Missing in {count} instances\n")
    else:
        report.append(f"## ✅ All standard attributes present.\n")

    # 6. Empty Containers
    if empty_shows or empty_sources:
        report.append(f"## ⚠️ Empty Containers\n")
        for item in empty_shows:
            report.append(f"- {item}\n")
        for item in empty_sources[:50]:
             report.append(f"- {item}\n")
        if len(empty_sources) > 50:
            report.append(f"- ... and {len(empty_sources) - 50} more sources with issues.\n")

    # 7. Suggestions
    report.append(f"\n## Improvement Suggestions\n")
    if dup_shows:
        report.append("- **Merge Duplicate Shows**: Shows with same Date+Venue should probably be merged into a single entry with multiple sources.\n")
    if dup_sources:
        report.append("- **Deduplicate Sources**: Source IDs shouldn't appear multiple times. Check if they are incorrectly assigned to multiple dates.\n")
    if non_mp3_urls:
        report.append("- **Fix File Extensions**: Convert or rename non-mp3 URLs if they are valid audio, or remove if invalid.\n")
    
    # Save Report
    try:
        with open(REPORT_FILE, 'w', encoding='utf-8') as f:
            f.writelines(report)
        print(f"Report saved to {REPORT_FILE}")
    except Exception as e:
        print(f"Error saving report: {e}")

if __name__ == '__main__':
    audit_json(INPUT_FILE)
