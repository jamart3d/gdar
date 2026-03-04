import json
import os
from collections import Counter

def analyze_encores():
    input_file = 'assets/data/output.cleaned_trailing.json'
    if not os.path.exists(input_file):
        input_file = 'assets/data/output.cleaned_final.json'
        
    output_report = 'encore_analysis_report.md'

    if not os.path.exists(input_file):
        print(f"Error: {input_file} not found.")
        return

    print(f"Analyzing {input_file}...")
    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # 1. Sources with > 1 set and more and 2 or more tracks in encore
    long_encore_sources = []
    
    # Tally if encore set starts with a track that has a variation of encore in its name
    encore_first_track_with_encore_name_count = 0
    encore_variations_tally = Counter()
    all_first_track_tally = Counter()
    total_long_encores = 0
    long_track_name_tally = Counter()

    # 2. Source with 2 or more sets and no encore
    no_encore_sources = []
    last_track_tally = Counter()

    # 3. Tally for tracks with "encore" in name but NOT in an encore set
    non_encore_set_encore_track_single_set_tally = Counter()
    non_encore_set_encore_track_multi_set_tally = Counter()

    # 4. Tally for Encores starting with "Sugar Magnolia"
    sugar_magnolia_encore_count = 0
    
    # 5. Tally for any Encore set with >= 1 track
    total_encores_populated = 0

    for show in data:
        show_date = show.get('date', 'Unknown Date')
        show_name = show.get('name', 'Unknown Venue')
        
        for source in show.get('sources', []):
            source_id = source.get('id', 'Unknown ID')
            sets = source.get('sets', [])

            # Check for long track names in all sets/tracks & Encore tracks in non-encore sets
            for s in sets:
                set_name = s.get('n', '').lower()
                is_encore_set = 'encore' in set_name
                
                for t in s.get('t', []):
                    t_name = t.get('t', '')
                    if len(t_name) > 60:
                        long_track_name_tally[t_name] += 1
                        
                    # Check for "encore" in track name if set is NOT an encore set
                    if not is_encore_set and 'encore' in t_name.lower():
                        if len(sets) == 1:
                            non_encore_set_encore_track_single_set_tally[t_name] += 1
                        else:
                            non_encore_set_encore_track_multi_set_tally[t_name] += 1
            
            if len(sets) > 1:
                has_encore = False
                
                # Check for long encores using index to access previous set
                for i in range(len(sets)):
                    s = sets[i]
                    set_name = s.get('n', '').lower()
                    tracks = s.get('t', [])
                    
                    if 'encore' in set_name:
                        has_encore = True
                        
                        if len(tracks) >= 1:
                            total_encores_populated += 1
                        
                        # Check if first track is Sugar Magnolia (regardless of set length)
                        if tracks:
                            first_track_name = tracks[0].get('t', '').lower()
                            if 'sugar magnolia' in first_track_name:
                                sugar_magnolia_encore_count += 1

                        if len(tracks) >= 2:
                            total_long_encores += 1
                            
                            # Check first track for "encore" in name
                            if tracks:
                                first_track_name = tracks[0].get('t', '')
                                all_first_track_tally[first_track_name] += 1
                                if 'encore' in first_track_name.lower():
                                    encore_first_track_with_encore_name_count += 1
                                    encore_variations_tally[first_track_name] += 1
                            
                            # Get previous set info
                            prev_set_name = "N/A"
                            prev_set_tracks_list = []
                            if i > 0:
                                prev_set = sets[i-1]
                                prev_set_name = prev_set.get('n', 'Unknown Set')
                                prev_set_tracks_list = [f"{t.get('n', '?')}. {t.get('t', '')}" for t in prev_set.get('t', [])]
                            
                            encore_tracks_list = [f"{t.get('n', '?')}. {t.get('t', '')}" for t in s.get('t', [])]

                            long_encore_sources.append({
                                'date': show_date,
                                'id': source_id,
                                'set_name': s.get('n', ''),
                                'track_count': len(tracks),
                                'first_track': tracks[0].get('t', '') if tracks else 'N/A',
                                'prev_set_name': prev_set_name,
                                'prev_set_tracks': prev_set_tracks_list,
                                'encore_tracks': encore_tracks_list
                            })

                # Check for multiple sets but NO encore
                if not has_encore:
                    no_encore_sources.append({
                        'date': show_date,
                        'id': source_id,
                        'set_count': len(sets)
                    })
                    # Get last track of the last set
                    if sets:
                        last_set = sets[-1]
                        last_set_tracks = last_set.get('t', [])
                        if last_set_tracks:
                            last_track_name = last_set_tracks[-1].get('t', '')
                            last_track_tally[last_track_name] += 1

    # Generate Report
    with open(output_report, 'w', encoding='utf-8') as f:
        f.write("# Encore Analysis Report\n\n")
        f.write(f"**Input File used for analysis:** `{input_file}`\n\n")
        
        f.write("## Summary Stats\n")
        f.write(f"- Total sources with Encore sets (>= 1 track): **{total_encores_populated}**\n")
        f.write(f"- Total sources with Encore sets having >= 2 tracks: **{total_long_encores}**\n")
        f.write(f"- Of those (>=2 tracks), Encore sets starting with a track containing 'encore': **{encore_first_track_with_encore_name_count}**\n")
        f.write(f"- Total Encores starting with 'Sugar Magnolia' (any length): **{sugar_magnolia_encore_count}**\n")
        f.write(f"- Sources with >= 2 sets but NO Encore labeled: **{len(no_encore_sources)}**\n\n")

        f.write("## Tracks with 'Encore' in Name (Non-Encore Sets) - Single Set Sources\n")
        f.write("| Track Name | Count |\n")
        f.write("|---|---|\n")
        for name, count in non_encore_set_encore_track_single_set_tally.most_common():
             f.write(f"| {name} | {count} |\n")
        f.write("\n")

        f.write("## Tracks with 'Encore' in Name (Non-Encore Sets) - Multi Set Sources\n")
        f.write("| Track Name | Count |\n")
        f.write("|---|---|\n")
        for name, count in non_encore_set_encore_track_multi_set_tally.most_common():
             f.write(f"| {name} | {count} |\n")
        f.write("\n")

        f.write("## All 'Encore' Variations in First Track\n")
        f.write("| Track Name | Count |\n")
        f.write("|---|---|\n")
        for name, count in encore_variations_tally.most_common():
             f.write(f"| {name} | {count} |\n")
        f.write("\n")

        f.write("## All First Tracks in Multi-Track Encores\n")
        f.write("| Track Name | Count |\n")
        f.write("|---|---|\n")
        for name, count in all_first_track_tally.most_common():
             f.write(f"| {name} | {count} |\n")
        f.write("\n")

        f.write("## Extra Long Track Names (> 60 chars)\n")
        f.write("| Track Name | Count |\n")
        f.write("|---|---|\n")
        for name, count in long_track_name_tally.most_common():
             f.write(f"| {name} | {count} |\n")
        f.write("\n")

        f.write("## Sources with Multi-Track Encores (>= 2 tracks)\n")
        for item in long_encore_sources:
            f.write(f"### {item['date']} (Source ID: {item['id']})\n")
            f.write(f"- **Previous Set ({item['prev_set_name']})**:\n")
            for track_str in item['prev_set_tracks']:
                f.write(f"    - {track_str}\n")
            f.write(f"- **Encore Set ({item['set_name']})**:\n")
            for track_str in item['encore_tracks']:
                f.write(f"    - {track_str}\n")
            f.write("\n")
        
        f.write("\n## Sources with >= 2 Sets and NO Encore\n")
        f.write("| Date | Source ID | Set Count |\n")
        f.write("|---|---|---|\n")
        for item in no_encore_sources:
            f.write(f"| {item['date']} | {item['id']} | {item['set_count']} |\n")

        f.write("\n## Last Track Tally (for sources with >= 2 sets and no Encore)\n")
        f.write("| Last Track Name | Count |\n")
        f.write("|---|---|\n")
        for track, count in last_track_tally.most_common():
            f.write(f"| {track} | {count} |\n")

    print(f"Analysis complete. Report written to {output_report}")

if __name__ == '__main__':
    analyze_encores()
