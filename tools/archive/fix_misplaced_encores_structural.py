import json
import os
import sys

DEFAULT_INPUT_FILE = 'assets/data/output.optimized_src.json'
DEFAULT_OUTPUT_FILE = 'assets/data/output.fixed_encores.json'

INPUT_FILE = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_INPUT_FILE
OUTPUT_FILE = sys.argv[2] if len(sys.argv) > 2 else DEFAULT_OUTPUT_FILE
REPORT_FILE = 'misplaced_encores_report.md'

MAIN_SETS = {'Set 1', 'Set 2', 'Set 3'}

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

    moves = []
    unlabeled_encores_fixed = []

    for show in data:
        date = show.get('date', 'Unknown')
        
        for source in show.get('sources', []):
            shnid = source.get('id', 'Unknown')
            tracks = source.get('tracks', [])
            
            # PASS 1: Fix tracks with "Encore" in name but not in Encore set
            for i in range(len(tracks)):
                track = tracks[i]
                curr_set = track.get('s', '')
                t_name = track.get('t', '').lower()

                # Check for "Encore" in title but NOT in Encore set
                if curr_set != 'Encore' and 'encore' in t_name:
                    unlabeled_encores_fixed.append({
                        'date': date,
                        'shnid': shnid,
                        'track': track.get('t', ''),
                        'from_set': curr_set,
                        'to_set': 'Encore'
                    })
                    # Apply fix immediately so Structural Fix (Pass 2) sees it as Encore
                    track['s'] = 'Encore'

            
            # PASS 2: Structural Fix (Encore followed by Main Set)
            last_main_set = None
            
            for i in range(len(tracks)):
                track = tracks[i]
                curr_set = track.get('s', '')
                
                # Check if this is a main set
                if curr_set in MAIN_SETS:
                    last_main_set = curr_set
                
                elif curr_set == 'Encore':
                    # Check lookahead for ANY subsequent main set
                    found_next_main = None
                    for j in range(i + 1, len(tracks)):
                        chk_set = tracks[j].get('s', '')
                        if chk_set in MAIN_SETS:
                            found_next_main = chk_set
                            break
                    
                    if found_next_main:
                        # It is misplaced!
                        
                        target_set = last_main_set if last_main_set else found_next_main
                        
                        moves.append({
                            'date': date,
                            'shnid': shnid,
                            'track': track.get('t', ''),
                            'from': curr_set,
                            'to': target_set,
                            'context': f"Prev={last_main_set}, NextFound={found_next_main}"
                        })
                        
                        # Apply fix
                        track['s'] = target_set
                        
                        # Update state: this track is now effectively part of target_set
                        last_main_set = target_set

    print(f"Fixed {len(moves)} structurally misplaced tracks.")
    print(f"Moved {len(unlabeled_encores_fixed)} named 'Encore' tracks to Encore set.")

    print(f"Saving to {OUTPUT_FILE}...")
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, separators=(',', ':'))

    print(f"Generating report {REPORT_FILE}...")
    with open(REPORT_FILE, 'w', encoding='utf-8') as f:
        f.write("# Misplaced Encore Fix Report\n\n")
        
        f.write("## Structurally Misplaced Encores (Moved to Set 1/2/3)\n")
        f.write(f"**Total Moves:** {len(moves)}\n\n")
        f.write("| Date | SHNID | Track | From | To | Context |\n")
        f.write("|---|---|---|---|---|---|\n")
        for m in moves:
            t_safe = m['track'].replace('|', '-') if m['track'] else "Unknown"
            f.write(f"| {m['date']} | {m['shnid']} | {t_safe} | {m['from']} | {m['to']} | {m['context']} |\n")
        
        f.write("\n")
        f.write("## Named 'Encore' Tracks Moved to Encore Set\n")
        f.write(f"**Total Moves:** {len(unlabeled_encores_fixed)}\n\n")
        f.write("| Date | SHNID | Track | From Set | To Set |\n")
        f.write("|---|---|---|---|---|\n")
        for m in unlabeled_encores_fixed:
            t_safe = m['track'].replace('|', '-') if m['track'] else "Unknown"
            f.write(f"| {m['date']} | {m['shnid']} | {t_safe} | {m['from_set']} | {m['to_set']} |\n")

    print("Done.")

if __name__ == '__main__':
    main()
