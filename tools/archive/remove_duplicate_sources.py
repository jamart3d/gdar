import json
import collections

INPUT_FILE = r'c:\Users\jeff\StudioProjects\gdar\assets\data\output.optimized_src_merged.json'
OUTPUT_FILE = r'c:\Users\jeff\StudioProjects\gdar\assets\data\output.optimized_src_merged_dup_clean.json'

def remove_duplicate_sources():
    print(f"Loading {INPUT_FILE}...")
    try:
        with open(INPUT_FILE, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        print(f"Error loading JSON: {e}")
        return

    print(f"Scanning {len(data)} shows for duplicate Source IDs...")

    # Pass 1: Map Source IDs to their locations (show_index, source_index)
    # Using list to preserve order of appearance
    source_occurrences = collections.defaultdict(list)

    for show_idx, show in enumerate(data):
        sources = show.get('sources', [])
        for source_idx, source in enumerate(sources):
            sid = source.get('id')
            if sid:
                source_occurrences[sid].append((show_idx, source_idx))

    # Identify locations to remove (keep the first, remove the rest)
    to_remove = set()
    dup_id_count = 0
    report_lines = []
    report_lines.append("# Duplicate Sources Removal Report")
    import datetime
    report_lines.append(f"**Date:** {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    report_lines.append("\n## Summary")
    
    for sid, locations in source_occurrences.items():
        if len(locations) > 1:
            # Remove the first location (index 0), keep the rest (index 1 to end)
            remove_locs = [locations[0]]
            keep_locs = locations[1:]
            
            for loc in remove_locs:
                to_remove.add(loc)
            
            dup_id_count += 1
            
            report_lines.append(f"\n### Source ID: {sid} ({len(locations)} occurrences)")
            for loc in remove_locs:
                report_lines.append(f"- **Removed**: Show Index {loc[0]}, Source Index {loc[1]}")
                print(f"Duplicate ID {sid}: Removing occurrence at Show Index {loc[0]}, Source Index {loc[1]}")
            
            for loc in keep_locs:
                 report_lines.append(f"- **Kept**: Show Index {loc[0]}, Source Index {loc[1]}")

    if dup_id_count == 0:
        print("No duplicate Source IDs found.")
        report_lines.append("\nNo duplicate sources found.")
        with open('duplicate_sources_report.md', 'w', encoding='utf-8') as f:
            f.write("\n".join(report_lines))
        return

    print(f"\nFound {dup_id_count} Source IDs with duplicates. removing all but the first occurrence.")

    # Pass 2: Rebuild data filtering out marked locations
    new_data = []
    removed_count = 0

    for show_idx, show in enumerate(data):
        original_sources = show.get('sources', [])
        new_sources = []
        
        for source_idx, source in enumerate(original_sources):
            if (show_idx, source_idx) in to_remove:
                removed_count += 1
                continue # Skip this source
            new_sources.append(source)
        
        # Create new show object with filtered sources
        if new_sources:
            new_show = show.copy()
            new_show['sources'] = new_sources
            new_data.append(new_show)
        else:
            print(f"Show at Index {show_idx} ({show.get('date')} @ {show.get('name')}) is now empty. Removing show entry.")

    print("-" * 30)
    print(f"Total Sources Removed: {removed_count}")
    print("-" * 30)
    
    report_lines.insert(3, f"- **Duplicate IDs Found**: {dup_id_count}")
    report_lines.insert(4, f"- **Total Instances Removed**: {removed_count}")

    try:
        with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
            # Use separators for minified output
            json.dump(new_data, f, separators=(',', ':'))
        print(f"Cleaned data saved to {OUTPUT_FILE}")
        
        with open('duplicate_sources_report.md', 'w', encoding='utf-8') as f:
            f.write("\n".join(report_lines))
        print(f"Full report saved to duplicate_sources_report.md")
        
    except Exception as e:
        print(f"Error saving JSON: {e}")

if __name__ == '__main__':
    remove_duplicate_sources()
