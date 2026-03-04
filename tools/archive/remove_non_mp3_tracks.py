import json
import os

def clean_tracks():
    input_file = 'assets/data/output.optimized_oldder_src.json'
    output_file = 'assets/data/output.optimized_oldder_src_cleaned.json'
    report_file = 'non_mp3_report.md'

    if not os.path.exists(input_file):
        print(f"Error: {input_file} not found.")
        return

    print(f"Loading {input_file}...")
    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)

    clean_report = []
    total_removed = 0
    sources_affected = 0

    clean_report.append("# 🗑️ Removed Non-MP3 Tracks Report\n")
    clean_report.append(f"> Processing file: `{input_file}`\n")

    for show in data:
        for source in show.get('sources', []):
            sid = source.get('id', 'Unknown ID')
            removed_in_source = []
            
            # Determine where tracks are stored
            if 'sets' in source:
                # We need to iterate sets and modify lists in place
                all_tracks = []
                for s_obj in source['sets']:
                    new_tracks = []
                    for t in s_obj.get('t', []):
                        url = t.get('u', '').lower()
                        if url and not url.endswith('.mp3'):
                            removed_in_source.append(t)
                        else:
                            new_tracks.append(t)
                    s_obj['t'] = new_tracks
                    all_tracks.extend(new_tracks)
                
                # Normalize remaining track numbers
                for idx, t in enumerate(all_tracks):
                    t['n'] = idx + 1

            elif 'tracks' in source:
                new_tracks = []
                for t in source['tracks']:
                    url = t.get('u', '').lower()
                    if url and not url.endswith('.mp3'):
                        removed_in_source.append(t)
                    else:
                        new_tracks.append(t)
                source['tracks'] = new_tracks
                
                # Normalize remaining track numbers
                for idx, t in enumerate(source['tracks']):
                    t['n'] = idx + 1

            if removed_in_source:
                sources_affected += 1
                total_removed += len(removed_in_source)
                clean_report.append(f"### 🎵 Source ID: {sid}")
                clean_report.append(f"Removed **{len(removed_in_source)}** tracks:")
                clean_report.append("| # | Title | URL |")
                clean_report.append("| :-- | :--- | :--- |")
                for t in removed_in_source:
                    clean_report.append(f"| {t.get('n', '?')} | {t.get('t', 'Unknown')} | `{t.get('u', '')}` |")
                
                # Report remaining tracks (which are now all_tracks or source['tracks'])
                current_tracks = []
                if 'sets' in source:
                    # all_tracks was populated in the sets block above
                    current_tracks = all_tracks
                elif 'tracks' in source:
                    current_tracks = source['tracks']
                
                if current_tracks:
                    clean_report.append(f"\n**Remaining Normalized Tracks ({len(current_tracks)}):**")
                    clean_report.append("| # | Title | URL |")
                    clean_report.append("| :-- | :--- | :--- |")
                    for t in current_tracks:
                         clean_report.append(f"| {t.get('n', '?')} | {t.get('t', 'Unknown')} | `{t.get('u', '')}` |")
                
                clean_report.append("\n")

    clean_report.insert(2, f"- **Total Sources Affected:** {sources_affected}")
    clean_report.insert(3, f"- **Total Tracks Removed:** {total_removed}\n")

    if total_removed == 0:
        clean_report.append("*No non-mp3 tracks were found.*")

    print(f"Saving report to {report_file}...")
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write("\n".join(clean_report))

    print(f"Saving cleaned data to {output_file}...")
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, separators=(',', ':'))

    print(f"Done. Removed {total_removed} tracks from {sources_affected} sources.")

if __name__ == "__main__":
    clean_tracks()
