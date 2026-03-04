import json
import os

def main():
    input_path = 'assets/data/output.optimized_src1.json'
    output_path = 'assets/data/output.optimized_src2.json'
    
    if not os.path.exists(input_path):
        print(f"Error: {input_path} not found.")
        return

    print(f"Loading data from {input_path}...")
    with open(input_path, 'r') as f:
        shows = json.load(f)

    count = 0
    
    print("Scanning and cleaning track names...")
    
    fixed_items = []
    
    for show in shows:
        show_name = show.get('name', 'Unknown Show')
        show_date = show.get('date', 'Unknown Date')
        for source in show.get('sources', []):
            source_id = source.get('id', 'Unknown ID')
            for track in source.get('tracks', []):
                title = track.get('t', '')
                # Check for &amp or &amp;
                if '&amp' in title:
                    # Replace &amp; first to handle the semicolon version correctly
                    # Then replace &amp to handle cases missing the semicolon
                    new_title = title.replace('&amp;', '&').replace('&amp', '&')
                    
                    if new_title != title:
                        # print(f"Fixing: '{title}' -> '{new_title}'")
                        track['t'] = new_title
                        count += 1
                        fixed_items.append({
                            'date': show_date,
                            'show': show_name,
                            'source': source_id,
                            'old': title,
                            'new': new_title
                        })

    print(f"Fixed {count} track names containing '&amp'.")
    
    report_path = 'report_amp_fix.md'
    print(f"Generating report at {report_path}...")
    with open(report_path, 'w') as f:
        f.write("# Track Name Cleanup Report (&amp; -> &)\n\n")
        f.write(f"**Total Tracks Fixed:** {count}\n\n")
        
        if fixed_items:
            f.write("| Date | Show Name | Source ID | Old Title | New Title |\n")
            f.write("|---|---|---|---|---|\n")
            for item in fixed_items:
                f.write(f"| {item['date']} | {item['show']} | {item['source']} | {item['old']} | {item['new']} |\n")
        else:
            f.write("No tracks found containing '&amp'.\n")

    print(f"Saving cleaned data to {output_path}...")
    with open(output_path, 'w') as f:
        json.dump(shows, f, separators=(',', ':')) # Minified

    print("Done!")

if __name__ == "__main__":
    main()
