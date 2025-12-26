import json
import os
from collections import defaultdict, OrderedDict

# Input file (processed after duplicate cleanup)
INPUT_FILE = r'c:\Users\jeff\StudioProjects\gdar\assets\data\output.optimized_src_orig.json'
# Output file
OUTPUT_FILE = r'c:\Users\jeff\StudioProjects\gdar\assets\data\output.optimized_src_merged.json'
# Report file
REPORT_FILE = r'c:\Users\jeff\StudioProjects\gdar\merge_report.md'

def merge_fragmented_shows():
    print(f"Loading {INPUT_FILE}...")
    try:
        with open(INPUT_FILE, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"Error: File not found: {INPUT_FILE}")
        return

    print(f"Original show count: {len(data)}")

    # 1. Group shows by (Date, Venue)
    # Using a list to preserve order of first appearance if possible, 
    # but since we are merging, we'll likely append merged shows.
    # Actually, let's keep a map to the *first* instance's index for in-place replacement if we wanted,
    # but creating a new list is safer and cleaner.
    
    grouped_shows = defaultdict(list)
    
    for show in data:
        date = show.get('date', 'Unknown Date')
        venue = show.get('name', 'Unknown Venue')
        key = (date, venue)
        grouped_shows[key].append(show)

    merged_data = []
    report_lines = []
    report_lines.append("# Broken/Fragmented Shows Merge Report")
    report_lines.append(f"**Date:** {os.popen('date /t').read().strip()}")
    report_lines.append("\n## Summary")
    
    fragmented_count = 0
    total_merged_sources = 0

    # 2. Process groups
    # We want to maintain some chronological order. 
    # The original list usually is sorted by date.
    # keys in grouped_shows will be inserted in order of first appearance (Python 3.7+ dicts match insertion order).
    
    for (date, venue), entries in grouped_shows.items():
        if len(entries) == 1:
            # No fragmentation
            merged_data.append(entries[0])
        else:
            # Fragmentation found!
            fragmented_count += 1
            
            # Create a base merged show
            # We take metadata from the first entry
            base_show = entries[0].copy()
            
            # Consolidate sources
            # Use a dict keyed by Source ID to prevent duplicates if any snuck in
            merged_sources_map = OrderedDict()
            
            # To report what happened
            merge_details = []
            
            for i, entry in enumerate(entries):
                srcs = entry.get('sources', [])
                # Collect SHNIDs for this entry
                entry_shnids = [s.get('id', 'Unknown') for s in srcs]
                # Format list as comma-separated string
                shnid_str = ", ".join(str(s) for s in entry_shnids)
                merge_details.append(f"Entry #{i+1}: {len(srcs)} sources (IDs: {shnid_str})")
                
                for s in srcs:
                    sid = s.get('id')
                    if sid:
                        if sid not in merged_sources_map:
                            merged_sources_map[sid] = s
                        else:
                            # Duplicate source ID encountered during merge (should be rare if prev script ran)
                            pass
                    else:
                        # No ID? append blindly or skip? 
                        # Assuming all sources have IDs based on audit.
                        # We'll generate a fake key using id() if needed but unlikely.
                        pass
            
            # Update the base show with merged sources list
            base_show['sources'] = list(merged_sources_map.values())
            
            merged_data.append(base_show)
            
            # Add to report
            report_lines.append(f"\n### {date} @ {venue}")
            report_lines.append(f"- **Merged {len(entries)} entries** into 1.")
            report_lines.append(f"- Result: {len(base_show['sources'])} total sources.")
            for detail in merge_details:
                report_lines.append(f"  - {detail}")
            
            total_merged_sources += len(base_show['sources'])

    # 3. Write Output
    print(f"Fragmented groups merged: {fragmented_count}")
    print(f"New show count: {len(merged_data)}")
    
    print(f"Saving to {OUTPUT_FILE}...")
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        # Use separators for creating compact JSON similar to input
        json.dump(merged_data, f, separators=(',', ':'))

    # 4. Write Report
    summary_text = (f"- **Fragmented Shows Fixed**: {fragmented_count}\n"
                    f"- **Original Show Count**: {len(data)}\n"
                    f"- **Final Show Count**: {len(merged_data)}\n")
    
    # Insert summary after header
    report_lines.insert(3, summary_text)
    
    with open(REPORT_FILE, 'w', encoding='utf-8') as f:
        f.write("\n".join(report_lines))
    
    print(f"Report saved to {REPORT_FILE}")

if __name__ == "__main__":
    merge_fragmented_shows()
