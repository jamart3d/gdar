import json
import os
import re

INPUT_FILE = 'assets/data/output.fixed_encores.json'
OUTPUT_FILE = 'assets/data/output.fixed_sets.json'
REPORT_FILE = 'fix_sets_report.md'

# Regex patterns
# d2t01, disc2, cd2
RE_SET2 = re.compile(r'(d2t|disc2|cd2|disk2|d02t)', re.IGNORECASE)
RE_SET3 = re.compile(r'(d3t|disc3|cd3|disk3|d03t)', re.IGNORECASE)
# "encore" in filename
RE_ENCORE = re.compile(r'encore', re.IGNORECASE)

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

    total_sources_fixed = 0
    fix_details = []

    for show in data:
        date = show.get('date', 'Unknown')
        
        for source in show.get('sources', []):
            shnid = source.get('id', 'Unknown')
            tracks = source.get('tracks', [])
            
            # Analyze current state
            has_set1 = False
            has_set2 = False
            has_set3 = False
            has_encore = False
            
            for t in tracks:
                s = t.get('s', '')
                if s == 'Set 1': has_set1 = True
                if s == 'Set 2': has_set2 = True
                if s == 'Set 3': has_set3 = True
                if s == 'Encore': has_encore = True
            
            fixes_for_source = []
            
            # Fix Set 2
            if not has_set2:
                for t in tracks:
                     u_val = t.get('u', '')
                     if RE_SET2.search(u_val):
                         # Found a track that looks like Set 2
                         # But wait, we shouldn't overwrite if it's already Set 3 or Encore (unlikely if they follow Set 2)
                         # Assuming if it looks like d2, it IS Set 2 in absence of Set 2 label.
                         # UPDATE: Allow overwriting 'Encore' if filename strongly implies Set 2 AND filename does not say 'encore'
                         curr_s = t.get('s')
                         if curr_s not in ['Set 3']: 
                             # If currently Encore, check if filename is safe
                             if curr_s == 'Encore':
                                  if not RE_ENCORE.search(u_val):
                                      t['s'] = 'Set 2'
                                      fixes_for_source.append(f"Mapped {u_val} (was Encore) to Set 2")
                             else:
                                  t['s'] = 'Set 2'
                                  fixes_for_source.append(f"Mapped {u_val} to Set 2")
            
            # Fix Set 3
            if not has_set3:
                for t in tracks:
                     u_val = t.get('u', '')
                     if RE_SET3.search(u_val):
                         curr_s = t.get('s')
                         if curr_s != 'Set 3': # Assuming d3 is Set 3
                             # Allow overwriting Encore if safe
                             if curr_s == 'Encore':
                                  if not RE_ENCORE.search(u_val):
                                      t['s'] = 'Set 3'
                                      fixes_for_source.append(f"Mapped {u_val} (was Encore) to Set 3")
                             else:
                                 t['s'] = 'Set 3'
                                 fixes_for_source.append(f"Mapped {u_val} to Set 3")
            
            # Fix Encore
            if not has_encore:
                for t in tracks:
                    u_val = t.get('u', '')
                    # Use filename for Encore detection if missing
                    if RE_ENCORE.search(u_val):
                         t['s'] = 'Encore'
                         fixes_for_source.append(f"Mapped {u_val} to Encore")

            if fixes_for_source:
                total_sources_fixed += 1
                # Summarize
                count_s2 = sum(1 for f in fixes_for_source if 'Set 2' in f)
                count_s3 = sum(1 for f in fixes_for_source if 'Set 3' in f)
                count_enc = sum(1 for f in fixes_for_source if 'Encore' in f)
                
                summary = []
                if count_s2: summary.append(f"{count_s2} tracks -> Set 2")
                if count_s3: summary.append(f"{count_s3} tracks -> Set 3")
                if count_enc: summary.append(f"{count_enc} tracks -> Encore")
                
                fix_details.append({
                    'date': date,
                    'shnid': shnid,
                    'summary': ", ".join(summary)
                })

    print(f"Fixed sets in {total_sources_fixed} sources.")

    print(f"Saving to {OUTPUT_FILE}...")
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, separators=(',', ':'))

    print(f"Generating report {REPORT_FILE}...")
    with open(REPORT_FILE, 'w', encoding='utf-8') as f:
        f.write("# Set Fix From Filename Report\n\n")
        f.write(f"**Total Sources Updated:** {total_sources_fixed}\n\n")
        f.write("| Date | SHNID | Changes |\n")
        f.write("|---|---|---|\n")
        
        for item in fix_details:
            f.write(f"| {item['date']} | {item['shnid']} | {item['summary']} |\n")

    print("Done.")

if __name__ == '__main__':
    main()
