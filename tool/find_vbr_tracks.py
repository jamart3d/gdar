import json
import os

INPUT_FILE = 'assets/data/output.optimized_src.json'
REPORT_FILE = 'vbr_report.md'

def main():
    if not os.path.exists(INPUT_FILE):
        print(f"Error: {INPUT_FILE} not found. Run fix_duplicate_tracks.py first.")
        return

    print(f"Loading {INPUT_FILE}...")
    with open(INPUT_FILE, 'r', encoding='utf-8') as f:
        data = json.load(f)

    vbr_shows = []
    total_vbr_tracks = 0

    for show in data:
        date = show.get('date', 'Unknown')
        show_vbr_tracks = []
        
        for source in show.get('sources', []):
            shnid = source.get('id', 'Unknown')
            for track in source.get('tracks', []):
                url = track.get('u', '')
                if '_vbr' in url.lower():
                    show_vbr_tracks.append({
                        'shnid': shnid,
                        'track': track.get('t', 'Unknown'),
                        'url': url,
                        'duration': track.get('d', 0)
                    })
        
        if show_vbr_tracks:
            vbr_shows.append({
                'date': date,
                'tracks': show_vbr_tracks
            })
            total_vbr_tracks += len(show_vbr_tracks)

    print(f"Found {total_vbr_tracks} VBR tracks across {len(vbr_shows)} shows.")
    print(f"Generating {REPORT_FILE}...")

    with open(REPORT_FILE, 'w', encoding='utf-8') as f:
        f.write("# VBR Track Report\n\n")
        f.write(f"This report lists all tracks in `{INPUT_FILE}` that still use `_vbr` MP3 files.\n\n")
        f.write(f"- **Total Shows with VBR:** {len(vbr_shows)}\n")
        f.write(f"- **Total VBR Tracks:** {total_vbr_tracks}\n\n")
        f.write("---\n\n")

        for show in vbr_shows:
            f.write(f"## {show['date']}\n")
            f.write(f"Found {len(show['tracks'])} VBR tracks:\n\n")
            f.write("| SHNID | Track Name | Duration | URL |\n")
            f.write("|-------|------------|----------|-----|\n")
            for t in show['tracks']:
                f.write(f"| {t['shnid']} | {t['track']} | {t['duration']}s | `{t['url']}` |\n")
            f.write("\n---\n\n")

    print("Done.")

if __name__ == '__main__':
    main()
