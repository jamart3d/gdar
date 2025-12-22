import json
import sys
from collections import defaultdict

def main():
    path = 'assets/data/output.optimized_src.json'
    print(f"Scanning {path}...")
    
    try:
        with open(path, 'r') as f:
            data = json.load(f)
    except Exception as e:
        print(f"Error: {e}")
        return

    duplicate_counts = 0
    
    for show in data:
        show_name = show.get('name', 'Unknown')
        show_date = show.get('date', 'Unknown')
        sources = show.get('sources', [])
        
        # normalized ID -> count
        id_counts = defaultdict(int)
        
        for s in sources:
            raw_id = s.get('id', '')
            # Normalization: strip whitespace, handle int/string diffs
            norm_id = str(raw_id).strip()
            if not norm_id:
                continue
                
            id_counts[norm_id] += 1
            
        # Check for dupes
        found_dupes = [ids for ids, count in id_counts.items() if count > 1]
        
        if found_dupes:
            duplicate_counts += 1
            print(f"Duplicates in {show_date} ({show_name}): {found_dupes}")

    print(f"\nTotal shows with duplicates: {duplicate_counts}")

if __name__ == '__main__':
    main()
