import json
import os
import urllib.request
import urllib.parse
import urllib.error
import time
import argparse

# API Configuration
API_KEY = "0m8rBqaV2IQj4jUOozuCPf2o1RC5K8hB_tzU"
API_CACHE = {}

def normalize_track_name(name):
    return str(name).lower().replace('.', '').replace(' ', '').replace("'", "").replace(',', "")

def get_official_setlist(date_str):
    """
    Fetches the setlist from setlist.fm.
    date_str: YYYY-MM-DD
    """
    if date_str in API_CACHE:
        return API_CACHE[date_str]

    try:
        parts = date_str.split('-')
        if len(parts) != 3:
            return None
        formatted_date = f"{parts[2]}-{parts[1]}-{parts[0]}"
    except:
        return None
    
    base_url = "https://api.setlist.fm/rest/1.0/search/setlists"
    params = {
        "artistName": "Grateful Dead",
        "date": formatted_date
    }
    query_string = urllib.parse.urlencode(params)
    url = f"{base_url}?{query_string}"
    
    req = urllib.request.Request(url)
    req.add_header("Accept", "application/json")
    req.add_header("x-api-key", API_KEY)

    max_retries = 3
    for attempt in range(max_retries):
        try:
            with urllib.request.urlopen(req) as response:
                time.sleep(1.1) # Rate limit compliance
                
                if response.status == 200:
                    data = json.loads(response.read().decode('utf-8'))
                    if "setlist" in data and len(data["setlist"]) > 0:
                        result = data["setlist"][0]
                        API_CACHE[date_str] = result
                        return result
                    else:
                        API_CACHE[date_str] = None # Not found
                        return None
                
        except urllib.error.HTTPError as e:
            if e.code == 429:
                print(f"  [API] Rate limited for {date_str}. Retrying...")
                time.sleep(5)
                continue
            elif e.code == 404:
                API_CACHE[date_str] = None
                return None
            else:
                print(f"  [API] Error {e.code} for {date_str}.")
                return None
        except Exception as e:
            print(f"  [API] Request failed for {date_str}: {e}")
            return None
        
    return None

def get_canonical_set_name(set_obj_or_name, is_official=False):
    """
    Determines a canonical set name (Set 1, Set 2, Set 3, Encore).
    """
    if is_official:
        # set_obj is a dict from setlist.fm
        if set_obj_or_name.get('encore'):
            return "Encore"
        
        # Heuristic for official sets (count them in the main loop preferably, but here we guess)
        # Actually setlist.fm doesn't name them "Set 1", just "sets".
        # We should handle this in processing.
        return "Set" 
    
    else:
        # Local set object
        name = set_obj_or_name.get('n', '').lower()
        if "encore" in name:
            return "Encore"
        if "set 1" in name or "set i" in name or name == "1":
            return "Set 1"
        if "set 2" in name or "set ii" in name or name == "2":
            return "Set 2"
        if "set 3" in name or "set iii" in name or name == "3":
            return "Set 3"
        return "Unknown Set"

def process_official_sets(official_data):
    """
    Flattens official data into a map: { normalized_track: set_name }
    """
    mapping = {}
    sets = official_data.get("sets", {}).get("set", [])
    
    set_counter = 1
    for s in sets:
        is_encore = s.get('encore', False)
        
        if is_encore:
            set_name = "Encore"
        else:
            set_name = f"Set {set_counter}"
            set_counter += 1
            
        for song in s.get("song", []):
            t_name = song.get("name")
            if t_name:
                norm = normalize_track_name(t_name)
                # Store the first occurrence (sometimes songs are played twice, rarely, or teases)
                if norm not in mapping:
                    mapping[norm] = set_name
                    
    return mapping

def check_sets(input_file, report_file, limit=None):
    print(f"Reading from {input_file}...")
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"Error: Input file {input_file} not found.")
        return

    report_lines = []
    
    # Header
    report_lines.append("# Set Placement Discrepancy Report")
    report_lines.append(f"Input: `{input_file}`")
    report_lines.append(f"Verification Source: Setlist.fm API")
    report_lines.append("")
    
    processed_count = 0
    mismatch_shows_count = 0
    
    unique_dates = sorted(list(set([d.get('date') for d in data])))
    if limit:
        unique_dates = unique_dates[:limit]
        
    print(f"Processing {len(unique_dates)} dates...")

    for show_date in unique_dates:
        # Find all shows/sources for this date
        shows_for_date = [s for s in data if s.get('date') == show_date]
        
        official_data = get_official_setlist(show_date)
        
        if not official_data:
            # print(f"  [API] No official data for {show_date}")
            continue
            
        official_map = process_official_sets(official_data)
        if not official_map:
            continue
            
        print(f"  [API] Verifying {show_date}...")
        
        for show in shows_for_date:
            venue = show.get('venue', 'Unknown')
            
            for source in show.get('sources', []):
                source_id = source.get('id', 'Unknown')
                sets = source.get('sets', [])
                
                source_mismatches = []
                
                # Iterate local tracks
                for s in sets:
                    local_set_name = get_canonical_set_name(s, is_official=False)
                    
                    for track in s.get('t', []):
                        t_name = track.get('t', '')
                        norm = normalize_track_name(t_name)
                        
                        if norm in official_map:
                            official_set_name = official_map[norm]
                            
                            # Comparison Logic
                            # Be tolerant of "Unknown Set" vs "Set 1" if we aren't sure, but usually we are.
                            # Strict check:
                            if local_set_name != "Unknown Set" and local_set_name != official_set_name:
                                # Found a mismatch
                                # Filter out some noise? E.g. Set 2 vs Set 3 logic might be fuzzy if there are 3 sets?
                                # For now, report all.
                                
                                fix_instruction = f"Move '{t_name}' from **{local_set_name}** to **{official_set_name}**"
                                source_mismatches.append(fix_instruction)
                
                if source_mismatches:
                    mismatch_shows_count += 1
                    report_lines.append(f"### {show_date} - {venue} (Source: {source_id})")
                    for m in source_mismatches:
                        report_lines.append(f"- {m}")
                    report_lines.append("")
        
        processed_count += 1
        if limit and processed_count >= limit:
            break

    print(f"Found discrepancies in {mismatch_shows_count} sources.")
    print(f"Writing report to {report_file}...")
    
    with open(report_file, 'w', encoding='utf-8') as f:
        for line in report_lines:
            f.write(line + "\n")
            
    print("Done.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Check set placement against API.')
    parser.add_argument('--input', default='assets/data/output.optimized_src.json', help='Input JSON file')
    parser.add_argument('--report', default='check_sets_report.md', help='Report Markdown file')
    parser.add_argument('--limit', type=int, default=None, help='Limit number of dates to process')
    
    args = parser.parse_args()
    
    check_sets(args.input, args.report, args.limit)
