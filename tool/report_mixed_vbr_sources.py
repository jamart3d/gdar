import json
import os

INPUT_FILE = 'assets/data/output.optimized_src.json'
REPORT_FILE = 'mixed_vbr_report.md'

def main():
    if not os.path.exists(INPUT_FILE):
        print(f"Error: {INPUT_FILE} not found.")
        return

    print(f"Loading {INPUT_FILE}...")
    with open(INPUT_FILE, 'r', encoding='utf-8') as f:
        data = json.load(f)

    mixed_sources = []

    for show in data:
        date = show.get('date', 'Unknown')
        for source in show.get('sources', []):
            shnid = source.get('id', 'Unknown')
            tracks = source.get('tracks', [])
            
            if not tracks:
                continue
                
            has_vbr = False
            has_non_vbr = False
            vbr_count = 0
            non_vbr_count = 0
            
            for t in tracks:
                url = t.get('u', '').lower()
                if '_vbr.mp3' in url:
                    has_vbr = True
                    vbr_count += 1
                else:
                    has_non_vbr = True
                    non_vbr_count += 1
            
            if has_vbr and has_non_vbr:
                mixed_sources.append({
                    'date': date,
                    'shnid': shnid,
                    'vbr_count': vbr_count,
                    'non_vbr_count': non_vbr_count,
                    'total_count': len(tracks)
                })

    print(f"Found {len(mixed_sources)} sources with mixed VBR/non-VBR tracks.")
    print(f"Generating {REPORT_FILE}...")

    with open(REPORT_FILE, 'w', encoding='utf-8') as f:
        f.write("# Mixed VBR/Non-VBR Source Report\n\n")
        f.write(f"This report lists sources in `{INPUT_FILE}` that contain both `_vbr.mp3` and standard mp3 URLs.\n\n")
        f.write(f"- **Total Mixed Sources Found:** {len(mixed_sources)}\n\n")
        
        f.write("| Date | SHNID | VBR Tracks | Non-VBR Tracks | Total Tracks |\n")
        f.write("|------|-------|------------|----------------|--------------|\n")
        
        for s in mixed_sources:
            f.write(f"| {s['date']} | {s['shnid']} | {s['vbr_count']} | {s['non_vbr_count']} | {s['total_count']} |\n")

    print("Done.")

if __name__ == '__main__':
    main()
