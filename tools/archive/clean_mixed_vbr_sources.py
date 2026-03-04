import json
import os

INPUT_FILE = 'assets/data/output.optimized_src.json'
OUTPUT_FILE = 'assets/data/output.optimized_src_vbr_cleaned.json'
REPORT_FILE = 'vbr_cleaning_report.md'

def main():
    if not os.path.exists(INPUT_FILE):
        print(f"Error: {INPUT_FILE} not found.")
        return

    print(f"Loading {INPUT_FILE}...")
    with open(INPUT_FILE, 'r', encoding='utf-8') as f:
        data = json.load(f)

    cleaned_sources = []
    total_removed = 0

    for show in data:
        date = show.get('date', 'Unknown')
        for source in show.get('sources', []):
            shnid = source.get('id', 'Unknown')
            tracks = source.get('tracks', [])
            
            if not tracks:
                continue
                
            vbr_tracks = []
            non_vbr_tracks = []
            
            for t in tracks:
                url = t.get('u', '').lower()
                if '_vbr.mp3' in url:
                    vbr_tracks.append(t)
                else:
                    non_vbr_tracks.append(t)
            
            # If it's a mixed set, remove the VBR ones
            if vbr_tracks and non_vbr_tracks:
                original_count = len(tracks)
                source['tracks'] = non_vbr_tracks
                total_removed += len(vbr_tracks)
                cleaned_sources.append({
                    'date': date,
                    'shnid': shnid,
                    'removed_count': len(vbr_tracks),
                    'remaining_count': len(non_vbr_tracks),
                    'original_count': original_count,
                    'removed_tracks': [f"{t.get('t', '').strip()} ({t.get('d', 0)}s) [URL: {t.get('u', '')}]" for t in vbr_tracks]
                })

    print(f"Cleaned {len(cleaned_sources)} mixed sources. Removed {total_removed} VBR tracks.")
    
    print(f"Saving to {OUTPUT_FILE}...")
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, separators=(',', ':'))

    print(f"Generating {REPORT_FILE}...")
    with open(REPORT_FILE, 'w', encoding='utf-8') as f:
        f.write("# Mixed VBR Cleaning Report\n\n")
        f.write(f"This report details the removal of `_vbr.mp3` tracks from sources that also contained standard quality tracks.\n\n")
        f.write(f"- **Total Mixed Sources Cleaned:** {len(cleaned_sources)}\n")
        f.write(f"- **Total VBR Tracks Removed:** {total_removed}\n\n")
        f.write("---\n\n")

        for s in cleaned_sources:
            f.write(f"## {s['date']} (SHNID: {s['shnid']})\n")
            f.write(f"- **Original Track Count:** {s['original_count']}\n")
            f.write(f"- **VBR Tracks Removed:** {s['removed_count']}\n")
            f.write(f"- **Standard Tracks Remaining:** {s['remaining_count']}\n\n")
            
            f.write("<details>\n")
            f.write("<summary>View Removed VBR Tracks</summary>\n\n")
            for t in s['removed_tracks']:
                f.write(f"- {t}\n")
            f.write("\n</details>\n\n")
            f.write("---\n\n")

    print("Done.")

if __name__ == '__main__':
    main()
