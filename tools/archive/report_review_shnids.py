import json
import os

INPUT_FILE = 'shows_needing_review.json'
OUTPUT_FILE = 'review_shnids_lex.txt'

def main():
    if not os.path.exists(INPUT_FILE):
        print(f"Error: {INPUT_FILE} not found.")
        return

    print(f"Loading {INPUT_FILE}...")
    try:
        with open(INPUT_FILE, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        print(f"Error reading JSON: {e}")
        return

    shnids = set()
    
    # Collect all source IDs
    for show in data:
        for source in show.get('sources', []):
            shnid = source.get('id')
            if shnid:
                shnids.add(str(shnid))

    print(f"Found {len(shnids)} unique SHNIDs.")

    # Sort lexicographically (string sort)
    # This ensures "10" comes before "2", grouping prefixes together
    sorted_shnids = sorted(list(shnids))

    print(f"Saving sorted list to {OUTPUT_FILE}...")
    try:
        with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
            for shnid in sorted_shnids:
                f.write(f"{shnid}\n")
        print("Success!")
        
        # Print first 10 as preview
        print("\nFirst 10 IDs:")
        for sid in sorted_shnids[:10]:
            print(sid)
            
    except Exception as e:
        print(f"Error writing output: {e}")

if __name__ == '__main__':
    main()
