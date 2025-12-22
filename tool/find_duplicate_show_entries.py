import json
from collections import defaultdict

def main():
    path = 'assets/data/output.deduped.json'
    print(f"Scanning {path} for duplicate show entries...")
    
    try:
        with open(path, 'r') as f:
            data = json.load(f)
    except Exception as e:
        print(f"Error: {e}")
        return

    date_counts = defaultdict(int)
    duplicate_dates = []

    for show in data:
        date = show.get('date', 'Unknown')
        date_counts[date] += 1
    
    for date, count in date_counts.items():
        if count > 1:
            duplicate_dates.append((date, count))
            
    if duplicate_dates:
        print(f"Found {len(duplicate_dates)} dates with multiple entries:")
        for date, count in duplicate_dates[:10]:
            print(f"  {date}: {count} entries")
        if len(duplicate_dates) > 10:
            print("  ...")
    else:
        print("No duplicate show entries found (unique dates for all entries).")

if __name__ == '__main__':
    main()
