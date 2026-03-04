import json

def main():
    path = 'assets/data/output.optimized_src.json'
    target_date = '1971-08-06'
    
    with open(path, 'r') as f:
        data = json.load(f)
        
    entries = [s for s in data if s.get('date') == target_date]
    print(f"Entries for {target_date}: {len(entries)}")
    
    all_shnids = []
    for i, entry in enumerate(entries):
        shnids = [s.get('id') for s in entry.get('sources', [])]
        print(f"Entry {i} sources: {shnids}")
        all_shnids.extend(shnids)
        
    print(f"Total SHNIDs: {len(all_shnids)}")
    print(f"Unique SHNIDs: {len(set(all_shnids))}")
    if len(all_shnids) != len(set(all_shnids)):
        print("DUPLICATES DETECTED via merge simulation!")

if __name__ == '__main__':
    main()
