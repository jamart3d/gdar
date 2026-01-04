import json
import argparse
import sys
from collections import defaultdict

# Known corrections map: Date -> (Venue, Location)
KNOWN_VENUE_LOCATIONS = {
    "1968-01-22": ("Eagles Auditorium", "Seattle, Wa"),
    "1968-01-23": ("Eagles Auditorium", "Seattle, Wa"),
    "1968-10-08": ("The Matrix", "San Francisco, Ca"),
    "1968-10-10": ("The Matrix", "San Francisco, Ca"),
    "1968-10-30": ("The Matrix", "San Francisco, Ca"),
    "1968-11-06": ("Pacific High Recording", "San Francisco, Ca"),
    "1969-06-01": ("Avalon Ballroom", "San Francisco, Ca"),
    "1969-08-28": ("Family Dog at the Great Highway", "San Francisco, Ca"), # Inferred loc from context/list pattern usually SF
    "1970-12-17": ("The Matrix", "San Francisco, Ca"),
    "1971-05-30": ("Winterland Arena", "San Francisco, Ca"),
    "1975-07-23": ("Club Front", "San Rafael, Ca"),
    "1975-07-24": ("Club Front", "San Rafael, Ca"),
    "1975-09-16": ("Club Front", "San Rafael, Ca"),
    "1976-05-28": ("Club Front", "San Rafael, Ca"),
    "1978-09-13": ("Gizah Sound and Light Theater", "Giza, Egypt"),
    "1978-11-08": ("Capitol Center", "Landover, Md"),
    "1980-10-01": ("Warfield Theatre & Radio City Music Hall", "San Francisco, CA & New York, NY"), # Best guess or null?
    "1981-03-04": ("Club Front", "San Rafael, Ca"),
    "1981-12-11": ("Club Front", "San Rafael, Ca"),
    "1982-01-01": ("Mickey's ranch studio", "Novato, Ca"),
    "1982-11-26": ("Bob Marley Performing Arts Center", "Montego Bay, Jam"),
    "1985-04-21": ("Marin Veterans Memorial Auditorium", "Marin, Ca"),
    "1986-12-01": ("Club Front", "San Rafael, Ca"),
    "1987-03-28": ("Hampton Coliseum", "Hampton, Va"),
    "1987-06-01": ("Club Front", "San Rafael, Ca"),
    "1987-07-13": ("Robert F. Kennedy Stadium", "Washington, DC"),
    "1989-09-09": ("The Spectrum", "San Rafael, Ca"),
    "1990-08-28": ("Club Front", "San Rafael, Ca"),
    "1990-09-26": ("Club Front", "San Rafael, Ca"),
    "1990-09-27": ("Club Front", "San Rafael, Ca"),
    "1990-09-28": ("Club Front", "San Rafael, Ca"),
    "1992-02-13": ("Club Front", "San Rafael, Ca"),
    "1992-02-21": ("Club Front", "San Rafael, Ca"),
    "1993-02-10": ("Club Front", "San Rafael, Ca"),
    "1994-02-24": ("Oakland County Coliseum", "Oakland, Ca"),
    "1995-03-28": ("The Omni", "Atlanta, Ga")
}

def get_source_map(data):
    """Builds a map of shnid -> {sets: signature} for comparison."""
    source_map = {}
    for show in data:
        for source in show.get('sources', []):
            shnid = source.get('id')
            if not shnid: continue
            
            # Get Set Signature
            sets = source.get('sets', [])
            if not sets and 'source_sets' in source:
                 sets = source['source_sets']
            
            sig = []
            for s in sets:
                s_name = s.get('n', 'Unk')
                t_count = len(s.get('t', []))
                sig.append(f"{s_name}({t_count})")
            
            source_map[shnid] = ", ".join(sig)
    return source_map

