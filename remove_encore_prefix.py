import json
import re

INPUT_FILE = 'assets/data/output.optimized_src3.json'
OUTPUT_FILE = 'assets/data/output.optimized_src4.json'
REPORT_FILE = 'encore_prefix_report.md'

def load_json(filepath):
    print(f"Loading {filepath}...")
    with open(filepath, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_json(filepath, data):
    print(f"Saving to {filepath}...")
    with open(filepath, 'w', encoding='utf-8') as f:
        # Minified output as per previous user preference
        json.dump(data, f, separators=(',', ':'))

def extract_venue(show_name):
    match = re.search(r'Grateful Dead Live at (.+?) on \d{4}-\d{2}-\d{2}', show_name)
    if match:
        return match.group(1)
    return "Unknown Venue"

def main():
    data = load_json(INPUT_FILE)
    
    changes = []
    set_moves = []
    
    encoded_prefix_pattern = re.compile(r'^Encore[:\s]+', re.IGNORECASE)
    
    # Exact lowercase matches to skip
    SKIP_EXACT_MATCHES = {
        "encore break",
        "encore break``", 
        "encore break`` ",
        "encore break~~",
        "encore call/break",
        "encore rap",
        "encore call"
    }

    for show in data:
        show_date = show.get('date', 'Unknown Date')
        show_name = show.get('name', '')
        venue = show.get('venue')
        if not venue:
            venue = extract_venue(show_name)
            
        for source in show.get('sources', []):
            source_id = source.get('id', 'Unknown ID')
            tracks = source.get('tracks', [])
            
            # 1. Analyze for "Track before an 'encore' named track" in Encore set and MOVE it
            # Iterate copy or handle index carefully. We can modify in place.
            for i in range(1, len(tracks) - 1): # Start at 1 to have a previous track
                current_track = tracks[i]
                next_track = tracks[i+1]
                previous_track = tracks[i-1]
                
                current_set = current_track.get('s', '')
                previous_set = previous_track.get('s', '')

                if 'encore' in current_set.lower():
                    next_track_name = next_track.get('t', '')
                    if 'encore' in next_track_name.lower():
                        # Move this track to the previous set
                        original_set = current_set
                        if original_set != previous_set:
                            current_track['s'] = previous_set
                            set_moves.append({
                                'date': show_date,
                                'venue': venue,
                                'shnid': source_id,
                                'track_name': current_track.get('t', ''),
                                'old_set': original_set,
                                'new_set': previous_set
                            })

            # 2. Name cleaning pass
            for track in tracks:
                original_title = track.get('t', '')
                
                # Skip requested variations
                if original_title.strip().lower() in SKIP_EXACT_MATCHES:
                    continue

                new_title = original_title

                # Remove "Encore: " prefix
                new_title = encoded_prefix_pattern.sub('', new_title)

                # Remove "(encore)" substring (case insensitive)
                new_title = re.sub(r'\s*\(encore\)', '', new_title, flags=re.IGNORECASE)

                new_title = new_title.strip()
                
                if new_title != original_title:
                    track['t'] = new_title
                    changes.append({
                        'date': show_date,
                        'venue': venue,
                        'shnid': source_id,
                        'old': original_title,
                        'new': new_title
                    })

    print(f"Found {len(changes)} tracks to update names.")
    print(f"Found {len(set_moves)} tracks to move from Encore set.")
    
    save_json(OUTPUT_FILE, data)
    
    print(f"Generating report {REPORT_FILE}...")
    with open(REPORT_FILE, 'w', encoding='utf-8') as f:
        f.write("# Encore Prefix Removal & Set Fix Report\n\n")
        f.write(f"**Total Track Names Updated:** {len(changes)}\n")
        f.write(f"**Total Tracks Moved from Encore Set:** {len(set_moves)}\n\n")
        
        f.write("## 1. Track Name Changes\n")
        f.write("| Date | Venue | SHNID | Old Name | New Name |\n")
        f.write("|---|---|---|---|---|\n")
        
        for item in changes:
            # Escape pipes
            venue_safe = item['venue'].replace('|', '-') if item['venue'] else "Unknown"
            old_safe = item['old'].replace('|', '-')
            new_safe = item['new'].replace('|', '-')
            f.write(f"| {item['date']} | {venue_safe} | {item['shnid']} | {old_safe} | {new_safe} |\n")
            
        f.write("\n" + "="*80 + "\n\n")
        f.write("## 2. Tracks Moved from Encore Set\n")
        f.write("*(Condition: In 'Encore' set but followed by track with 'encore' in name)*\n\n")
        f.write("| Date | Venue | SHNID | Track Name | Old Set | New Set |\n")
        f.write("|---|---|---|---|---|---|\n")
        
        for item in set_moves:
            venue_safe = item['venue'].replace('|', '-') if item['venue'] else "Unknown"
            t_safe = item['track_name'].replace('|', '-')
            f.write(f"| {item['date']} | {venue_safe} | {item['shnid']} | {t_safe} | {item['old_set']} | {item['new_set']} |\n")
            
    print("Done.")

if __name__ == '__main__':
    main()
