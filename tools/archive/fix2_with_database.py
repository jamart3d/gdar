import json
try:
    import requests
    from bs4 import BeautifulSoup
    HAS_DEPS = True
except ImportError:
    HAS_DEPS = False

import time
import difflib
import copy
import re
import argparse


# --- CONFIGURATION ---
INPUT_FILENAME = 'input_to_fix.json'
OUTPUT_FILENAME = 'input_to_fix2.json'
REVIEW_FILENAME = 'shows_needing_review.json'

# --- API & DATA SOURCE CONFIGURATION ---
ETREEDB_URL_BASE = "https://etreedb.org"
REQUEST_HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
    'Accept-Language': 'en-US,en;q=0.9',
    'Accept-Encoding': 'gzip, deflate, br',
    'DNT': '1',
    'Upgrade-Insecure-Requests': '1',
}

# --- LOGIC CONFIGURATION ---
NON_MUSIC_TRACKS = ["tuning", "banter", "crowd", "intro", "take a step back"]
VALID_SET_NAMES = ["Set 1", "Set 2", "Set 3", "Encore"]

def print_comparison(old_tracks, new_tracks):
    print(f"\n      {'#':<3} | {'TRACK TITLE':<35} | {'OLD':<25} | {'NEW':<25}")
    print(f"      {'':-^3}-+-{'-':-^35}-+-{'-':-^25}-+-{'-':-^25}")
    for i, (old, new) in enumerate(zip(old_tracks, new_tracks), 1):
        title = old.get('t', '')
        disp_title = (title[:33] + '..') if len(title) > 33 else title
        old_s = old.get('s', 'Set 1')
        new_s = new.get('s', 'Set 1')
        diff_flag = " <== CHANGE" if old_s != new_s else ""
        print(f"      {i:<3} | {disp_title:<35} | {old_s:<25} | {new_s:<25}{diff_flag}")
    print("\n")

# ==============================================================================
#  FILENAME PARSING LOGIC
# ==============================================================================

def parse_set_from_filename(filename):
    # Regex to find d<number>, s<number>, or e<number>
    match = re.search(r'(?:[ds])([1-3])', filename, re.IGNORECASE)
    if match:
        return f"Set {match.group(1)}"
    
    match_encore = re.search(r'e([1-9])', filename, re.IGNORECASE)
    if match_encore:
        return "Encore"
        
    return None

def process_shows_by_filename(shows, test_mode=False, output_filename=None):
    clean_shows = []
    review_shows = []
    review_shnids = [] # List to track specific problem SHNIDs

    for i, show in enumerate(shows):
        if test_mode and i > 0: break

        show_needs_review = False
        show_changed = False
        
        date = show.get("date", "Unknown")
        venue = show.get("venue", "Unknown Venue")
        print("="*80 + f"\nSHOW {i+1}/{len(shows)}: {date} @ {venue} [Filename Mode]")

        for source in show.get("sources", []):
            original_tracks = copy.deepcopy(source.get('tracks', []))
            tracks = source.get('tracks', [])
            source_needs_review = False

            for track in tracks:
                filename = track.get('u', '')
                current_set = track.get('s', 'Set 1')
                
                parsed_set = parse_set_from_filename(filename)
                
                if parsed_set:
                    if current_set != parsed_set:
                        track['s'] = parsed_set
                        show_changed = True
                else:
                    # If any track can't be parsed, the whole show needs review
                    source_needs_review = True
                    break 

            if source_needs_review:
                shnid = source.get('id', 'Unknown')
                print(f"  [REVIEW] Source {shnid} has tracks with unparsable filenames.")
                review_shnids.append(shnid) # Add valid SHNID to list
                show_needs_review = True
                break
            
            if show_changed:
                 print_comparison(original_tracks, tracks)


        if show_needs_review:
            review_shows.append(show)
            print("  [ACTION] Added to review list.")
        elif show_changed:
            clean_shows.append(show)
            print("  [SUCCESS] Show sets updated by filename.")
        else:
            clean_shows.append(show)
            print("  [NO CHANGES] Show is already clean.")

    if not test_mode:
        final_output_filename = output_filename if output_filename else OUTPUT_FILENAME
        if clean_shows:
            with open(final_output_filename, 'w', encoding='utf-8') as f:
                json.dump(clean_shows, f, indent=4)
            print(f"\nSaved {len(clean_shows)} clean shows to {final_output_filename}")

        if review_shows:
            with open(REVIEW_FILENAME, 'w', encoding='utf-8') as f:
                json.dump(review_shows, f, indent=4)
            print(f"Saved {len(review_shows)} shows needing review to {REVIEW_FILENAME}")

            # Save SHNIDs needing review
            shnid_file = "review_shnids.txt"
            
            # Sort lexicographically (as requested: "numerically but not by length")
            # This means '100' comes before '2'
            sorted_shnids = sorted(review_shnids)

            with open(shnid_file, 'w', encoding='utf-8') as f:
                for shnid in sorted_shnids:
                    f.write(f"{shnid}\n")
            print(f"Saved {len(review_shnids)} unique review SHNIDs to {shnid_file} (Lexicographical Sort)")


