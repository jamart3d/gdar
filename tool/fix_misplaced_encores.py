import json
import os

INPUT_FILE = 'assets/data/output.optimized_src.json'
OUTPUT_FILE = 'assets/data/output.optimized_src_fixed_encores.json'
REPORT_FILE = 'report_misplaced_encores_fixed.md'

# Tracks that are DEFINITELY not encore openers if followed by another song.
# They almost always belong to the end of the previous set.
TRACKS_TO_MOVE = {
    "sugar magnolia",
    "one more saturday night",
    "turn on your lovelight",
    "turn on your love light",
    "not fade away",
    "johnny b. goode",
    "us blues",
    "u.s. blues",
    "casey jones",
    "good lovin",
    "good lovin'",
    "around and around",
    "around & around",
    "morning dew",
    "uncle john's band",
    "uncle johns band",
    "playing in the band",
    "shakedown street",
    "alabama getaway",
    "black muddy river",
    "don't ease me in",
    # Specific dirty names from report
    "one more saturday night-",
    "turn on your lovelight *",
    "good lovin 5", 
    "knockin' on heaven's door"
}

def main():
    if not os.path.exists(INPUT_FILE):
        print(f"Error: {INPUT_FILE} not found.")
        return

    print(f"Loading {INPUT_FILE}...")
    with open(INPUT_FILE, 'r', encoding='utf-8') as f:
        data = json.load(f)

    moves = []

    for show in data:
        show_date = show.get('date', 'Unknown')
        venue = show.get('venue', 'Unknown Venue')
        
        for source in show.get('sources', []):
            shnid = source.get('id', 'Unknown')
            tracks = source.get('tracks', [])
            
            # We need to look at the tracks list and identify the "Encore" boundary
            # The tracks are usually ordered.
            
            # 1. Identify Encore tracks indices
            encore_indices = [i for i, t in enumerate(tracks) if t.get('s', '').lower() == 'encore']
            
            if not encore_indices:
                continue
                
            # 2. Iterate through encore tracks EXCEPT the last one
            # If we move a track, we change its 's' (set) to the set of the track BEFORE the first encore track.
            
            first_encore_index = encore_indices[0]
            if first_encore_index == 0:
                # Encore is the first thing? Unlikely but skip to be safe (no previous set)
                continue
                
            previous_set = tracks[first_encore_index - 1].get('s', 'Unknown Set')
            
            # We only touch tracks that are NOT the very last track of the source
            # (Because the last track of the source IS likely the real encore, even if it is Sugar Mag)
            # effectively: if loop over encore_indices[:-1]
            
            # However, we must be careful. If we list specific names, we only move THOSE.
            
            for idx in encore_indices:
                # If it's the absolute last track of the entire source, we generally assume it IS the encore 
                # (OR the taper didn't record the real encore, but we can't fix that easily).
                # But the user logic is "not in encore set, but the set before".
                
                # Check if this is the last track of the source
                if idx == len(tracks) - 1:
                    continue
                
                track = tracks[idx]
                t_name = track.get('t', '').lower()
                
                # Check if it matches our list
                should_move = False
                for target in TRACKS_TO_MOVE:
                    if target in t_name: # Simple substring check or exact? User said "adding more track names"
                        # Let's do exact match or strict substring to avoid false positives
                        if target == t_name.strip() or t_name.strip().startswith(target): 
                             should_move = True
                             break
                
                if should_move:
                    # Double check: Is the NEXT track also an "Encore"? 
                    # If the next track is Set 1, that would be weird. 
                    # Assuming standard ordering.
                    
                    # Move to previous set
                    old_set = track['s']
                    track['s'] = previous_set
                    
                    moves.append({
                        'date': show_date,
                        'venue': venue,
                        'shnid': shnid,
                        'track': track.get('t'),
                        'from': old_set,
                        'to': previous_set
                    })

    print(f"Moved {len(moves)} tracks.")
    
    print(f"Saving to {OUTPUT_FILE}...")
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, separators=(',', ':'))

    print(f"Generating report {REPORT_FILE}...")
    with open(REPORT_FILE, 'w', encoding='utf-8') as f:
        f.write("# Misplaced Encore Fix Report\n\n")
        f.write(f"**Total Tracks Moved:** {len(moves)}\n\n")
        f.write("| Date | SHNID | Track | From | To |\n")
        f.write("|---|---|---|---|---|\n")
        for m in moves:
            t_safe = m['track'].replace('|', '-')
            f.write(f"| {m['date']} | {m['shnid']} | {t_safe} | {m['from']} | {m['to']} |\n")

    print("Done.")

if __name__ == '__main__':
    main()
