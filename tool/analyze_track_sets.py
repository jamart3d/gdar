import json
import os

def main():
    input_file = 'assets/data/output.optimized_src.json'
    if not os.path.exists(input_file):
        print(f"Error: {input_file} not found.")
        return

    file_size = os.path.getsize(input_file)
    with open(input_file, 'r') as f:
        data = json.load(f)

    total_tracks = 0
    set_attr_bytes = 0
    total_sources = 0
    set_changes = 0
    
    all_sets = []

    for show in data:
        for source in show.get('sources', []):
            total_sources += 1
            last_set = None
            source_tracks = source.get('tracks', [])
            for track in source_tracks:
                total_tracks += 1
                set_name = str(track.get('s', ''))
                all_sets.append(set_name)
                
                # Calculation: '"s":"Set 1"' or '"s":"Encore"'
                # This contributes roughly len(set_name) + 5 bytes (key "s", quotes, colon, quotes around value)
                # Plus a comma if it's not the last element, but we'll stick to a baseline.
                set_attr_bytes += len(set_name) + 5
                
                if set_name != last_set:
                    set_changes += 1
                    last_set = set_name

    # Optimization Estimate:
    # Instead of "tracks": [{"s":"Set 1", ...}, {"s":"Set 1", ...}]
    # We use "sets": [{"n":"Set 1", "t":[...]}, {"n":"Encore", "t":[...]}]
    # Each set object adds roughly: '{"n":"","t":[]}' -> 12 bytes + len(set_name)
    # The savings would be: set_attr_bytes - (set_changes * (12 + avg_set_name_len))
    
    avg_set_name_len = sum(len(s) for s in all_sets) / len(all_sets) if all_sets else 0
    est_new_bytes = set_changes * (12 + avg_set_name_len)
    potential_savings = set_attr_bytes - est_new_bytes

    print(f"--- Track Set Analysis ---")
    print(f"Total Tracks: {total_tracks}")
    print(f"Total Sources: {total_sources}")
    print(f"Total 'Set' entries (one per track): {total_tracks}")
    print(f"Unique Set blocks (consecutive tracks in same set): {set_changes}")
    print(f"Estimated overhead from redundant 's' attributes: {set_attr_bytes} bytes")
    print(f"Estimated overhead after optimization: {int(est_new_bytes)} bytes")
    print(f"Potential Savings: {int(potential_savings)} bytes ({potential_savings / file_size * 100:.2f}%)")
    print(f"Current File Size: {file_size} bytes")

if __name__ == '__main__':
    main()
