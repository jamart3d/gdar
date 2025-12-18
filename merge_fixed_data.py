import json
import sys

ORIGINAL_FILE = 'assets/data/output.optimized_src1.json'
FIXED_FILE = 'assets/data/output.optimized_src.fixed2.json'
OUTPUT_FILE = 'assets/data/output.optimized_src3.json'

def main():
    print(f"Loading original data from {ORIGINAL_FILE}...")
    try:
        with open(ORIGINAL_FILE, 'r', encoding='utf-8') as f:
            original_shows = json.load(f)
    except Exception as e:
        print(f"Error loading original file: {e}")
        return

    print(f"Loading fixed data from {FIXED_FILE}...")
    try:
        with open(FIXED_FILE, 'r', encoding='utf-8') as f:
            fixed_shows = json.load(f)
    except Exception as e:
        print(f"Error loading fixed file: {e}")
        return

    print(f"Original shows: {len(original_shows)}")
    print(f"Fixed/Clean shows: {len(fixed_shows)}")

    # Create a map for fast lookup of fixed shows
    # Keying by date + name to ensure uniqueness
    fixed_map = {}
    for show in fixed_shows:
        key = (show.get('date'), show.get('name'))
        fixed_map[key] = show

    merged_shows = []
    updated_count = 0
    preserved_count = 0
    
    print("Merging data...")
    for show in original_shows:
        key = (show.get('date'), show.get('name'))
        
        if key in fixed_map:
            # Found a fixed (or verified clean) version
            merged_shows.append(fixed_map[key])
            updated_count += 1
            # Optional: Check if it was actually different to count "real" fixes vs "clean" matches
            # But for now, we just track that we used the version from the clean set.
        else:
            # Not in fixed set (likely in review set), keep original
            merged_shows.append(show)
            preserved_count += 1

    print("-" * 40)
    print(f"Merge Complete.")
    print(f"Total Combined Shows: {len(merged_shows)}")
    print(f"Shows from Fixed File: {updated_count}")
    print(f"Shows Retained from Original (Review/Missing): {preserved_count}")
    print("-" * 40)

    print(f"Saving to {OUTPUT_FILE}...")
    try:
        with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
            json.dump(merged_shows, f, separators=(',', ':'))
        print("Success!")
    except Exception as e:
        print(f"Error saving output file: {e}")

if __name__ == '__main__':
    main()
