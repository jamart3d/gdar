import json
import os
import urllib.request
import urllib.parse
import urllib.error
import time
import argparse
import re

# --- Configuration & Constants ---
API_KEY = "WkG1hvmMIUZzzbChGzdMMPH0ahQincyOeCV3"
CACHE_DIR = "../../setlist_cache"
API_CACHE = {}  # In-memory cache for the current run
BANNED_SHNIDS = ["4850", "11660", "137088", "137021", "7233", "97489", "78"]

# Songs that typically ended the final set (Set 2 or Set 3)
typical_closers = [
    "Sugar Magnolia", "Sunshine Daydream", "One More Saturday Night", 
    "Not Fade Away", "Goin' Down the Road Feeling Bad", "Good Lovin'", 
    "Around and Around", "Johnny B. Goode", "U.S. Blues", "Casey Jones", 
    "Turn On Your Love Light", "Estimated Prophet", "Morning Dew", 
    "The Music Never Stopped", "Throwing Stones", "Deal"
]

# Songs that typically appeared in the Encore slot
typical_encores = [
    "U.S. Blues", "One More Saturday Night", "Johnny B. Goode", 
    "Brokedown Palace", "And We Bid You Goodnight", "Baby Blue", 
    "It's All Over Now, Baby Blue", "Touch of Grey", "Quinn the Eskimo", 
    "Mighty Quinn", "Liberty", "Box of Rain", "Black Muddy River", 
    "I Fought the Law", "Werewolves of London"
]

set2_openers_comprehensive = [
    "China Cat Sunflower", "Scarlet Begonias",
    "Help on the Way", "Shakedown Street", "Iko Iko",
    "Feel Like a Stranger", "Samson and Delilah", "Playing in the Band", "Playin' in the Band", "Truckin'",
    "Eyes of the World", "Estimated Prophet", "Terrapin Station",
    "Mississippi Half-Step Uptown Toodeloo", "Man Smart, Woman Smarter", "Hey Pocky Way",
    "Bertha", "Dancing in the Street", "Foolish Heart",
    "Victim or the Crime", "Box of Rain", "Picasso Moon", "Touch of Grey",
    "Hell in a Bucket", "Jack Straw", "Cold Rain and Snow", "Rain",
    "Let the Good Times Roll", "In the Midnight Hour", "Gimme Some Lovin'",
    "Cosmic Charlie", "Loose Lucy", "Alabama Getaway", "Greatest Story Ever Told",
    "The Promised Land", "New Minglewood Blues",
    "Big Railroad Blues", "Hard to Handle", "Dark Star", "The Other One",
    "Cryptical Envelopment", "Wang Dang Doodle", "Maggie's Farm", "Quinn the Eskimo",
    "Keep On Growing", "Cumberland Blues"
]


TRACK_NAME_CORRECTIONS = {
    "Johnny B Goode": "Johnny B. Goode",
    "Turn On Your Lovelight": "Turn On Your Love Light",
    "Knockin' On Heaven's Door": "Knockin' on Heaven's Door",

    "Goin' Down The Road Feelin' Bad": "Going Down The Road Feeling Bad",
    "Uncle Johns Band": "Uncle John's Band",
    "Throwin' Stones": "Throwing Stones"
}


STATE_PROVINCE_MAP = {
    'alabama': 'AL', 'alaska': 'AK', 'arizona': 'AZ', 'arkansas': 'AR', 'california': 'CA',
    'colorado': 'CO', 'connecticut': 'CT', 'delaware': 'DE', 'florida': 'FL', 'georgia': 'GA',
    'hawaii': 'HI', 'idaho': 'ID', 'illinois': 'IL', 'indiana': 'IN', 'iowa': 'IA', 'kansas': 'KS',
    'kentucky': 'KY', 'louisiana': 'LA', 'maine': 'ME', 'maryland': 'MD', 'massachusetts': 'MA',
    'michigan': 'MI', 'minnesota': 'MN', 'mississippi': 'MS', 'missouri': 'MO', 'montana': 'MT',
    'nebraska': 'NE', 'nevada': 'NV', 'new hampshire': 'NH', 'new jersey': 'NJ', 'new mexico': 'NM',
    'new york': 'NY', 'north carolina': 'NC', 'north dakota': 'ND', 'ohio': 'OH', 'oklahoma': 'OK',
    'oregon': 'OR', 'pennsylvania': 'PA', 'rhode island': 'RI', 'south carolina': 'SC',
    'south dakota': 'SD', 'tennessee': 'TN', 'texas': 'TX', 'utah': 'UT', 'vermont': 'VT',
    'virginia': 'VA', 'washington': 'WA', 'west virginia': 'WV', 'wisconsin': 'WI', 'wyoming': 'WY',
    'alberta': 'AB', 'british columbia': 'BC', 'manitoba': 'MB', 'new brunswick': 'NB',
    'newfoundland and labrador': 'NL', 'nova scotia': 'NS', 'ontario': 'ON',
    'prince edward island': 'PE', 'quebec': 'QC', 'saskatchewan': 'SK'
}

# --- Normalization Functions ---
def normalize_track_name(name):
    return str(name).lower().replace('.', '').replace(' ', '').replace("'", "").replace(',', '')

def normalize_location_string(location_str):
    if not location_str or ',' not in location_str:
        return location_str

    parts = [part.strip().lower() for part in location_str.split(',')]
    if len(parts) == 2:
        city, state_or_province = parts
        state_or_province_code = STATE_PROVINCE_MAP.get(state_or_province, state_or_province.upper())
        return f"{city.title()}, {state_or_province_code}"
    return location_str