# ==============================================================================
#  ETREEDB LOGIC (UPGRADED)
# ==============================================================================
def get_etreedb_data(session, shnid):
    if not shnid: return None
    print(f"  [ETREEDB] Querying etreedb.org for SHNID {shnid}...")
    url = f"{ETREEDB_URL_BASE}/shn/{shnid}"
    
    headers = session.headers.copy()
    headers['Referer'] = ETREEDB_URL_BASE + '/'
    headers['Sec-Fetch-Site'] = 'same-origin'

    try:
        resp = session.get(url, headers=headers, timeout=20)
        resp.raise_for_status()
        soup = BeautifulSoup(resp.text, 'html.parser')

        setlist_tag = soup.find('b', string='Setlist')
        if not setlist_tag:
            print("  [ETREEDB-WARN] 'Setlist' header not found. Cannot parse.")
            return None

        content_lines = []
        for sibling in setlist_tag.next_siblings:
            if (sibling.name == 'b' and sibling.get_text(strip=True)) or sibling.name == 'hr':
                break
            if hasattr(sibling, 'get_text'):
                text = sibling.get_text(separator='\n')
                content_lines.extend(text.splitlines())
            elif isinstance(sibling, str):
                content_lines.extend(sibling.strip().splitlines())
        
        relevant_text = "\n".join(content_lines)
        structure = {}
        set_number = 1
        current_set = f"Set {set_number}"

        lines = relevant_text.splitlines()

        re_set_marker = re.compile(
            r'^\s*('
            r'(?:Set(?:\s)?[I1-3]+s*:?)|'
            r'(?:Second\s+Set|Third\s+Set)|'
            r'(?:Acoustic\s+Set)|'
            r'(?:Disc\s+[2-3])|'
            r'(?:CD\s+[2-3])|'
            r'(?:Midnight\s+Countdown)'
            r')', re.IGNORECASE
        )
        re_encore_marker = re.compile(r'^\s*(Encore[s]?:?|E:)', re.IGNORECASE)

        for line in lines:
            line_clean = line.strip()
            if not line_clean:
                continue

            if re_set_marker.match(line_clean):
                set_number += 1
                current_set = f"Set {set_number}"
                continue
            
            encore_match = re_encore_marker.match(line_clean)
            if encore_match:
                current_set = "Encore"
                line_clean = line_clean[encore_match.end():].strip()
                if not line_clean:
                    continue

            song_title = line_clean
            song_title = re.sub(r'^[\d.]+\s*', '', song_title) # remove "1. "
            song_title = re.sub(r'd\dt\d+\s*', '', song_title) # remove "d1t01"
            song_title = re.sub(r'\s*\([\d:]+\)', '', song_title) # remove "(xx:xx)"
            song_title = re.sub(r'\s*[[>#*$]]+.*', '', song_title).strip() # remove trailing metadata
            song_title = song_title.split('->')[0].strip()

            if len(song_title) > 2 and "tuning" not in song_title.lower() and "setlist" not in song_title.lower():
                if song_title and (song_title not in structure):
                    structure[song_title] = current_set
        
        return structure

    except requests.exceptions.HTTPError as e:
        if e.response.status_code == 403:
            print(f"  [ETREEDB-BLOCKED] Access to {shnid} was blocked by the server.")
        else:
            print(f"  [ETREEDB-ERROR] {e}")
        return None
    except Exception as e:
        print(f"  [ETREEDB-ERROR] An unexpected error occurred: {e}")
        return None

def match_and_update(source_tracks, db_hierarchy):
    updates = 0
    for track in source_tracks:
        user_title = track.get('t', '')
        original_set = track.get('s', 'Set 1')
        
        for db in db_hierarchy:
            if not db: continue
            
            # Simple direct matches for special cases
            if "Feedback" in user_title and "Feedback" in db:
                if db["Feedback"] == "Set 2" and original_set != "Set 2":
                    track['s'] = "Set 2"
                    updates += 1
                track['_matched'] = True
                continue
            if "And We Bid You Good Night" in user_title and "And We Bid You Good Night" in db:
                if db["And We Bid You Good Night"] == "Encore" and original_set != "Encore":
                    track['s'] = "Encore"
                    updates += 1
                track['_matched'] = True
                continue

            # Fuzzy matching for general song titles
            matches = difflib.get_close_matches(user_title, db.keys(), n=1, cutoff=0.8)
            if matches:
                match_title = matches[0]
                new_set = db[match_title]
                
                if new_set in VALID_SET_NAMES and original_set != new_set:
                    track['s'] = new_set
                    updates += 1
                track['_matched'] = True
                break 
    return updates