def audit_json(input_file, report_file, reference_file=None, output_file=None):
    print(f"Starting audit of {input_file}...")
    
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        print(f"FATAL: Could not read or parse JSON file: {e}")
        sys.exit(1)

    ref_data = None
    if reference_file:
        print(f"Loading reference file {reference_file}...")
        try:
            with open(reference_file, 'r', encoding='utf-8') as f:
                ref_data = json.load(f)
        except Exception as e:
            print(f"WARNING: Could not read reference file: {e}")

    if not isinstance(data, list):
        print("FATAL: Root element is not a list.")
        sys.exit(1)

    stats = {
        "total_shows": len(data),
        "total_sources": 0,
        "total_tracks": 0,
        "issues_found": 0,
        "duplicate_shnids": 0,
        "empty_sets": 0,
        "malformed_sources": 0,
        "suspicious_encores": 0,
        "single_track_set2": 0,
        "long_no_encore": 0,
        "us_blues_last_no_encore": 0,
        "us_blues_last_no_encore": 0,
        "omsn_last_no_encore": 0,
        "shows_missing_l": 0,
        "missing_fields": defaultdict(int)
    }

    issues_log = []
    shows_missing_l_list = []
    corrections_log = []
    seen_shnids = {}

    for show in data:

        date = show.get('date', 'UNKNOWN_DATE')
        sources = show.get('sources', [])
        
        if not sources:
            stats["missing_fields"]["no_sources"] += 1
            issues_log.append({"msg": f"[{date}] Show has no sources.", "source": None})
            continue
            
        if 'l' not in show:
            stats["shows_missing_l"] += 1
            shows_missing_l_list.append(f"[{date}] {show.get('name', 'N/A')}")

        # Check against Known Corrections
        if date in KNOWN_VENUE_LOCATIONS:
            expected_venue, expected_location = KNOWN_VENUE_LOCATIONS[date]
            current_venue = show.get('name', '')
            current_location = show.get('l', '')
            
            # Apply corrections if mismatched
            updates = []
            if expected_venue and expected_venue != current_venue:
                show['name'] = expected_venue
                updates.append(f"Venue: '{current_venue}' -> '{expected_venue}'")
            
            if expected_location and expected_location != current_location:
                show['l'] = expected_location
                updates.append(f"Location: '{current_location}' -> '{expected_location}'")
            
            if updates:
                stats["issues_found"] += 1 
                # Log as applied correction
                corrections_log.append(f"[{date}] Applied Known Corrections: {'; '.join(updates)}")


        for source in sources:
            stats["total_sources"] += 1
            shnid = source.get('id')
            
            # Check ID
            if not shnid:
                 stats["missing_fields"]["source_id"] += 1
                 stats["malformed_sources"] += 1
                 issues_log.append({"msg": f"[{date}] Malformed source (missing ID).", "source": source})
                 continue
            
            # Check Duplicates
            if shnid in seen_shnids:
                stats["duplicate_shnids"] += 1
                issues_log.append({"msg": f"[{date}] Duplicate SHNID {shnid} (previously seen in {seen_shnids[shnid]})", "source": source})
            else:
                seen_shnids[shnid] = date

            # Check Sets
            sets = source.get('sets', [])
            if not sets:
                 if 'source_sets' in source:
                     sets = source['source_sets']
                 else:
                     stats["missing_fields"]["no_sets"] += 1
                     issues_log.append({"msg": f"[{date}] Source {shnid} has no sets.", "source": source})
                     continue
            
            has_set2 = False
            has_encore = False
            set2_tracks = 0
            total_source_tracks = 0
            
            issues_found_in_source = []

            for s in sets:
                set_name = s.get('n', 'Unknown')
                tracks = s.get('t', [])
                count = len(tracks)
                total_source_tracks += count
                stats["total_tracks"] += count

                if not tracks:
                    stats["empty_sets"] += 1
                    issues_found_in_source.append(f"Set '{set_name}' is empty.")
                
                # Check Track Fields
                for t in tracks:
                    if 't' not in t:
                        stats["missing_fields"]["track_title"] += 1
                    if 'u' not in t:
                        stats["missing_fields"]["track_filename"] += 1
                
                # Logic Checks
                if set_name == "Set 2":
                    has_set2 = True
                    set2_tracks = count
                
                if set_name == "Encore":
                    has_encore = True
                    if count >= 5:
                        stats["suspicious_encores"] += 1
                        issues_found_in_source.append(f"Suspiciously long Encore ({count} tracks).")

            if has_set2 and set2_tracks == 1:
                stats["single_track_set2"] += 1
                issues_found_in_source.append(f"Single track Set 2.")
            
            if total_source_tracks > 13 and not has_encore:
                 stats["long_no_encore"] += 1
                 issues_found_in_source.append(f"Long show ({total_source_tracks} tracks) with NO Encore.")
            
            # Check for specific closers not in Encore
            if sets:
                last_set = sets[-1]
                if last_set.get('n') != "Encore" and last_set.get('t'):
                    last_track = last_set['t'][-1]
                    lt_name_lower = last_track.get('t', '').lower()
                    
                    if "u.s. blues" in lt_name_lower or "us blues" in lt_name_lower:
                        stats["us_blues_last_no_encore"] += 1
                        issues_found_in_source.append("U.S. Blues is last track but NOT in Encore.")
                    
                    if "one more saturday night" in lt_name_lower:
                         stats["omsn_last_no_encore"] += 1
                         issues_found_in_source.append("One More Saturday Night is last track but NOT in Encore.")
            


            if issues_found_in_source:
                for issue in issues_found_in_source:
                    issues_log.append({"msg": f"[{date}] Source {shnid}: {issue}", "source": source})

    # Write Output JSON if requested
    if output_file:
         print(f"Writing optimized JSON to {output_file}...")
         try:
             with open(output_file, 'w', encoding='utf-8') as f:
                 # Use separators for minified output similar to fix_sets_api
                 json.dump(data, f, separators=(',', ':'))
             print("Done.")
         except Exception as e:
             print(f"FATAL: Could not write output file: {e}")

    # Write Report
    print(f"Audit complete. Found {len(issues_log)} issues.")
    print(f"Writing report to {report_file}...")
    
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write("# JSON Data Audit Report\n\n")
        
        f.write("## Summary Statistics\n\n")
        f.write("| Metric | Count |\n")
        f.write("| :--- | :--- |\n")
        f.write(f"| Total Shows | {stats['total_shows']} |\n")
        f.write(f"| Total Sources | {stats['total_sources']} |\n")
        f.write(f"| Total Tracks | {stats['total_tracks']} |\n")
        f.write(f"| **Issues Found** | **{len(issues_log)}** |\n")
        f.write("\n")
        
        if ref_data:
            f.write("## Comparison with Reference\n\n")
            input_map = get_source_map(data)
            ref_map = get_source_map(ref_data)
            
            new_ids = set(input_map.keys()) - set(ref_map.keys())
            missing_ids = set(ref_map.keys()) - set(input_map.keys())
            common_ids = set(input_map.keys()) & set(ref_map.keys())
            
            changed_structures = []
            for shnid in common_ids:
                if input_map[shnid] != ref_map[shnid]:
                    changed_structures.append(f"- {shnid}: `{ref_map[shnid]}` -> `{input_map[shnid]}`")
            
            f.write(f"- **New Sources:** {len(new_ids)}\n")
            f.write(f"- **Removed Sources:** {len(missing_ids)}\n")
            f.write(f"- **Sources with Set Structure Changes:** {len(changed_structures)}\n\n")
            
            if changed_structures:
                f.write("### Structure Changes (Sample)\n")
                for change in changed_structures[:50]:
                    f.write(f"{change}\n")
                if len(changed_structures) > 50:
                    f.write(f"... and {len(changed_structures) - 50} more.\n")
            f.write("\n")
        
        f.write("## Integrity Issues\n\n")
        f.write(f"- **Duplicate SHNIDs:** {stats['duplicate_shnids']}\n")
        f.write(f"- **Empty Sets:** {stats['empty_sets']}\n")
        f.write(f"- **Malformed Sources:** {stats['malformed_sources']}\n")
        f.write(f"- **Suspicious Encores (5+ tracks):** {stats['suspicious_encores']}\n")
        f.write(f"- **Single Track Set 2:** {stats['single_track_set2']}\n")
        f.write(f"- **Long Shows with NO Encore (>13 tracks):** {stats['long_no_encore']}\n")
        f.write(f"- **'U.S. Blues' last but NO Encore:** {stats['us_blues_last_no_encore']}\n")
        f.write(f"- **'One More Saturday Night' last but NO Encore:** {stats['omsn_last_no_encore']}\n")

        f.write(f"- **Shows missing Location 'l':** {stats['shows_missing_l']}\n")
        f.write("\n")
        
        if stats["missing_fields"]:
             f.write("### Missing Fields (Counts)\n")
             for field, count in stats["missing_fields"].items():
                 f.write(f"- {field}: {count}\n")
             f.write("\n")

        if shows_missing_l_list:
            f.write("## Shows Missing Location\n\n")
            for item in shows_missing_l_list:
                f.write(f"- {item}\n")
            f.write("\n")

        if corrections_log:
            f.write("## Applied Venue/Location Corrections\n\n")
            for item in corrections_log:
                f.write(f"- {item}\n")
            f.write("\n")

        f.write("## Issue Log\n\n")
        if issues_log:
            limit = 1000
            if len(issues_log) > limit:
                f.write(f"*(Displaying first {limit} of {len(issues_log)} issues)*\n\n")
            
            for i, item in enumerate(issues_log):
                if i >= limit: break
                
                msg = item['msg']
                source = item['source']
                
                f.write(f"### {i+1}. {msg}\n")
                if source:
                    desc = source.get('_d', 'N/A')
                    f.write(f"- **Source Path:** `{desc}`\n")
                    f.write(f"- **Archive URL:** https://archive.org/details/{desc}\n")
                    f.write("- **Tracks:**\n")
                    
                    sets = source.get('sets') or source.get('source_sets') or []
                    if sets:
                        for s in sets:
                            s_name = s.get('n', 'Set')
                            f.write(f"  - **{s_name}**\n")
                            for idx, t in enumerate(s.get('t', []), 1):
                                t_name = t.get('t', 'Unknown')
                                t_fn = t.get('u', '')
                                f.write(f"    {idx}. {t_name} `({t_fn})`\n")
                    else:
                        f.write("  *No tracks found property.*\n")
                
                f.write("\n---\n")

        else:
            f.write("No specific issues logged. Data structure appears healthy.\n")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Audit JSON data integrity.')
    parser.add_argument('--input', default='assets/data/output.optimized_src.json', help='Input JSON file')
    parser.add_argument('--report', default='audit_report.md', help='Output report file')
    parser.add_argument('--reference', help='Optional reference JSON file to compare against')
    parser.add_argument('--output', help='Optional output JSON file to save corrections')
    args = parser.parse_args()
    
    audit_json(args.input, args.report, args.reference, args.output)