# --- API & Cache Functions ---
def get_official_setlist(date_str, enable_api=False):
    if date_str in API_CACHE:
        return json.loads(json.dumps(API_CACHE[date_str]))

    cache_path = os.path.join(CACHE_DIR, f"{date_str}_setlist.json")
    if os.path.exists(cache_path):
        with open(cache_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            result = data if not data.get("not_found") else None
            API_CACHE[date_str] = result
            return json.loads(json.dumps(result)) if result else None

    try:
        parts = date_str.split('-')
        if len(parts) != 3: return None
        formatted_date = f"{parts[2]}-{parts[1]}-{parts[0]}"
    except:
        return None

    if not enable_api:
        if date_str not in API_CACHE: # Only warn once per date if not in cache (though this logic is per-call)
             # print(f"      [Offline] Skipping API call for {date_str}")
             pass
        return None

    base_url = "https://api.setlist.fm/rest/1.0/search/setlists"
    params = {"artistName": "Grateful Dead", "date": formatted_date}
    req = urllib.request.Request(f"{base_url}?{urllib.parse.urlencode(params)}")
    req.add_header("Accept", "application/json")
    req.add_header("x-api-key", API_KEY)

    print(f"    [API] Calling Setlist.fm for official setlist on {date_str}...")
    time.sleep(5)

    try:
        with urllib.request.urlopen(req) as response:
            if response.status == 200:
                data = json.loads(response.read().decode('utf-8'))
                if "setlist" in data and len(data["setlist"]) > 0:
                    result = data["setlist"][0]
                    API_CACHE[date_str] = result
                    with open(cache_path, 'w', encoding='utf-8') as f: json.dump(result, f)
                    return result
    except urllib.error.HTTPError as e:
        if e.code != 429:
            print(f"      [API] Error {e.code}. Caching as 'not found'.")
            with open(cache_path, 'w', encoding='utf-8') as f: json.dump({"not_found": True}, f)
        else:
            print(f"      [API] Rate limited.")
        API_CACHE[date_str] = None
        return None
    except Exception as e:
        print(f"      [API] Request failed: {e}")
        API_CACHE[date_str] = None
        return None

    with open(cache_path, 'w', encoding='utf-8') as f: json.dump({"not_found": True}, f)
    API_CACHE[date_str] = None
    return None

def get_venue_location(venue_name, enable_api=False):
    if not venue_name or venue_name.lower() in ["various", "unknown"]:
        return None

    cache_key = f"venue_{venue_name}"
    if cache_key in API_CACHE:
        return API_CACHE[cache_key]

    safe_filename = re.sub(r'[^a-zA-Z0-9_.-]', '_', venue_name) + "_venue.json"
    cache_path = os.path.join(CACHE_DIR, safe_filename)

    if os.path.exists(cache_path):
        with open(cache_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            result = data if not data.get("not_found") else None
            API_CACHE[cache_key] = result
            return result

    if not enable_api:
        # print(f"      [Offline] Skipping API call for {venue_name}")
        return None

    url_base = "https://api.setlist.fm/rest/1.0/search/venues"
    headers = {"Accept": "application/json", "x-api-key": API_KEY}
    params = {"name": venue_name}
    req = urllib.request.Request(f"{url_base}?{urllib.parse.urlencode(params)}", headers=headers)

    print(f'    [API] Calling Setlist.fm for venue location of "{venue_name}"...')
    time.sleep(5)

    try:
        with urllib.request.urlopen(req) as response:
            if response.status == 200:
                data = json.loads(response.read().decode('utf-8'))
                if "venue" in data and data["venue"]:
                    top_match = data["venue"][0]
                    city_info = top_match.get("city", {})
                    location_data = {"city": city_info.get("name"), "state": city_info.get("stateCode")}
                    API_CACHE[cache_key] = location_data
                    with open(cache_path, 'w', encoding='utf-8') as f: json.dump(location_data, f)
                    return location_data
    except Exception as e:
        print(f"      [API] Venue request failed: {e}")

    with open(cache_path, 'w', encoding='utf-8') as f: json.dump({"not_found": True}, f)
    API_CACHE[cache_key] = None
    return None

# --- Data Processing Functions ---
def process_official_sets(official_data):
    mapping = {}
    sets = official_data.get("sets", {}).get("set", [])
    set_counter = 1
    for s in sets:
        set_name = "Encore" if s.get('encore', False) else f"Set {set_counter}"
        if not s.get('encore', False): set_counter += 1
        for song in s.get("song", []):
            if t_name := song.get("name"):
                if (norm := normalize_track_name(t_name)) not in mapping:
                    mapping[norm] = set_name
    return mapping

def source_has_encore_variation_in_track_names(source_sets):
    for s in source_sets:
        for t in s.get('t', []):
            t_name = str(t.get('t', ''))
            if "E:" in t_name or "E2:" in t_name or "encore" in t_name.lower():
                return True
    return False

def classify_dead_tracks(date, track_list):
    """
    date: 'YYYY-MM-DD'
    track_list: List of the final 4-5 songs of the show in order.
    """
    year = int(date.split('-')[0])
    last_song = track_list[-1]
    penultimate = track_list[-2] if len(track_list) > 1 else None

    # Result structure
    show_structure = {"Set_Closer": [], "Encore": []}

    # 1. PURE ENCORE LIST (Assume these are always encores if at the end)
    pure_encores = ["The Mighty Quinn", "Quinn the Eskimo", "Satisfaction", "Brokedown Palace", "Liberty"]
    
    # 2. PURE CLOSER LIST (Assume these trigger the encore break)
    pure_closers = ["Around and Around", "Sugar Magnolia", "Sunshine Daydream", "Good Lovin'"]

    # 3. Handle Satisfaction Exceptions (1981-03-24, 1981-05-12, 1981-12-05)
    sat_exceptions = ["1981-03-24", "1981-05-12", "1981-12-05"]
    if date in sat_exceptions and last_song != "Satisfaction":
        show_structure["Set_Closer"] = ["Satisfaction"]
        show_structure["Encore"] = [last_song]
        return show_structure

    # 4. Handle 1974 "Triple Set" Era Logic
    if year == 1974:
        # If OMSN is present, it is almost always the Set 3 Closer.
        if "One More Saturday Night" in track_list:
            idx = track_list.index("One More Saturday Night")
            show_structure["Set_Closer"] = track_list[:idx+1]
            show_structure["Encore"] = track_list[idx+1:]
        else:
            show_structure["Encore"] = [last_song]
            show_structure["Set_Closer"] = track_list[:-1]

    # 5. Standard Era Logic (Post-1977)
    else:
        # Check if the last song is a known Encore
        if last_song in pure_encores or last_song == "Uncle John's Band":
            show_structure["Encore"] = [last_song]
            show_structure["Set_Closer"] = [penultimate]
            
            # Check for "Double Encore" (e.g. U.S. Blues > OMSN)
            if penultimate in ["U.S. Blues", "Johnny B. Goode"]:
                show_structure["Encore"] = [penultimate, last_song]
                show_structure["Set_Closer"] = [track_list[-3]]
        
        elif last_song in pure_closers:
            # If the show ends with a closer, there was technically 'No Encore'
            show_structure["Set_Closer"] = [last_song]
            show_structure["Encore"] = ["(No Encore Played)"]

    return show_structure

def format_setlist_for_report(sets, archive_desc=None):
    lines = []
    def sort_key(s):
        name = s.get('n', 'Z')
        if name.lower().startswith('set'): return (1, name)
        if name.lower().startswith('encore'): return (2, name)
        return (0, name)

    # User requested just n, u, and track name. No full path.
    
    for s in sorted(sets, key=sort_key):
        set_name = s.get('n', 'Unknown Set')
        lines.append(f"**{set_name}**")
        tracks = s.get('t', [])
        if tracks:
            for i, t in enumerate(tracks, 1):
                track_name = t.get('t', 'Unknown Track')
                track_num = t.get('n', i)
                filename = t.get('u', '')
                
                # Format: n:{n} u:{u} {t}
                lines.append(f"  n:{track_num} u:{filename} {track_name}")
        else:
            lines.append("  *(This set is empty)*")
        lines.append("")
    return "\n".join(lines)

# --- Main Script Logic ---
def fix_sets(input_file, output_file, report_file, long_encore_report_file, very_long_encore_report_file, detailed_report_file, unlabeled_encores_report_file, multiple_set1_report_file, track_number_issues_report_file, track_numbers_fixed_report_file, single_track_set2_report_file, only_set1_report_file, set_reconstruction_report_file, limit=None, apply_changes=False, enable_api=False):
    os.makedirs(CACHE_DIR, exist_ok=True)
    run_mode = "LIVE RUN" if apply_changes else "MOCK RUN"
    print(f"Starting script in {run_mode} mode...")

    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"Error: Input file {input_file} not found.")
        return

    stats = {
        "shows": 0, "sources": 0, "setlists_found": 0, "setlists_not_found": 0,
        "loc_updates": 0, "location_updates": 0, "sets_updated": 0, "set_corrections": 0, "api_encores_identified": 0,
        "sources_1_set": 0, "sources_2_sets_no_encore": 0,
        "encore_sources": [], "encore_track_counts": {}, 
        "rule_based_encore_fixes": [], "remaining_unlabeled_encores": [],
        "multiple_set1_sources": [], "track_number_issues": [], "track_fixable_by_filename": [],
        "multiple_set1_sources": [], "track_number_issues": [], "track_fixable_by_filename": [],
        "single_track_set2_sources": [], "only_set1_sources": [], "set_reconstructions": [],
        "encore_variations": {"E:": 0, "E2:": 0, "Encore": 0, "Total": 0},
        "flutter_sample_removed": 0, "banned_sources_removed": 0, "dot_tracks_fixed": 0,
        "case_issues_tally": {}, "unlabeled_encores_fixed": 0, 
        "track_name_corrections": [], "case_corrected_track_names": [], 
        "duration_in_track_name_removed": 0, "special_track_corrections_made": [], 
        "encore_variation_fixes": [], "double_slash_removed_fixes": [], "trailing_empty_paren_removed": 0,
        "non_mp3_tracks": [],
        "missing_encore_analysis": {} # {track_name: {count: int, type: str}}
    }
    report_logs = {}

    # --- Pre-scan for Encore Variations ---
    print("    [Pre-scan] Tallying encore variations in track names...")
    for show in data:
        for source in show.get('sources', []):
            for s in source.get('sets', []):
                for t in s.get('t', []):
                    t_name = str(t.get('t', ''))
                    found = False
                    if "E:" in t_name:
                        stats["encore_variations"]["E:"] += 1
                        found = True
                    if "E2:" in t_name:
                        stats["encore_variations"]["E2:"] += 1
                        found = True
                    if "encore" in t_name.lower(): # Case-insensitive substring check
                        stats["encore_variations"]["Encore"] += 1
                        found = True

                    if found:
                        stats["encore_variations"]["Total"] += 1

                    # Check for Case Issues (e.g., "JOrdan")
                    # Regex: Word boundary, 2+ Uppercase, 1+ Lowercase
                    case_matches = re.findall(r'\b[A-Z]{2,}[a-z]+', t_name)
                    for match in case_matches:
                        if match not in stats["case_issues_tally"]:
                            stats["case_issues_tally"][match] = []
                        stats["case_issues_tally"][match].append(t_name)
                    
                    # Check for Non-MP3 tracks (basic filename check if extensions exist)
                    if re.search(r'\.(flac|shn|wav|m4a|ogg)$', t_name, re.IGNORECASE):
                        # Double check it's not .mp3 (already excluded by regex but being explicit)
                        if not t_name.lower().endswith('.mp3'):
                            stats["non_mp3_tracks"].append({
                                'date': show.get('date', 'Unknown Date'),
                                'id': source.get('id', 'N/A'),
                                'track': t_name
                            })

    unique_dates = sorted(list(set(d.get('date') for d in data if d.get('date'))))
    if limit:
        unique_dates = unique_dates[:limit]

    for show_date in unique_dates:
        date_log = {"location_updates": [], "venue_notes": [], "location_notes": [],
                    "official_venue": None, "official_location": None, "official_setlist": None,
                    "shows": []}

        shows_for_date = [s for s in data if s.get('date') == show_date]
        stats["shows"] += len(shows_for_date)

        # --- Get Official Data ---
        official_data = get_official_setlist(show_date, enable_api)
        if official_data:
            stats["setlists_found"] += 1
            date_log["official_setlist"] = official_data
            official_map = process_official_sets(official_data)

            venue_info = official_data.get("venue", {})
            date_log["official_venue"] = venue_info.get("name")
            city_info = venue_info.get("city", {})
            city = city_info.get("name")
            state = city_info.get("stateCode") or city_info.get("state")
            if city and state:
                date_log["official_location"] = f"{city}, {state}"
        else:
            stats["setlists_not_found"] += 1
            official_map = {}

        # --- Process Each Show on this Date ---
        for show in shows_for_date:
            show_log = {"json_name": show.get("name"), "json_location": show.get("l"), "sources": [], "location_updated": False}

            if date_log["official_venue"] and show_log["json_name"] and \
               date_log["official_venue"].lower() != show_log["json_name"].lower():
                note = f"JSON name is `{show_log['json_name']}`"
                if note not in date_log["venue_notes"]:
                    date_log["venue_notes"].append(note)

            norm_json_loc = normalize_location_string(show_log["json_location"])
            norm_official_loc = normalize_location_string(date_log["official_location"])
            if norm_json_loc and norm_official_loc and norm_json_loc != norm_official_loc:
                note = f"JSON location is `{show_log['json_location']}`"
                if note not in date_log["location_notes"]:
                    date_log["location_notes"].append(note)

            if not show.get("l"): # Only update if location is missing
                new_loc = None
                if date_log.get("official_location"):
                     new_loc = date_log["official_location"]
                elif show.get("name"):
                    location_info = get_venue_location(show.get("name"), enable_api)
                    if location_info and location_info.get("city") and location_info.get("state"):
                        new_loc = f"{location_info['city']}, {location_info['state']}"

                if new_loc:
                    show["l"] = new_loc
                    stats["loc_updates"] += 1
                    date_log['location_updates'].append(f"For `{show.get('name')}`, added location `{new_loc}`.")
                    show_log["json_location"] = new_loc
                    show_log["location_updated"] = True

            # Filter banned sources first
            valid_sources = []
            for source in show.get('sources', []):
                if str(source.get('id', '')) in BANNED_SHNIDS:
                    stats['banned_sources_removed'] += 1
                    continue
                valid_sources.append(source)
            show['sources'] = valid_sources

            for source in show.get('sources', []):
                stats["sources"] += 1

                # --- Fix Encore Variations ---
                # First pass: clean track names and flag for moving
                for s in source.get('sets', []):
                    for t in s.get('t', []):
                        t_name = str(t.get('t', ''))
                        original_t_name = t_name

                        # Check for exclusion keywords
                        exclusion_keywords = ["break", "rap", "call", "applause"]
                        if any(keyword in t_name.lower() for keyword in exclusion_keywords):
                            continue # Skip this track

                        cleaned_t_name = re.sub(r'(\bE:|\bE2:|\bEncore\b)\s*:?\s*', '', t_name, flags=re.IGNORECASE).strip()

                        if cleaned_t_name != original_t_name:
                            t['t'] = cleaned_t_name
                            t['_move_to_encore'] = True
                            stats['encore_variation_fixes'].append({
                                'date': show_date,
                                'id': source.get('id', 'N/A'),
                                'original_name': original_t_name,
                                'cleaned_name': cleaned_t_name
                            })
                
                # Second pass: move flagged tracks to Encore set
                tracks_to_move = []
                for s in source.get('sets', []):
                    tracks_to_keep = []
                    for t in s.get('t', []):
                        if t.get('_move_to_encore'):
                            del t['_move_to_encore'] # Clean up the flag
                            tracks_to_move.append(t)
                        else:
                            tracks_to_keep.append(t)
                    s['t'] = tracks_to_keep
                
                if tracks_to_move:
                    encore_set = next((s for s in source.get('sets', []) if s.get('n', '').lower() == 'encore'), None)
                    if not encore_set:
                        encore_set = {'n': 'Encore', 't': []}
                        source.get('sets', []).append(encore_set)
                    encore_set['t'].extend(tracks_to_move)

                # Filter out "Flutter Sample" and fix dot tracks
                for s in source.get('sets', []):
                    new_tracks = []
                    for t in s.get('t', []):
                        t_name = str(t.get('t', ''))

                        # Remove duration from track name
                        original_t_name_for_duration_check = t_name
                        cleaned_t_name = re.sub(r'\s*\{[\d:.]+\}$', '', t_name).strip()
                        if cleaned_t_name != original_t_name_for_duration_check:
                            stats['duration_in_track_name_removed'] += 1
                            t_name = cleaned_t_name
                            t['t'] = t_name
                        
                        # Remove double slashes and fix spacing
                        original_t_name_for_slash_check = t_name
                        
                        # Step 1: Remove artifacts
                        temp_t_name = t_name.replace('.//', '').replace('//', '').replace('%', '')
                        
                        # Step 2: Normalize all whitespace (replace multiple spaces with one, strip)
                        cleaned_t_name_from_slash = re.sub(r'\s+', ' ', temp_t_name).strip()

                        if cleaned_t_name_from_slash != original_t_name_for_slash_check:
                            stats['double_slash_removed_fixes'].append((original_t_name_for_slash_check, cleaned_t_name_from_slash))
                            t_name = cleaned_t_name_from_slash
                            t['t'] = t_name
                        
                        # Remove trailing empty parentheses
                        if t_name.endswith(" ()"):
                            t_name = t_name[:-3].strip()
                            t['t'] = t_name
                            stats['trailing_empty_paren_removed'] += 1

                        # Apply case corrections
                        original_t_name_for_case_check = t_name # Store original for comparison
                        def replace_case_match(match):
                            return match.group(0).capitalize()

                        corrected_t_name_from_case = re.sub(r'\b[A-Z]{2,}[a-z]+', replace_case_match, t_name)

                        if corrected_t_name_from_case != original_t_name_for_case_check:
                            stats['case_corrected_track_names'].append((original_t_name_for_case_check, corrected_t_name_from_case))
                            t_name = corrected_t_name_from_case
                            t['t'] = t_name # Update the track object

                        # Special Correction: "Quinn" variations to "The Mighty Quinn"

                        # Special Correction: "Quinn" variations to "The Mighty Quinn"
                        original_t_name_for_special_check = t_name
                        if "quinn" in t_name.lower() and t_name != "The Mighty Quinn":
                            t_name = "The Mighty Quinn"
                            t['t'] = t_name
                            stats['special_track_corrections_made'].append((original_t_name_for_special_check, t_name))


                        # Filter out "Flutter Sample" and fix dot tracks
                        if t_name.startswith('.'):
                            t_name = t_name.lstrip('.').strip()
                            t['t'] = t_name
                            stats['dot_tracks_fixed'] += 1

                        if t_name == "Flutter Sample":
                            stats['flutter_sample_removed'] += 1
                        else:
                            # Check for and apply track name corrections
                            if t_name in TRACK_NAME_CORRECTIONS:
                                corrected_name = TRACK_NAME_CORRECTIONS[t_name]
                                t['t'] = corrected_name
                                stats['track_name_corrections'].append(t_name) # Append original track name
                                t_name = corrected_name  # Update t_name for subsequent logic in this loop

                            new_tracks.append(t)
                    s['t'] = new_tracks

                original_sets = json.loads(json.dumps(source.get('sets', [])))
                is_correction_needed = False

                if official_map and original_sets:
                    all_tracks = [t for s in original_sets for t in s.get('t', [])]

                    if any(official_map.get(normalize_track_name(t.get('t', ''))) == 'Encore' for t in all_tracks):
                        stats["api_encores_identified"] += 1

                    for track in all_tracks:
                        norm_name = normalize_track_name(track.get('t', ''))
                        official_set = official_map.get(norm_name)
                        if official_set:
                            original_set_name = next((s.get('n') for s in original_sets if track in s.get('t', [])), None)
                            if official_set != original_set_name:
                                is_correction_needed = True
                                break

                if is_correction_needed:
                    track_to_set = {tuple(t.items()): s.get('n') for s in original_sets for t in s.get('t', [])}
                    new_sets_map = {}
                    new_sets_list = []

                    for track in all_tracks:
                        norm_name = normalize_track_name(track.get('t', ''))
                        final_set = official_map.get(norm_name, track_to_set.get(tuple(track.items()), "Unknown Set"))

                        if final_set not in new_sets_map:
                            new_set = {'n': final_set, 't': []}
                            new_sets_map[final_set] = new_set
                            new_sets_list.append(new_set)
                        new_sets_map[final_set]['t'].append(track)

                    final_tracks = [t for s in new_sets_list for t in s.get('t', [])]
                    if all_tracks == final_tracks:
                        stats["set_corrections"] += 1
                        updated_sets_flag = True
                        if apply_changes:
                            source['sets'] = new_sets_list
                    else:
                        updated_sets_flag = False
                else:
                    updated_sets_flag = False

                show_log["sources"].append({'data': source, 'set_updated': updated_sets_flag})

                # --- Stats Collection ---
                # Check for potential unlabeled encore before correction
                original_set_names = [s.get('n') for s in original_sets if s.get('n')]
                has_encore_variation = source_has_encore_variation_in_track_names(original_sets)
                had_potential_unlabeled_encore = len(original_set_names) >= 2 and not any(name == 'Encore' for name in original_set_names) and not has_encore_variation

                # Use the corrected sets for stats calculation if available, even if not applied to source object
                current_sets = new_sets_list if updated_sets_flag else source.get('sets', [])
                set_names = [s.get('n') for s in current_sets if s.get('n')]
                has_encore = any(name == 'Encore' for name in set_names)

                if had_potential_unlabeled_encore and has_encore:
                    stats['unlabeled_encores_fixed'] += 1

                num_sets = len(current_sets)

                if num_sets == 1:
                    stats["sources_1_set"] += 1
                elif num_sets >= 2 and not has_encore:
                    if not source_has_encore_variation_in_track_names(current_sets):
                        # Rule-based encore fixing using classify_dead_tracks
                        last_set = current_sets[-1]
                        last_set_tracks = last_set.get('t', [])
                        
                        # Extract the last few tracks for classification
                        # Assuming classify_dead_tracks expects track names as strings
                        track_names_for_classification = [t.get('t') for t in last_set_tracks][-5:] # Last 5 tracks

                        if track_names_for_classification:
                            classified_structure = classify_dead_tracks(show_date, track_names_for_classification)
                            
                            # --- Tally Logic ---
                            last_track_name_lower = track_names_for_classification[-1].lower().strip()
                            if last_track_name_lower not in stats["missing_encore_analysis"]:
                                stats["missing_encore_analysis"][last_track_name_lower] = {"count": 0, "type": "Unknown"}
                            
                            stats["missing_encore_analysis"][last_track_name_lower]["count"] += 1
                            
                            if classified_structure.get("Encore") and classified_structure["Encore"] != ["(No Encore Played)"]:
                                stats["missing_encore_analysis"][last_track_name_lower]["type"] = "Encore"
                            elif classified_structure.get("Encore") == ["(No Encore Played)"]:
                                stats["missing_encore_analysis"][last_track_name_lower]["type"] = "Set_Closer"
                            # -------------------
                            
                            classified_encore_names = classified_structure.get("Encore", [])
                            classified_closer_names = classified_structure.get("Set_Closer", [])

                            if classified_encore_names and classified_encore_names != ["(No Encore Played)"]:
                                # We found an encore via classification, so move tracks
                                tracks_to_move_to_encore = []
                                tracks_to_keep_in_last_set = []

                                # Iterate through the last set's tracks to move classified encores
                                # And retain classified closers in the last set
                                for track in last_set_tracks:
                                    if track.get('t') in classified_encore_names:
                                        tracks_to_move_to_encore.append(track)
                                    else:
                                        tracks_to_keep_in_last_set.append(track)
                                
                                if tracks_to_move_to_encore:
                                    # Create or find the Encore set
                                    encore_set_obj = next((s for s in current_sets if s.get('n') == 'Encore'), None)
                                    if not encore_set_obj:
                                        encore_set_obj = {'n': 'Encore', 't': []}
                                        current_sets.append(encore_set_obj)
                                    
                                    encore_set_obj['t'].extend(tracks_to_move_to_encore)
                                    last_set['t'] = tracks_to_keep_in_last_set # Update the last set
                                    
                                    # Log the fix
                                    stats['rule_based_encore_fixes'].append({
                                        'date': show_date,
                                        'id': source.get('id', 'N/A'),
                                        'moved_tracks': [t.get('t') for t in tracks_to_move_to_encore]
                                    })
                                else:
                                    # If classify_dead_tracks said there's an encore but we didn't move anything
                                    # (e.g. track_names_for_classification was smaller than the classified_encore_names implies)
                                    # then it's still a potential unlabeled encore
                                    stats['remaining_unlabeled_encores'].append({
                                        'date': show_date,
                                        'id': source.get('id'),
                                        'desc': source.get('_d', 'N/A'),
                                        'source_sets': json.loads(json.dumps(current_sets)) # deepcopy
                                    })
                            else:
                                # classify_dead_tracks either found "(No Encore Played)" or nothing for encore
                                stats['remaining_unlabeled_encores'].append({
                                    'date': show_date,
                                    'id': source.get('id'),
                                    'desc': source.get('_d', 'N/A'),
                                    'source_sets': json.loads(json.dumps(current_sets)) # deepcopy
                                })

                        else:
                            # If no tracks were passed for classification (empty last_set_tracks)
                            stats['remaining_unlabeled_encores'].append({
                                'date': show_date,
                                'id': source.get('id'),
                                'desc': source.get('_d', 'N/A'),
                                'source_sets': json.loads(json.dumps(current_sets)) # deepcopy
                            })

                has_long_encore = False
                if has_encore:
                    encore_set = next((s for s in current_sets if s.get('n') == 'Encore'), None)
                    if encore_set:
                        t_count = len(encore_set.get('t', []))
                        if t_count >= 4:
                            has_long_encore = True
                        stats["encore_track_counts"][t_count] = stats["encore_track_counts"].get(t_count, 0) + 1
                        stats["encore_sources"].append({
                            "date": show_date,
                            "id": source.get('id', 'N/A'),
                            "count": t_count,
                            "desc": source.get('_d', 'N/A'),
                            "tracks": [t.get('t', 'Unknown') for t in encore_set.get('t', [])],
                            "original_sets": original_sets,
                            "corrected_sets": current_sets
                        })


                
                # --- Single Track Set 2 Detection ---
                has_single_track_set2 = False
                set2 = next((s for s in current_sets if s.get('n', '').lower() == 'set 2'), None)
                if set2 and len(set2.get('t', [])) == 1:
                    has_single_track_set2 = True
                    stats["single_track_set2_sources"].append({
                        "date": show_date,
                        "id": source.get('id', 'N/A'),
                        "desc": source.get('_d', 'N/A'),
                        "sets": current_sets
                    })

                # --- Empty Set Detection ---
                # Check for sets with zero tracks (e.g. "Set 2" is empty but "Set 3" exists)
                has_empty_set = False
                for s in current_sets:
                    if not s.get('t', []):
                         has_empty_set = True
                         break
                
                if has_empty_set:
                     if "empty_set_sources" not in stats: stats["empty_set_sources"] = []
                     stats["empty_set_sources"].append({
                        "date": show_date,
                        "id": source.get('id', 'N/A'),
                        "desc": source.get('_d', 'N/A'),
                        "sets": current_sets
                     })

                # --- Only Set 1 Detection ---
                if len(current_sets) == 1 and current_sets[0].get('n', '').lower() == 'set 1':
                    stats["only_set1_sources"].append({
                        "date": show_date,
                        "id": source.get('id', 'N/A'),
                        "desc": source.get('_d', 'N/A'),
                        "sets": current_sets
                    })

                # --- Track Number Issues Check ---
                all_source_tracks = []
                for s in current_sets:
                    for t in s.get('t', []):
                         all_source_tracks.append(t)
                
                if all_source_tracks:
                    issues = []
                    # Check for sequential integers 1..N
                    expected_n = 1
                    
                    # Also check for strictly sequential relative to previous? 
                    # Let's just check if it matches the expected sequence 1, 2, 3...
                    # Or should we just check if they are integers and ascending? 
                    # User said "out of order or missing". 
                    # A strict 1-based index check covers both (missing 2 means 3 comes after 1 -> out of order/gap).
                    
                    for i, t in enumerate(all_source_tracks):
                        n_val = t.get('n')
                        try:
                            n_int = int(n_val)
                            if n_int != expected_n:
                                issues.append(f"Track index {i+1} has n:{n_val} (expected {expected_n})")
                        except (ValueError, TypeError):
                             issues.append(f"Track index {i+1} has invalid or missing n: {n_val}")
                        expected_n += 1
                    



                    # Check for Multiple Set 1s early to see if we can force a filename fix
                    set1_count_early = sum(1 for s in current_sets if s.get('n', '').lower() == 'set 1')

                    if issues or set1_count_early > 1 or has_long_encore or has_single_track_set2:
                        # --- Check if fixable by filename sort ---
                        can_sort_by_filename = True
                        sortable_tracks = []
                        
                        for t in all_source_tracks:
                            u_val = t.get('u', '')
                            # Regex for d1t01 or t01 patterns
                            
                            match_dt = re.search(r'd(\d+)t(\d+)', u_val, re.IGNORECASE)
                            match_t = re.search(r't(\d+)', u_val, re.IGNORECASE)
                            # Fallback: starts with number followed by space or dot
                            match_n = re.search(r'^(\d+)', u_val)

                            sort_key = None
                            if match_dt:
                                sort_key = (int(match_dt.group(1)), int(match_dt.group(2)))
                            elif match_t:
                                sort_key = (0, int(match_t.group(1))) # Disc 0
                            elif match_n:
                                sort_key = (0, int(match_n.group(1)))
                            
                            if sort_key:
                                sortable_tracks.append({'track': t, 'key': sort_key})
                            else:
                                can_sort_by_filename = False
                                break
                        
                        if can_sort_by_filename:
                            # Fixable -> track_fixable_by_filename
                            sortable_tracks.sort(key=lambda x: x['key'])
                            sorted_track_list = [item['track'] for item in sortable_tracks]
                            
                            stats["track_fixable_by_filename"].append({
                                "date": show_date,
                                "id": source.get('id', 'N/A'),
                                "desc": source.get('_d', 'N/A'),
                                "sets": current_sets, # Original sets structure
                                "sorted_tracks": sorted_track_list # Proposed flat list
                            })
                        else:
                             # Unfixable -> track_number_issues ONLY if actual issues existed
                             if issues:
                                 stats["track_number_issues"].append({
                                    "date": show_date,
                                    "id": source.get('id', 'N/A'),
                                    "desc": source.get('_d', 'N/A'),
                                    "sets": current_sets,
                                    "issues": issues
                                })

                # --- Multiple Set 1 Detection ---
                # Run AFTER track number fix detection. If it's fixable by filename sort, we skip this check 
                # because the "Multiple Set 1" is likely a symptom of the disorder.
                is_fixable = False
                if stats["track_fixable_by_filename"]:
                    last_fixable = stats["track_fixable_by_filename"][-1]
                    if last_fixable['id'] == source.get('id'):
                        is_fixable = True
                
                if not is_fixable:
                    set1_count = sum(1 for s in current_sets if s.get('n', '').lower() == 'set 1')
                    if set1_count > 1:
                        has_set2 = any(s.get('n', '').lower() == 'set 2' for s in current_sets)
                        suggestion = ""
                        if has_set2:
                            suggestion = "Check for split sets (Acoustic/Electric) or merge?"
                        else:
                            suggestion = "Rename second 'Set 1' to 'Set 2'"
                        
                        # Diagnostic Hint Logic
                        hint = ""
                        # Check if it was in track number issues (unfixable)
                        in_issues = False
                        if stats["track_number_issues"]:
                             if stats["track_number_issues"][-1]['id'] == source.get('id'):
                                 in_issues = True
                        
                        if in_issues:
                            hint = "Source appears in Track Number Issues Report (Unfixable). Filenames likely not sortable."
                        else:
                            # It passed track number check, so numbers are sequential.
                            # Check if filenames ARE sortable, which would explain why user thinks it should be fixed.
                            can_sort_diag = True
                            for t in all_source_tracks:
                                u_val = t.get('u', '')
                                match_dt = re.search(r'd(\d+)t(\d+)', u_val, re.IGNORECASE)
                                match_t = re.search(r't(\d+)', u_val, re.IGNORECASE)
                                match_n = re.search(r'^(\d+)', u_val)
                                if not (match_dt or match_t or match_n):
                                    can_sort_diag = False
                                    break
                            
                            if can_sort_diag:
                                hint = "Filenames allow sorting, but fix was skipped because existing track numbers (n) are valid (1..N)."
                            else:
                                hint = "Filenames do not support reliable sorting (no d#t# pattern found)."

                        stats["multiple_set1_sources"].append({
                            "date": show_date,
                            "id": source.get('id', 'N/A'),
                            "desc": source.get('_d', 'N/A'),
                            "sets": current_sets,
                            "suggestion": suggestion,
                            "hint": hint
                        })

            date_log["shows"].append(show_log)
        report_logs[show_date] = date_log

    # --- Post-scan: Set Reconstruction ---
    # --- Post-scan: Set Reconstruction ---
    if set_reconstruction_report_file:
        print("    [Post-scan] Attempting Set Reconstruction on candidates...")
        
        # Build SHNID Map for Mutable Updates via Reference
        shnid_map = {}
        for show in data:
            for source in show.get('sources', []):
                if sid := source.get('id'):
                    shnid_map[str(sid)] = source

        candidates = {}
        # Order matters for priority if IDs overlap (last write wins)
        # 1. Unfixable/Generic Issues
        for cat in ['single_track_set2_sources', 'only_set1_sources', 'remaining_unlabeled_encores', 'track_number_issues', 'empty_set_sources']:
             for item in stats.get(cat, []):
                 candidates[str(item['id'])] = item
        
        # 2. Very Long Encores (>= 4 tracks) - Likely mislabeled sets
        for item in stats.get('encore_sources', []):
            if item.get('count', 0) >= 4:
                candidates[str(item['id'])] = item

        # 3. Fixable by Filename (Higher priority, use sorted tracks)
        for item in stats.get('track_fixable_by_filename', []):
             candidates[str(item['id'])] = item

        if set(candidates.keys()) and "107885" in candidates:
             print(f"DEBUG: 107885 IS in candidates. Source: {candidates['107885'].keys()}")
        else:
             print(f"DEBUG: 107885 IS NOT in candidates. Total candidates: {len(candidates)}")
             # Check if it was in any specific stats list
             for cat in ['single_track_set2_sources', 'only_set1_sources', 'remaining_unlabeled_encores', 'track_number_issues', 'empty_set_sources', 'track_fixable_by_filename']:
                 found = any(str(i['id']) == "107885" for i in stats.get(cat, []))
                 if found: print(f"DEBUG: 107885 FOUND in stats['{cat}']")

        for cid, item in candidates.items():
            # If we have pre-sorted tracks (from fixable_by_filename), use them!
            if 'sorted_tracks' in item:
                all_tracks = item['sorted_tracks']
                original_sets = [{'n': 'Original (Unsorted)', 't': item.get('sets', [])}] # Placeholder-ish or use original
            else:
                # Standard extraction from sets
                all_tracks = []
                # Handle various schema types (Standard vs Encore Report schema)
                current_sets = item.get('sets') or item.get('source_sets') or item.get('original_sets') or []
                original_sets = current_sets
                for s in current_sets:
                    for t in s.get('t', []):
                        all_tracks.append(t)
            
            if not all_tracks: 
                continue
            
            proposed_sets = []
            has_changes = False
            
            # --- Reconstruction Logic ---
            current_set_name = "Set 1"
            current_set_tracks = []
            last_t_name = ""
            for i, t in enumerate(all_tracks):
                 t_name = t.get('t', '')
                 t_filename = t.get('u', '')
                 
                 # Anchor: d1t01 always asserts Set 1
                 if ("d1t01" in t_filename or "d01t01" in t_filename) and current_set_name != "Set 1":
                      if current_set_tracks:
                          proposed_sets.append({'n': current_set_name, 't': current_set_tracks})
                          current_set_tracks = []
                      current_set_name = "Set 1"
                      has_changes = True

                 # New: Generic Disc detection
                 is_disc1 = "d1t" in t_filename or "d01t" in t_filename
                 is_disc_break = any(m in t_filename for m in ['d2t01', 'd02t01', 'd3t01', 'd03t01'])

                 # Trigger Set 2 start logic
                 triggered_set2 = False

                 # 1. Force Set 2 on Disc Break (d2t01, etc.)
                 if is_disc_break:
                     triggered_set2 = True

                 # 2. Tuning/Crowd -> Playin' in the Band (Strong Indicator of Set 2 Start)
                 # Handles variations like "Playin'", "Playing", "Tuning/Crowd", etc.
                 elif ("playin" in t_name.lower() and "band" in t_name.lower()) and \
                      any(x in last_t_name.lower() for x in ["tuning", "crowd"]):
                     triggered_set2 = True
                 
                 # 3. Heuristic Trigger (Opener List) - Case Insensitive
                 elif any(op.lower() == t_name.lower() for op in set2_openers_comprehensive):
                     triggered_set2 = True
                     # Guard: Block triggers on Disc 1 (e.g. Bertha d1t07)
                     if is_disc1:
                         triggered_set2 = False
                     # Guard: Never split The Eleven - The Other One
                     if t_name == "The Other One" and "The Eleven" in last_t_name:
                         triggered_set2 = False
                 
                 if current_set_name == "Set 1" and triggered_set2:
                      # Check for preceding Tuning/Crowd tracks to move to Set 2
                      moved_tracks = []
                      while current_set_tracks:
                          last_track = current_set_tracks[-1]
                          lt_name = last_track.get('t', '').lower()
                          if "tuning" in lt_name or "crowd" in lt_name:
                               moved_tracks.insert(0, current_set_tracks.pop())
                          else:
                               break
                      
                      if current_set_tracks:
                          proposed_sets.append({'n': current_set_name, 't': current_set_tracks})
                          current_set_tracks = []
                      
                      current_set_name = "Set 2"
                      # Add moved tracks first
                      current_set_tracks.extend(moved_tracks)
                      has_changes = True

                 # Trigger Encore start
                 # Heuristic: Only switch if we are near the end (<= 3 tracks remaining inclusive)
                 remaining_tracks = len(all_tracks) - i
                 is_near_end = remaining_tracks <= 3
                 
                 trigger_encore = (t_name in typical_encores and is_near_end)
                 
                 # Refinement: Ambiguous Closer/Encore handling (e.g. OMSN -> US Blues)
                 if trigger_encore and t_name in typical_closers:
                     next_t_name = all_tracks[i+1]['t'] if (i + 1 < len(all_tracks)) else ""
                     if next_t_name in typical_encores:
                         trigger_encore = False

                 if current_set_name != "Encore" and trigger_encore:
                       if current_set_tracks:
                           proposed_sets.append({'n': current_set_name, 't': current_set_tracks})
                           current_set_tracks = []
                       current_set_name = "Encore"
                       has_changes = True
                 
                 current_set_tracks.append(t)
                 last_t_name = t_name
            
            if current_set_tracks:
                proposed_sets.append({'n': current_set_name, 't': current_set_tracks})
             
            # Exception: Ensure "Johnny B. Goode" is always Encore if it's the very last track
            if proposed_sets:
                last_set = proposed_sets[-1]
                if last_set['n'] != 'Encore' and last_set['t']:
                    last_track = last_set['t'][-1]
                    t_name_check = last_track.get('t', '')
                    # Regex: Johnny followed by B and Goode, case insensitive
                    if re.search(r"johnny\s*b\.?\s*goode?", t_name_check, re.IGNORECASE):
                        last_set['t'].pop()
                        if not last_set['t']:
                            proposed_sets.pop()
                        proposed_sets.append({'n': 'Encore', 't': [last_track]})
             
            # --- Refinement Rules ---
            try:
                year = int(item['date'].split('-')[0])
            except:
                year = 9999

            set2 = next((s for s in proposed_sets if s['n'] == 'Set 2'), None)
            
            flatten = False
            # Rule 1: Short Set 2 (<= 3 tracks) -> Flatten
            if set2 and len(set2['t']) <= 3:
                flatten = True
            
            # Rule 2: Pre-1969 -> Flatten
            if year < 1969:
                flatten = True
             
            # Rule 3: Short Set 1 (<= 3 tracks) -> Flatten
            set1 = next((s for s in proposed_sets if s['n'] == 'Set 1'), None)
            if set1 and len(set1['t']) <= 3:
                flatten = True
                
            if flatten:
                proposed_sets = [{'n': 'Set 1', 't': all_tracks}]

            # Determine if meaningful change occurred
            sig_orig = [(s.get('n'), len(s.get('t', []))) for s in original_sets]
            sig_prop = [(s.get('n'), len(s.get('t', []))) for s in proposed_sets]
           
            if sig_orig != sig_prop:
                # Apply change to stats/report
                stats['set_reconstructions'].append({
                    'date': item['date'],
                    'id': item['id'],
                    'desc': item['desc'],
                    'original_sets': original_sets,
                    'proposed_sets': proposed_sets
                })

                # Apply change to MAIN DATA (via reference)
                if apply_changes:
                    if real_source := shnid_map.get(str(item.get('id'))):
                         real_source['sets'] = proposed_sets
                         # Remove legacy field if present to avoid confusion
                         if 'source_sets' in real_source:
                             del real_source['source_sets']
                         # Mark as updated in log?
                         # print(f"Updated {item['id']}")

    if apply_changes:
        print(f"Writing corrected data to {output_file}...")
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, separators=(',', ':'))

    print(f"Writing report to {report_file}...")
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write("# Setlist Comparison Report\n\n")
        f.write("## Script Logic\n\n")
        f.write("This script performs the following operations to clean and verify show data:\n")
        f.write("1.  **Normalization:** Track names are normalized (lowercase, no punctuation) to ensure accurate matching.\n")
        f.write("2.  **API Verification:** For each show date, it attempts to fetch the official setlist and venue information from Setlist.fm (using a local cache).\n")
        f.write("3.  **Location Updates:** Missing locations are populated using official Setlist.fm data if available.\n")
        f.write("4.  **Setlist Correction:** Local tracklists are compared against the official setlist. If a track is found in a different set in the official data (e.g., 'Encore' vs 'Set 2'), the local setlist is reorganized to match.\n")
        f.write("5.  **Track Cleaning:** Removes 'Flutter Sample' tracks and fixes track names starting with a dot ('.').\n")
        f.write("6.  **Reporting:** Generates this report detailing all updates, corrections, and potential anomalies (e.g., long encores).\n\n")

        f.write("## Generated Reports\n\n")
        f.write(f"- **Summary Report:** `{report_file}`\n")
        if detailed_report_file:
            f.write("## Generated Reports (Priority Order)\n\n")
        f.write("The following reports were generated based on the analysis. **Note:** Sources identified as 'Fixable' in the `Track Numbers Fixed Report` are prioritized and **excluded** from subsequent diagnostic reports to avoid redundancy.\n\n")
        
        if track_numbers_fixed_report_file and stats['track_fixable_by_filename']:
             f.write(f"1. **Track Numbers Fixed Report:** `{track_numbers_fixed_report_file}`\n")
             f.write("   - **Actionable Fixes:** Sources with sortable filenames (fixes Multiple Set 1s, Long Encores, etc).\n")
        
        if set_reconstruction_report_file and stats['set_reconstructions']:
             # Calculate remaining Single Track Set 2s (should be 0 if logic worked)
             remaining_single_track = 0
             for r in stats['set_reconstructions']:
                 prop = r.get('proposed_sets', [])
                 s2 = next((s for s in prop if s['n'] == 'Set 2'), None)
                 if s2 and len(s2['t']) == 1:
                     remaining_single_track += 1
             
             f.write(f"2. **Set Reconstruction Proposals:** `{set_reconstruction_report_file}`\n")
             f.write(f"   - **Proposed Fixes:** Set 2 / Encore splits for odd set structures. (Remaining Single Track Set 2: {remaining_single_track})\n")

        if detailed_report_file:
             f.write(f"3. **Detailed Report:** `{detailed_report_file}`\n")
             f.write("   - Full comparison of all processed shows.\n")

        if unlabeled_encores_report_file:
             f.write(f"4. **Unlabeled Encores Report:** `{unlabeled_encores_report_file}`\n")
             f.write("   - Potential encores detected by heuristics.\n")

        if long_encore_report_file and any(e['count'] <= 3 for e in stats["encore_sources"]):
             f.write(f"5. **Short Encore Report:** `{long_encore_report_file}`\n")
             f.write("   - Encores with 3 tracks or less (excluding fixable ones).\n")

        if very_long_encore_report_file and any(e['count'] >= 4 for e in stats["encore_sources"]):
             f.write(f"6. **Very Long Encore Report:** `{very_long_encore_report_file}`\n")
             f.write("   - Encores with 4+ tracks (likely mislabeled sets, excluding fixable ones).\n")
        
        if only_set1_report_file and stats['only_set1_sources']:
             f.write(f"7. **Only Set 1 Report:** `{only_set1_report_file}`\n")
             f.write("   - Sources that consist of ONLY 'Set 1'.\n")

        if track_number_issues_report_file and stats['track_number_issues']:
             f.write(f"8. **Track Number Issues Report:** `{track_number_issues_report_file}`\n")
             f.write("   - **Unfixable** track numbering issues requiring manual review.\n")

        if multiple_set1_report_file and stats['multiple_set1_sources']:
             f.write(f"9. **Multiple Set 1 Report:** `{multiple_set1_report_file}`\n")
             f.write("   - Sources with duplicate 'Set 1's (excluding fixable ones).\n")
        
        # Moved to LAST as requested
        if single_track_set2_report_file and stats['single_track_set2_sources']:
             f.write(f"10. **Single Track Set 2 Report:** `{single_track_set2_report_file}`\n")
             f.write("   - Sources with exactly 1 track in Set 2 (Original Candidates).\n")
        
        if only_set1_report_file and stats['only_set1_sources']:
             f.write(f"8. **Only Set 1 Report:** `{only_set1_report_file}`\n")
             f.write("   - Sources that consist of ONLY 'Set 1'.\n")

        if track_number_issues_report_file and stats['track_number_issues']:
             f.write(f"9. **Track Number Issues Report:** `{track_number_issues_report_file}`\n")
             f.write("   - **Unfixable** track numbering issues requiring manual review.\n")

        if multiple_set1_report_file and stats['multiple_set1_sources']:
             f.write(f"10. **Multiple Set 1 Report:** `{multiple_set1_report_file}`\n")
             f.write("   - Sources with duplicate 'Set 1's (excluding fixable ones).\n")
        
        f.write("\n")

        f.write("## Run Summary\n\n")

        # --- High Level Stats ---
        f.write(f"- **Shows Processed:** {stats['shows']}\n")
        f.write(f"- **Sources Processed:** {stats['sources']}\n")
        f.write(f"- **Locations Updated:** {stats['loc_updates']}\n")
        f.write(f"- **Setlists Corrected:** {stats['set_corrections']}\n")
        f.write(f"- **Sources with API-Identified Encore:** {stats['api_encores_identified']}\n")
        f.write(f"- **Sources with 1 Set:** {stats['sources_1_set']}\n")
        f.write(f"- **Banned Sources Removed:** {stats['banned_sources_removed']}\n\n")

        # --- Track Name Fixes Summary ---
        total_track_name_fixes = (
            len(stats['encore_variation_fixes']) +
            len(stats['case_corrected_track_names']) +
            len(stats['special_track_corrections_made']) +
            len(stats['track_name_corrections']) +
            stats['dot_tracks_fixed'] +
            stats['duration_in_track_name_removed'] +
            len(stats['double_slash_removed_fixes'])
        )
        f.write(f"**Total Track Name Fixes:** {total_track_name_fixes}\n\n")
        f.write("### Track Cleaning & Correction Log (In Execution Order)\n\n")

        # 1. Encore Variations
        f.write(f"**1. Encore Variation Removal:** {len(stats['encore_variation_fixes'])}\n")
        if stats['encore_variation_fixes']:
            fix_summary = {}
            for fix in stats['encore_variation_fixes']:
                original = fix['original_name']
                cleaned = fix['cleaned_name']
                if original not in fix_summary:
                    fix_summary[original] = cleaned
            for original, cleaned in sorted(fix_summary.items()):
                f.write(f"  - `{original}` -> `{cleaned}`\n")
        else:
            f.write("  - None\n")
        f.write("\n")

        # 2. Duration Artifacts
        f.write(f"**2. Duration Artifacts Removed (`{{...}}`):** {stats['duration_in_track_name_removed']}\n\n")

        # 3. Double Slashes .// %
        f.write(f"**3. Double Slash & Artifacts (`//`, `.//`, `%`) Removed:** {len(stats['double_slash_removed_fixes'])}\n")
        if stats['double_slash_removed_fixes']:
            unique_slash_fixes = sorted(list(set(stats['double_slash_removed_fixes'])), key=lambda x: x[0].lower())
            for original, corrected in unique_slash_fixes:
                f.write(f"  - `{original}` -> `{corrected}`\n")
        else:
            f.write("  - None\n")
        f.write("\n")

        # 4. Trailing Empty Parens
        f.write(f"**4. Trailing Empty Parentheses Removed (`()`):** {stats['trailing_empty_paren_removed']}\n\n")

        # 5. Case Corrections
        f.write(f"**5. Case Corrected Track Names:** {len(stats['case_corrected_track_names'])}\n")
        if stats['case_corrected_track_names']:
            unique_case_corrections = sorted(list(set(stats['case_corrected_track_names'])), key=lambda x: x[0].lower())
            for original, corrected in unique_case_corrections:
                f.write(f"  - `{original}` -> `{corrected}`\n")
        else:
            f.write("  - None\n")
        f.write("\n")
        
        # 6. Special Corrections
        f.write(f"**6. Special Track Corrections (e.g., 'Quinn' variations):** {len(stats['special_track_corrections_made'])}\n")
        if stats['special_track_corrections_made']:
            unique_special_corrections = sorted(list(set(stats['special_track_corrections_made'])), key=lambda x: x[0].lower())
            for original, corrected in unique_special_corrections:
                f.write(f"  - `{original}` -> `{corrected}`\n")
        else:
            f.write("  - None\n")
        f.write("\n")
        
        # 7. Leading Dot
        f.write(f"**7. Track Names with Leading Dot Fixed:** {stats['dot_tracks_fixed']}\n\n")

        # 8. Flutter Sample
        f.write(f"**8. 'Flutter Sample' Tracks Removed:** {stats['flutter_sample_removed']}\n\n")

        # 9. Dictionary Corrections
        f.write(f"**9. Dictionary Track Name Corrections:** {len(stats['track_name_corrections'])}\n")
        if stats['track_name_corrections']:
            around_fixes_count = stats['track_name_corrections'].count("Around")
            if around_fixes_count > 0:
                f.write(f"  - `Around` -> `Around And Around` fixes: {around_fixes_count}\n")
            
                corrected_name = TRACK_NAME_CORRECTIONS.get(original_name, "N/A") 
                f.write(f"  - `{original_name}` -> `{corrected_name}`\n")
        
        # 10. Non-MP3 Tracks
        f.write(f"**10. Non-MP3 Tracks Detected:** {len(stats['non_mp3_tracks'])}\n")
        if stats['non_mp3_tracks']:
            f.write("  *(Tracks with extensions like .flac, .shn, .wav, but not .mp3)*\n")
            for item in stats['non_mp3_tracks']:
                 f.write(f"  - {item['date']} (SHNID: {item['id']}): `{item['track']}`\n")
        

        f.write("\n- **Encore Track Counts:**\n")
        if stats["encore_track_counts"]:
            for count, freq in sorted(stats["encore_track_counts"].items()):
                f.write(f"  - {count} track(s): {freq}\n")
        else:
            f.write("  - None\n")
        f.write("\n")

        # --- Metadata ---
        f.write("---\n")
        f.write(f"- **Run Mode:** {run_mode}\n")
        f.write(f"- **Input File:** `{input_file}`\n")
        f.write(f"- **Output File:** `{output_file}`" + ("\n" if apply_changes else " (No changes written in Mock Run)\n"))


    if detailed_report_file:
        print(f"Writing detailed report to {detailed_report_file}...")
        with open(detailed_report_file, 'w', encoding='utf-8') as f:
            f.write("## Detailed Comparison\n\n")
            for date, logs in sorted(report_logs.items()):
                # Check if this date has any updates worth reporting
                has_date_updates = any(s.get("location_updated") for s in logs["shows"]) or \
                                   any(src['set_updated'] for s in logs["shows"] for src in s["sources"])

                if not has_date_updates:
                    continue

                # Determine the best display venue and location, preferring official data
                main_show_log = logs["shows"][0] if logs["shows"] else {}
                display_venue = logs.get("official_venue") or main_show_log.get("json_name", "Unknown")
                display_loc = logs.get("official_location") or main_show_log.get("json_location", "")
                loc_str = f" ({display_loc})" if display_loc else ""
                f.write(f"### {date} - {display_venue}{loc_str}\n\n")

                for note in logs["venue_notes"]: f.write(f"**Note:** {note}.\n")
                for note in logs["location_notes"]: f.write(f"**Note:** {note}.\n")
                if logs["venue_notes"] or logs["location_notes"]: f.write("\n")

                if logs['location_updates']:
                    f.write("**Location Updates on this Date:**\n\n")
                    for update in logs['location_updates']: f.write(f"- {update}\n")
                    f.write("\n")

                f.write("**Official Setlist.fm Data**\n\n")
                if official_data := logs.get("official_setlist"):
                    official_sets = official_data.get("sets", {}).get("set", [])
                    if official_sets:
                        report_sets = []
                        set_counter = 1
                        for s in official_sets:
                            set_name = "Encore" if s.get('encore') else f"Set {set_counter}"
                            if not s.get('encore'): set_counter += 1
                            report_sets.append({'n': set_name, 't': [{'t': song.get("name")} for song in s.get("song", []) if song.get("name")]})
                        f.write(format_setlist_for_report(report_sets))
                    else:
                        f.write("*No sets found.*\\n\\n")
                else:
                    f.write("*None found.*\\n\\n")

                f.write("\n**Matching Sources from Input File**\n\n")
                if not logs["shows"]:
                    f.write("*No shows found in input file for this date.*\\n\\n")
                else:
                    for i, show_log in enumerate(logs["shows"]):
                        # Check if this show or any of its sources has updates
                        show_has_loc_update = show_log.get("location_updated")
                        sources_with_updates = [src for src in show_log["sources"] if src['set_updated']]

                        if not show_has_loc_update and not sources_with_updates:
                            continue

                        sources_to_list = show_log["sources"] if show_has_loc_update else sources_with_updates
                        if not sources_to_list: continue

                        for j, source_entry in enumerate(sources_to_list):
                            source = source_entry['data']
                            is_set_updated = source_entry['set_updated']

                            json_name = show_log.get('json_name', 'N/A')
                            json_loc = show_log.get('json_location', '')
                            json_loc_display = json_loc
                            updated_str = " *(Updated from Setlist)*" if show_log.get("location_updated") else ""
                            if is_set_updated: updated_str += " *(Setlist Updated)*"

                            f.write(f"- **JSON Name:** `{json_name}`\n")
                            f.write(f"- **JSON Location:** `{json_loc_display}`{updated_str}\n")

                            official_venue = logs.get('official_venue')
                            if official_venue:
                                 official_loc = logs.get('official_location', '')
                                 official_loc_str = f" ({official_loc})" if official_loc else ""
                                 f.write(f"- **Official Venue:** `{official_venue}`{official_loc_str}\n")

                            f.write(f"- **Source Path:** `{source.get('_d', 'N/A')}`\n")
                            f.write(f"- **SHNID:** `{source.get('id', 'N/A')}`\n")
                            f.write(f"- **Tracks:**\n")

                            if source_sets := source.get('sets', []):
                                f.write(format_setlist_for_report(source_sets, source.get('_d')))
                            else:
                                f.write("  *No tracks listed.*\\n\\n")
                            if j < len(show_log["sources"]) - 1: f.write("---\n")
                    if i < len(logs["shows"]) - 1: f.write("----\n")
                f.write("---\n")

    if track_numbers_fixed_report_file:
        print(f"Writing track numbers fixed report to {track_numbers_fixed_report_file}...")
        with open(track_numbers_fixed_report_file, 'w', encoding='utf-8') as f:
            f.write("# Track Numbers Fixed Report\n\n")
            f.write("This report lists sources detected with track number issues that CAN be resolved by sorting based on filenames (e.g., `d1t01`).\n\n")
            f.write(f"**Total Fixable Sources:** {len(stats['track_fixable_by_filename'])}\n\n")
            
            for item in stats["track_fixable_by_filename"]:
                f.write(f"## {item['date']} - SHNID: {item['id']}\n\n")
                f.write(f"- **Archive URL:** https://archive.org/details/{item['desc']}\n\n")
                
                f.write("### Current Order (Compact)\n\n")
                f.write(format_setlist_for_report(item['sets'], item['desc']))
                f.write("\n")
                
                # Format the sorted flat list with NORMALIZED track numbers
                normalized_tracks = []
                for i, t in enumerate(item['sorted_tracks'], 1):
                    t_new = t.copy()
                    t_new['n'] = str(i)
                    normalized_tracks.append(t_new)

                sorted_set_structure = [{'n': 'Proposed Filename Sorted Order', 't': normalized_tracks}]
                
                f.write("### Proposed Filename Sorted Order\n\n")
                f.write(format_setlist_for_report(sorted_set_structure, item['desc']))
                f.write("\n---\n\n")

    if unlabeled_encores_report_file:
        print(f"Writing unlabeled encores report to {unlabeled_encores_report_file}...")
        with open(unlabeled_encores_report_file, 'w', encoding='utf-8') as f:
            f.write("# Potential Unlabeled Encores Report\n\n")
            f.write("This report lists sources with potential unlabeled encores, indicating those fixed by rule-based classification and those remaining.\n\n")
            
            remaining_unlabeled_count = len(stats['remaining_unlabeled_encores'])
            f.write(f"**Summary:**\n\n")
            f.write(f"- Fixed by Rule-Based Classification: {len(stats['rule_based_encore_fixes'])}\n")
            f.write(f"- Remaining Potential Unlabeled Encores: {remaining_unlabeled_count}\n\n")

            f.write("### Missing Encore Analysis (Tally by Last Track)\n\n")
            f.write("| Last Track | Count | Classification |\n")
            f.write("|---|---|---|\n")
            
            # Sort by count desc
            sorted_tally = sorted(stats['missing_encore_analysis'].items(), key=lambda item: item[1]['count'], reverse=True)
            
            for track_name, info in sorted_tally:
                f.write(f"| {track_name} | {info['count']} | {info['type']} |\n")
            f.write("\n")

            if stats["remaining_unlabeled_encores"]:
                f.write("---\n\n ## Remaining Potential Unlabeled Encores\n\n")
                for item in stats["remaining_unlabeled_encores"]:
                    f.write(f"### {item['date']} - SHNID: {item.get('id', 'N/A')}\n\n")
                    f.write(f"- **Archive URL:** https://archive.org/details/{item['desc']}\n\n")
                    f.write(format_setlist_for_report(item['source_sets'], item['desc']))

                    # Add hint about the last track
                    last_track_name = None
                    if item['source_sets']:
                        last_set = item['source_sets'][-1]
                        if last_set.get('t'):
                            last_track_name = last_set['t'][-1].get('t')
                    
                    if last_track_name:
                        if last_track_name in typical_encores:
                            f.write(f"**Hint:** The last track, `{last_track_name}`, is a typical encore.\n\n")
                        elif last_track_name in typical_closers:
                            f.write(f"**Hint:** The last track, `{last_track_name}`, is a typical set closer.\n\n")
                    f.write("\n---\n\n")

            else:
                f.write("No remaining potential unlabeled encores found.\n")
            f.write("\n")

    if long_encore_report_file and any(e['count'] <= 3 for e in stats["encore_sources"]):
        print(f"Writing short encore report to {long_encore_report_file}...")
        with open(long_encore_report_file, 'w', encoding='utf-8') as f:
            f.write("# Short Encore Report (3 or less tracks)\n\n")
            fixable_ids = {str(item['id']) for item in stats['track_fixable_by_filename']}
            short_encores = [e for e in stats["encore_sources"] if e['count'] <= 3 and str(e['id']) not in fixable_ids]
            corrected_count = sum(1 for item in short_encores if item['original_sets'] != item['corrected_sets'])
            f.write(f"**Summary:**\n\n")
            f.write(f"- Total sources with short encores: {len(short_encores)}\n")
            f.write(f"- Sources with corrected setlists: {corrected_count}\n\n")
            for item in short_encores:
                f.write(f"## {item['date']} - SHNID: {item['id']}\n\n")
                f.write(f"- **Archive URL:** https://archive.org/details/{item['desc']}\n")
                f.write(f"- **Encore Track Count:** {item['count']}\n\n")
                f.write("### Original Sets\n\n")
                f.write(format_setlist_for_report(item['original_sets'], item['desc']))
                f.write("\n")
                f.write("### Corrected Sets (from Setlist.fm)\n\n")
                f.write(format_setlist_for_report(item['corrected_sets'], item['desc']))
                f.write("\n---\n\n")

    if very_long_encore_report_file and any(e['count'] >= 4 for e in stats["encore_sources"]):
        print(f"Writing very long encore report to {very_long_encore_report_file}...")
        with open(very_long_encore_report_file, 'w', encoding='utf-8') as f:
            f.write("# Very Long Encore Report (4 or more tracks)\n\n")
            fixable_ids = {str(item['id']) for item in stats['track_fixable_by_filename']}
            long_encores = [e for e in stats["encore_sources"] if e['count'] >= 4 and str(e['id']) not in fixable_ids]
            corrected_count = sum(1 for item in long_encores if item['original_sets'] != item['corrected_sets'])
            f.write(f"**Summary:**\n\n")
            f.write(f"- Total sources with long encores: {len(long_encores)}\n")
            f.write(f"- Sources with corrected setlists: {corrected_count}\n\n")
            for item in long_encores:
                f.write(f"## {item['date']} - SHNID: {item['id']}\n\n")
                f.write(f"- **Archive URL:** https://archive.org/details/{item['desc']}\n")
                f.write(f"- **Encore Track Count:** {item['count']}\n\n")
                f.write("### Original Sets\n\n")
                f.write(format_setlist_for_report(item['original_sets'], item['desc']))
                f.write("\n")
                f.write("### Corrected Sets (from Setlist.fm)\n\n")
                f.write(format_setlist_for_report(item['corrected_sets'], item['desc']))
                f.write("\n---\n\n")

    if track_number_issues_report_file:
        print(f"Writing track number issues report to {track_number_issues_report_file}...")
        with open(track_number_issues_report_file, 'w', encoding='utf-8') as f:
            f.write("# Track Number Issues Report (Unfixable / Manual Review)\n\n")
            f.write("This report lists sources with track number issues that **CANNOT** be automatically resolved by filename sorting.\n")
            f.write("This report lists sources with track number issues that **CANNOT** be automatically resolved by filename sorting.\n")
            f.write("These sources likely require manual review or custom logic.\n\n")
            f.write(f"**Total Sources with Issues:** {len(stats['track_number_issues'])}\n\n")
            
            for item in stats["track_number_issues"]:
                f.write(f"## {item['date']} - SHNID: {item['id']}\n\n")
                f.write(f"- **Archive URL:** https://archive.org/details/{item['desc']}\n")
                f.write(f"- **Issues Found:**\n")
                for issue in item['issues']:
                    f.write(f"  - {issue}\n")
                f.write("\n")
                f.write("### Tracklist (Current Order)\n\n")
                f.write(format_setlist_for_report(item['sets'], item['desc']))
                f.write("\n")
                
                # Create Proposed Sorted Order (Flattened)
                all_tracks = [t for s in item['sets'] for t in s.get('t', [])]
                def get_n_safe(t):
                    val = t.get('n', 9999)
                    try:
                        return int(val)
                    except:
                        return 9999
                
                sorted_tracks = sorted(all_tracks, key=get_n_safe)
                # Group into a dummy set for formatting
                sorted_set_structure = [{'n': 'Proposed Sorted Order (Flattened)', 't': sorted_tracks}]
                
                f.write("### Proposed Sorted Order (By 'n')\n\n")
                f.write(format_setlist_for_report(sorted_set_structure, item['desc']))
                f.write("\n---\n\n")

    print("Done.")

    if multiple_set1_report_file and stats["multiple_set1_sources"]:
        print(f"Writing multiple Set 1s report to {multiple_set1_report_file}...")
        with open(multiple_set1_report_file, 'w', encoding='utf-8') as f:
            f.write("# Sources with Multiple 'Set 1's\n\n")
            f.write(f"**Total Sources Found:** {len(stats['multiple_set1_sources'])}\n\n")
            
            for item in stats["multiple_set1_sources"]:
                f.write(f"## {item['date']} - SHNID: {item['id']}\n\n")
                f.write(f"- **Archive URL:** https://archive.org/details/{item['desc']}\n")
                f.write(f"- **Suggestion:** {item['suggestion']}\n")
                if item.get('hint'):
                    f.write(f"- **Diagnostic Hint:** {item['hint']}\n")
                f.write("\n")
                f.write("### Setlist Structure\n\n")
                f.write("### Setlist Structure\n\n")
                f.write(format_setlist_for_report(item['sets'], item['desc']))
                f.write("\n---\n\n")

    if single_track_set2_report_file and stats["single_track_set2_sources"]:
        fixable_ids = {str(item['id']) for item in stats['track_fixable_by_filename']}
        filtered_sources = [s for s in stats["single_track_set2_sources"] if str(s['id']) not in fixable_ids]

        if filtered_sources:
            print(f"Writing single track Set 2 report to {single_track_set2_report_file}...")
            with open(single_track_set2_report_file, 'w', encoding='utf-8') as f:
                f.write("# Sources with 1 Track in Set 2\n\n")
                f.write(f"**Total Sources Found:** {len(filtered_sources)}\n\n")
                
                for item in filtered_sources:
                    f.write(f"## {item['date']} - SHNID: {item['id']}\n\n")
                    f.write(f"- **Archive URL:** https://archive.org/details/{item['desc']}\n")
                    f.write("\n")
                    f.write("### Setlist Structure\n\n")
                    f.write(format_setlist_for_report(item['sets'], item['desc']))
                    f.write("\n---\n\n")


    if only_set1_report_file and stats["only_set1_sources"]:
        print(f"Writing Only Set 1 report to {only_set1_report_file}...")
        with open(only_set1_report_file, 'w', encoding='utf-8') as f:
            f.write("# Sources with Only 'Set 1'\n\n")
            f.write(f"**Total Sources Found:** {len(stats['only_set1_sources'])}\n\n")
            
            for item in stats["only_set1_sources"]:
                f.write(f"## {item['date']} - SHNID: {item['id']}\n\n")
                f.write(f"- **Archive URL:** https://archive.org/details/{item['desc']}\n")
                f.write("\n")
                f.write("### Setlist Structure\n\n")
                f.write(format_setlist_for_report(item['sets'], item['desc']))
                f.write("\n---\n\n")


    if set_reconstruction_report_file and stats["set_reconstructions"]:
        print(f"Writing Set Reconstruction report to {set_reconstruction_report_file}...")
        with open(set_reconstruction_report_file, 'w', encoding='utf-8') as f:
            f.write("# Set Reconstruction Proposals\n\n")
            f.write(f"**Total Reconstructions Proposed:** {len(stats['set_reconstructions'])}\n\n")
            f.write("This report proposes Set 2 / Encore splits for sources detected as 'Single Track Set 2', 'Only Set 1', or 'Unlabeled Encore candidates'.\n\n")
            
            for item in stats["set_reconstructions"]:
                f.write(f"## {item['date']} - SHNID: {item['id']}\n\n")
                f.write(f"- **Archive URL:** https://archive.org/details/{item['desc']}\n\n")
                f.write("### Original Structure\n\n")
                f.write(format_setlist_for_report(item['original_sets'], item['desc']))
                f.write("\n")
                f.write("### Proposed Reconstruction\n\n")
                f.write(format_setlist_for_report(item['proposed_sets'], item['desc']))
                f.write("\n---\n\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Fix set placement and missing locations against API with caching.')
    parser.add_argument('--input', default='assets/data/output.optimized_src.json', help='Input JSON file')
    parser.add_argument('--output', default='assets/data/output.optimized_src_api.json', help='Output JSON file')
    parser.add_argument('--report', default='fix_report.md', help='Output report file')
    parser.add_argument('--long-encore-report', default='long_encore_report.md', help='Output report file for encores with 3 or less tracks')
    parser.add_argument('--very-long-encore-report', default='very_long_encore_report.md', help='Output report file for encores with 4 or more tracks')
    parser.add_argument('--detailed-report', default='detailed_report.md', help='Output report file for detailed comparison')
    parser.add_argument('--unlabeled-encores-report', default='unlabeled_encores_report.md', help='Output report file for potential unlabeled encores')
    parser.add_argument('--multiple-set1-report', default='multiple_set1_report.md', help='Output report file for sources with multiple Set 1s')
    parser.add_argument('--track-number-issues-report', default='track_number_issues_report.md', help='Output report file for track number sequence issues')
    parser.add_argument('--track-numbers-fixed-report', default='track_numbers_fixed_report.md', help='Output report file for sources fixable by filename sort')
    parser.add_argument('--single-track-set2-report', default='single_track_set2_report.md', help='Output report file for sources with exactly 1 track in Set 2')
    parser.add_argument('--only-set1-report', default='only_set1_report.md', help='Output report file for sources with only Set 1')
    parser.add_argument('--set-reconstruction-report', default='set_reconstruction_report.md', help='Output report file for reconstructed sets')
    parser.add_argument('--limit', type=int, help='Limit number of dates to process')
    parser.add_argument('--apply-changes', action='store_true', help='Apply setlist changes to the output file. Default is a mock run.')
    parser.add_argument('--online', action='store_true', help='Enable API calls to Setlist.fm (default is Offline)')
    args = parser.parse_args()
    fix_sets(args.input, args.output, args.report, args.long_encore_report, args.very_long_encore_report, args.detailed_report, args.unlabeled_encores_report, args.multiple_set1_report, args.track_number_issues_report, args.track_numbers_fixed_report, args.single_track_set2_report, args.only_set1_report, args.set_reconstruction_report, args.limit, args.apply_changes, args.online)
