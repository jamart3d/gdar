import json
import re

def main():
    input_file = 'assets/data/output.optimized_src.json'
    output_file = 'venue_prefix_report.md'
    
    try:
        with open(input_file, 'r') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"Error: {input_file} not found.")
        return

    total_shows = 0
    can_split_count = 0
    cannot_split_count = 0
    
    prefix_counts = {}

    for show in data:
        total_shows += 1
        name = show.get('name', '')
        
        # Split by " at " case-insensitive
        # limiting split to 1 to just get the prefix vs the rest
        # We use strict regex: spaces around 'at' to avoid splitting "Theater"
        parts = re.split(r'\s+at\s+', name, maxsplit=1, flags=re.IGNORECASE)
        
        if len(parts) > 1:
            can_split_count += 1
            prefix = parts[0].strip()
            
            # Normalize prefix for tallying (case-insensitive)
            prefix_key = prefix.lower()
            if prefix_key not in prefix_counts:
                # Store the first variation we see as the display version, or just clean it
                prefix_counts[prefix_key] = {'display': prefix, 'count': 0}
            prefix_counts[prefix_key]['count'] += 1
        else:
            cannot_split_count += 1

    # Sort prefixes by count descending
    sorted_prefixes = sorted(prefix_counts.values(), key=lambda x: x['count'], reverse=True)

    with open(output_file, 'w') as f:
        f.write('# Report: Venue Name Split Analysis ("at")\n\n')
        
        f.write(f'**Total Shows Analyzed:** {total_shows}\n\n')
        
        f.write('| Category | Count | Percentage |\n')
        f.write('|---|---|---|\n')
        perc_split = (can_split_count / total_shows * 100) if total_shows else 0
        perc_nosplit = (cannot_split_count / total_shows * 100) if total_shows else 0
        f.write(f'| Can be split by " at " | {can_split_count} | {perc_split:.1f}% |\n')
        f.write(f'| Cannot be split | {cannot_split_count} | {perc_nosplit:.1f}% |\n')

        f.write('\n## Prefix Tally (Text before " at ")\n')
        f.write('| Prefix | Count |\n')
        f.write('|---|---|\n')
        
        for p in sorted_prefixes:
            f.write(f"| {p['display']} | {p['count']} |\n")

        f.write('\n## Examples of Unsplittable Names\n')
        count = 0
        for show in data:
             name = show.get('name', '')
             if len(re.split(r'\s+at\s+', name, maxsplit=1, flags=re.IGNORECASE)) <= 1:
                f.write(f"- {name}\n")
                count += 1
                if count >= 20:
                    break
                    
    print(f"Report generated: {output_file}")

if __name__ == '__main__':
    main()
