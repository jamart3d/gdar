import json
from collections import Counter

def load_data(filepath):
    try:
        with open(filepath, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"File not found: {filepath}")
        return []

def get_stats(data):
    stats = {
        'total_shows': len(data),
        'total_sources': 0,
        'unique_venues': set(),
        'src_counts': Counter()
    }
    
    for show in data:
        # Venue
        venue = show.get('name', '').strip()
        stats['unique_venues'].add(venue)
        
        # Sources
        sources = show.get('sources', [])
        stats['total_sources'] += len(sources)
        
        # Src Categories
        for source in sources:
            src = source.get('src')
            stats['src_counts'][str(src)] += 1
            
    return stats

def main():
    original_file = 'assets/data/output.optimized_src.json'
    new_file = 'assets/data/output.optimized_src_strict.json'
    
    print(f"Loading Original: {original_file}")
    org_data = load_data(original_file)
    print(f"Loading New (Cleaned): {new_file}")
    new_data = load_data(new_file)
    
    org_stats = get_stats(org_data)
    new_stats = get_stats(new_data)
    
    print("\n--- COMPARISON REPORT ---\n")
    
    print(f"{'Metric':<25} | {'Original':<10} | {'New':<10} | {'Diff':<10}")
    print("-" * 65)
    
    # Shows
    diff_shows = new_stats['total_shows'] - org_stats['total_shows']
    print(f"{'Total Shows':<25} | {org_stats['total_shows']:<10} | {new_stats['total_shows']:<10} | {diff_shows:<10}")
    
    # Sources
    diff_sources = new_stats['total_sources'] - org_stats['total_sources']
    print(f"{'Total Sources':<25} | {org_stats['total_sources']:<10} | {new_stats['total_sources']:<10} | {diff_sources:<10}")
    
    # Venues
    org_venues = len(org_stats['unique_venues'])
    new_venues = len(new_stats['unique_venues'])
    diff_venues = new_venues - org_venues
    print(f"{'Unique Venues':<25} | {org_venues:<10} | {new_venues:<10} | {diff_venues:<10}")
    
    print("\n--- Source Categories (src) ---\n")
    print(f"{'Category':<25} | {'Original':<10} | {'New':<10} | {'Diff':<10}")
    print("-" * 65)
    
    # Combine all keys
    all_keys = set(org_stats['src_counts'].keys()) | set(new_stats['src_counts'].keys())
    
    # Sort by count descending (using new stats)
    sorted_keys = sorted(all_keys, key=lambda k: new_stats['src_counts'][k], reverse=True)
    
    for k in sorted_keys:
        v_org = org_stats['src_counts'][k]
        v_new = new_stats['src_counts'][k]
        diff = v_new - v_org
        print(f"{k:<25} | {v_org:<10} | {v_new:<10} | {diff:<10}")

if __name__ == "__main__":
    main()