def fill_gaps(source_tracks):
    updates = 0
    for i, track in enumerate(source_tracks):
        current_set = track.get('s', 'Set 1')
        
        is_noise = any(x in track.get('t','').lower() for x in NON_MUSIC_TRACKS)
        is_invalid_set = current_set not in VALID_SET_NAMES

        if is_noise or is_invalid_set or not track.get('_matched', False):
            prev_label = next((st.get('s') for st in reversed(source_tracks[:i]) if st.get('s') in VALID_SET_NAMES), None)
            next_label = next((st.get('s') for st in source_tracks[i+1:] if st.get('s') in VALID_SET_NAMES), None)
            
            new_set = prev_label or next_label

            if new_set and new_set != current_set:
                track['s'] = new_set
                updates += 1

    for t in source_tracks:
        if '_matched' in t: del t['_matched']
    return updates

def process_shows_with_etreedb(shows, test_mode=False, output_filename=None):
    if not HAS_DEPS:
        print("[ERROR] 'requests' and 'bs4' are required for EtreeDB mode.")
        print("Please install them using: pip install requests beautifulsoup4")
        return

    with requests.Session() as session:
        session.headers.update(REQUEST_HEADERS)
        print("  [SESSION] Initializing session...")
        try:
            session.get(ETREEDB_URL_BASE, timeout=20)
            print("  [SESSION] Session initialized.")
        except Exception as e:
            print(f"  [SESSION-ERROR] Could not initialize session: {e}")
            return
            
        print(f"\nSTARTING ETREEDB BATCH PROCESSING ({len(shows)} shows)\n")
        
        processed_shows = []
        final_output_filename = output_filename if output_filename else OUTPUT_FILENAME
        
        for i, show in enumerate(shows):
            if test_mode and i > 0: break

            date = show.get("date", "Unknown")
            venue = show.get("venue", "Unknown Venue")
            print("="*80 + f"\nSHOW {i+1}/{len(shows)}: {date} @ {venue}")

            show_changes = 0
            for idx, source in enumerate(show.get("sources", [])):
                shnid = source.get('id', f"Source #{idx+1}")
                tracks = source.get('tracks', [])
                print(f"\n  ---- PROCESSING SHNID: {shnid} ----")
                
                original_tracks = copy.deepcopy(tracks)
                etreedb_data = get_etreedb_data(session, shnid)
                
                if etreedb_data is None:
                    print(f"    [NO CHANGES] Could not retrieve data for {shnid}.")
                    continue

                db_hierarchy = [etreedb_data]
                matched_count = match_and_update(tracks, db_hierarchy)
                gap_count = fill_gaps(tracks)
                
                total = matched_count + gap_count
                if total > 0:
                    show_changes += total
                    print(f"    [CHANGES DETECTED FOR {shnid}]")
                    print_comparison(original_tracks, tracks)
                else:
                    print(f"    [NO CHANGES] {shnid} is clean.")

            if show_changes > 0:
                print(f"  [SUMMARY] Fixed {show_changes} issues.")
            
            processed_shows.append(show)
            
            if not test_mode and ((i > 0 and (i+1) % 5 == 0) or ((i+1) == len(shows))):
                print("  [PROGRESS] Saving results...")
                with open(final_output_filename, 'w', encoding='utf-8') as f:
                    json.dump(processed_shows, f, indent=4)
            
            time.sleep(5) 

    if not test_mode:
        print(f"\nDONE! Final output saved to {final_output_filename}")

# ==============================================================================
#  MAIN
# ==============================================================================

def main():
    parser = argparse.ArgumentParser(description="Clean and process show setlist data.")
    parser.add_argument('--etreedb', action='store_true', help="Use the etreedb.org lookup instead of filename parsing.")
    parser.add_argument('--test', action='store_true', help="Run in test mode (process only the first show, no file output).")
    parser.add_argument('--input', type=str, default=INPUT_FILENAME, help=f"Input JSON file (default: {INPUT_FILENAME})")
    parser.add_argument('--output', type=str, help="Output JSON file.")
    args = parser.parse_args()

    mode = "EtreeDB" if args.etreedb else "Filename Parsing"
    test_mode_str = " (Test Mode)" if args.test else ""
    print(f"Running in {mode}{test_mode_str}")

    try:
        with open(args.input, 'r', encoding='utf-8') as f:
            shows = json.load(f)
    except Exception as e:
        print(f"Could not read {args.input}: {e}")
        return

    if args.etreedb:
        process_shows_with_etreedb(shows, args.test, args.output)
    else:
        process_shows_by_filename(shows, args.test, args.output)

if __name__ == "__main__":
    main()
