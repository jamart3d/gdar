import json
import os
import re

INPUT_FILE = 'assets/data/output.fixed_encores.json'
REPORT_FILE = 'filename_pattern_report.md'

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

    # Pattern: "d" followed by digit(s), "t" followed by digit(s)
    # e.g. "d1t01", "d02t12", "D1T06"
    pattern = re.compile(r'd\d+t\d+', re.IGNORECASE)

    total_tracks = 0
    matched_tracks = 0
    
    total_shows = 0
    shows_with_pattern = 0
    
    # subsets of shows_with_pattern
    shows_pat_with_set1 = 0
    shows_pat_with_set2 = 0
    shows_pat_with_set3 = 0
    shows_pat_with_encore = 0
    shows_pat_missing_set1 = 0
    shows_pat_missing_set2 = 0
    shows_pat_missing_set3 = 0
    shows_pat_missing_encore = 0
    shows_pat_no_set23enc = 0 # Pattern matches, but NO Set 2, NO Set 3, NO Encore

    # Optional: Breakdown by disc number (d1, d2, etc.)
    disc_counts = {}

    for show in data:
        total_shows += 1
        show_has_pattern = False
        show_has_set1 = False
        show_has_set2 = False
        show_has_set3 = False
        show_has_encore = False
        
        for source in show.get('sources', []):
            tracks = source.get('tracks', [])
            
            # Check sets in this source
            for t in tracks:
                s_label = t.get('s', '')
                if s_label == 'Set 1': show_has_set1 = True
                if s_label == 'Set 2': show_has_set2 = True
                if s_label == 'Set 3': show_has_set3 = True
                if s_label == 'Encore': show_has_encore = True
            
            # Check pattern
            for track in tracks:
                total_tracks += 1
                u_val = track.get('u', '')
                
                match = pattern.search(u_val)
                if match:
                    matched_tracks += 1
                    show_has_pattern = True
                    
                    # Extract "d1", "d2" part for breakdown
                    matched_str = match.group().lower()
                    disc_part = re.match(r'd\d+', matched_str).group()
                    disc_counts[disc_part] = disc_counts.get(disc_part, 0) + 1

        if show_has_pattern:
            shows_with_pattern += 1
            if show_has_set1: shows_pat_with_set1 += 1
            else: shows_pat_missing_set1 += 1

            if show_has_set2:
                shows_pat_with_set2 += 1
                # Only check for missing Set 3 if we HAVE Set 2
                if show_has_set3: shows_pat_with_set3 += 1
                else: shows_pat_missing_set3 += 1
            else: 
                shows_pat_missing_set2 += 1
                # If missing Set 2, we don't care about missing Set 3 (per user request)
                # But we might still track if it *has* Set 3 despite missing Set 2 (unlikely but possible)
                if show_has_set3: shows_pat_with_set3 += 1
            
            if show_has_encore: shows_pat_with_encore += 1
            else: shows_pat_missing_encore += 1
            
            if not show_has_set2 and not show_has_set3 and not show_has_encore:
                shows_pat_no_set23enc += 1

    print(f"Generating {REPORT_FILE}...")
    with open(REPORT_FILE, 'w', encoding='utf-8') as f:
        f.write("# Filename Pattern Analysis Report\n\n")
        f.write(f"- **Total Shows**: {total_shows}\n")
        f.write(f"- **Shows with matching filenames (*dXtY*)**: {shows_with_pattern} ({(shows_with_pattern/total_shows*100) if total_shows else 0:.2f}%)\n\n")
        
        if shows_with_pattern > 0:
            f.write("### Breakdown of Matched Shows\n")
            f.write(f"- With **Set 1**: {shows_pat_with_set1} ({(shows_pat_with_set1/shows_with_pattern*100):.2f}%)\n")
            f.write(f"- **MISSING Set 1**: {shows_pat_missing_set1} ({(shows_pat_missing_set1/shows_with_pattern*100):.2f}%)\n")
            f.write(f"- With **Set 2**: {shows_pat_with_set2} ({(shows_pat_with_set2/shows_with_pattern*100):.2f}%)\n")
            f.write(f"- **MISSING Set 2**: {shows_pat_missing_set2} ({(shows_pat_missing_set2/shows_with_pattern*100):.2f}%)\n")
            f.write(f"- With **Set 3**: {shows_pat_with_set3} ({(shows_pat_with_set3/shows_with_pattern*100):.2f}%)\n")
            f.write(f"- With **Encore**: {shows_pat_with_encore} ({(shows_pat_with_encore/shows_with_pattern*100):.2f}%)\n")
            f.write(f"- **MISSING Encore**: {shows_pat_missing_encore} ({(shows_pat_missing_encore/shows_with_pattern*100):.2f}%)\n")
            f.write(f"- **MISSING Set 2, Set 3, AND Encore**: {shows_pat_no_set23enc} ({(shows_pat_no_set23enc/shows_with_pattern*100):.2f}%)\n\n")

        f.write(f"### Track Stats\n")
        f.write(f"- **Total Tracks Scanned**: {total_tracks}\n")
        f.write(f"- **Tracks matching pattern**: {matched_tracks}\n")
        f.write(f"- **Percentage**: {(matched_tracks/total_tracks)*100:.2f}%\n\n")
        
        f.write("### Breakdown by Disc Number\n")
        # Sort by disc number (numerical sort)
        sorted_discs = sorted(disc_counts.keys(), key=lambda x: int(x[1:]))
        for d in sorted_discs:
            f.write(f"- **{d}**: {disc_counts[d]}\n")

    print("Done.")

if __name__ == '__main__':
    main()
