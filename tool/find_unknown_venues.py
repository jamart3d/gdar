import json
import re

INPUT_FILE = 'assets/data/output.optimized_src3.json'
OUTPUT_REPORT = 'unknown.md'

# List of strings that qualify as "Unknown"
UNKNOWN_INDICATORS = [
    "unknown",
    "unknown venue",
    "unknown location",
    "various"
]

def is_unknown(venue):
    if not venue: return True
    v = venue.strip().lower()
    # Check for exact matches or containing strict unknown phrases
    for indicator in UNKNOWN_INDICATORS:
        if indicator in v:
            return True
    return False

def extract_venue(show_name):
    # Format: Grateful Dead Live at [Venue] on [Date]
    match = re.search(r'Grateful Dead Live at (.+?) on \d{4}-\d{2}-\d{2}', show_name)
    if match:
        return match.group(1)
    return ""

def main():
    print(f"Loading {INPUT_FILE}...")
    try:
        with open(INPUT_FILE, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        print(f"Error loading file: {e}")
        return

    unknown_list = []
    
    for show in data:
        name = show.get('name', '')
        date = show.get('date', 'Unknown Date')
        
        # Try to get venue from field first, then fallback to parsing name
        venue = show.get('venue', '')
        if not venue:
            venue = extract_venue(name)
        
        if is_unknown(venue):
            unknown_list.append({
                'date': date,
                'name': name,
                'venue': venue
            })
    
    count = len(unknown_list)
    print(f"Found {count} shows with unknown venues.")

    print(f"Generating {OUTPUT_REPORT}...")
    with open(OUTPUT_REPORT, 'w', encoding='utf-8') as f:
        f.write("# Unknown Venues Report\n\n")
        f.write(f"**Total Shows with Unknown Venue:** {count}\n\n")
        f.write("| Date | Show Name | Extracted Venue |\n")
        f.write("|---|---|---|\n")
        
        for item in unknown_list:
            # Escape pipes for markdown table
            name = item['name'].replace('|', '-')
            venue_val = item['venue'].replace('|', '-') if item['venue'] else "(empty)"
            f.write(f"| {item['date']} | {name} | {venue_val} |\n")
    
    print("Done.")

if __name__ == '__main__':
    main()
