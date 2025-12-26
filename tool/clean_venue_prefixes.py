import json
import re
import os

def main():
    input_file = 'assets/data/output.optimized_oldder_src_cleaned.json'
    output_file = 'assets/data/output.optimized_oldder_src_cleaned_name1chop.json'
    report_file = 'venue_prefix_clean_report.md'
    
    if not os.path.exists(input_file):
        print(f"Error: {input_file} not found.")
        return

    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)

    updated_count = 0
    total_shows = len(data)
    
    report = [
        "# 🏟️ Venue Prefix Cleaning Report",
        f"\n> **Input:** `{input_file}`",
        f"> **Output:** `{output_file}`\n",
        "## 📝 Changes\n",
        "| Original Name | Cleaned Name |",
        "| :--- | :--- |"
    ]

    print(f"Processing {total_shows} shows...")

    unchanged_entries = []

    for show in data:
        original_name = show.get('name', '')
        
        # Split by " at " case-insensitive, maxsplit=1
        parts = re.split(r'\s+at\s+', original_name, maxsplit=1, flags=re.IGNORECASE)
        
        updated = False
        if len(parts) > 1:
            # Take the part after " at "
            new_name = parts[1].strip()
            
            if new_name != original_name:
                show['name'] = new_name
                updated_count += 1
                report.append(f"| {original_name} | **{new_name}** |")
                updated = True
        
        if not updated:
            unchanged_entries.append(original_name)

    if updated_count == 0:
        report.append("\n*No venue names were modified.*")
    else:
        report.insert(4, f"**Total Shows Updated:** {updated_count}\n")
    
    # Append unchanged section
    report.append("\n## 🛡️ Unchanged Venues")
    report.append(f"**Total Unchanged:** {len(unchanged_entries)}\n")
    
    if unchanged_entries:
        report.append("| Original Name |")
        report.append("| :--- |")
        for name in unchanged_entries:
            report.append(f"| {name} |")
    else:
        report.append("*All venues were updated based on the criteria.*")

    # Save the cleaned data
    print(f"Saving cleaned data to {output_file}...")
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, separators=(',', ':'))

    # Save the report
    print(f"Saving report to {report_file}...")
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write("\n".join(report))

    print(f"Done. Updated {updated_count} shows.")

if __name__ == '__main__':
    main()
