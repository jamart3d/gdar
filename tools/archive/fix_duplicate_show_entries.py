import json
import os

INPUT_FILE = 'assets/data/output.optimized_src.json'
OUTPUT_FILE = 'assets/data/output.deduped.json'

def main():
    if not os.path.exists(INPUT_FILE):
        print(f"Error: {INPUT_FILE} not found.")
        return

    print(f"Loading {INPUT_FILE}...")
    with open(INPUT_FILE, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    print(f"Original entries: {len(data)}")

    # Map Date -> Show Object
    shows_by_date = {}

    for entry in data:
        date = entry.get('date')
        if not date:
            continue

        if date not in shows_by_date:
            # First time seeing this date: Use this entry as the base
            # Ensure sources specific sorting/deduplication later
            shows_by_date[date] = entry
            # Ensure sources is a list (sanity check)
            if 'sources' not in shows_by_date[date]:
                 shows_by_date[date]['sources'] = []
        else:
            # Date exists: Merge sources into the existing entry
            existing_show = shows_by_date[date]
            new_sources = entry.get('sources', [])
            
            # We will deduplicate later, for now just extend
            existing_show['sources'].extend(new_sources)
            
            # Optional: Merge other fields if missing?
            # For now, assuming Name/Venue are consistent or the first one is fine.
            if not existing_show.get('venue') and entry.get('venue'):
                existing_show['venue'] = entry.get('venue')

    # Now verify and deduplicate sources for every merged show
    final_shows = []
    
    total_dupes_removed = 0

    # Sort dates to ensure final list is ordered
    sorted_dates = sorted(shows_by_date.keys())

    for date in sorted_dates:
        show = shows_by_date[date]
        sources = show.get('sources', [])
        
        unique_sources = []
        seen_ids = set()
        
        for source in sources:
            shnid = source.get('id')
            # If shnid is missing, we might keep it or warn. Let's keep it if src exists?
            # Usually strict id is good.
            if not shnid: 
                 # Fallback for no ID? Just add it? 
                 # Or skip. Let's count it as unique if we can't ident it.
                 # Actually, let's treat it as distinct.
                 unique_sources.append(source)
                 continue

            if shnid in seen_ids:
                total_dupes_removed += 1
                continue
            
            seen_ids.add(shnid)
            unique_sources.append(source)
        
        # Sort sources by ID
        unique_sources.sort(key=lambda s: s.get('id', ''))
        
        show['sources'] = unique_sources
        final_shows.append(show)

    print(f"Final merged shows: {len(final_shows)}")
    print(f"Total duplicate sources removed: {total_dupes_removed}")
    
    print(f"Saving to {OUTPUT_FILE} (Minified)...")
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(final_shows, f, separators=(',', ':'))
    
    print("Done.")

if __name__ == '__main__':
    main()
