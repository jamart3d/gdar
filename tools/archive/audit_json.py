import json
import argparse
import sys
from collections import defaultdict

import re
# Known corrections map: Date -> (Venue, Location)
KNOWN_VENUE_LOCATIONS = {
    "1968-01-22": ("Eagles Auditorium", "Seattle, Wa"),
    "1968-01-23": ("Eagles Auditorium", "Seattle, Wa"),
    "1968-10-08": ("The Matrix", "San Francisco, Ca"),
    "1968-10-10": ("The Matrix", "San Francisco, Ca"),
    "1968-10-30": ("The Matrix", "San Francisco, Ca"),
    "1968-11-06": ("Pacific High Recording", "San Francisco, Ca"),
    "1969-06-01": ("Avalon Ballroom", "San Francisco, Ca"),
    "1969-08-28": ("Family Dog at the Great Highway", "San Francisco, Ca"), # Inferred loc from context/list pattern usually SF
    "1970-12-17": ("The Matrix", "San Francisco, Ca"),
    "1971-05-30": ("Winterland Arena", "San Francisco, Ca"),
    "1975-07-23": ("Club Front", "San Rafael, Ca"),
    "1975-07-24": ("Club Front", "San Rafael, Ca"),
    "1975-09-16": ("Club Front", "San Rafael, Ca"),
    "1976-05-28": ("Club Front", "San Rafael, Ca"),
    "1978-09-13": ("Gizah Sound and Light Theater", "Giza, Egypt"),
    "1978-11-08": ("Capitol Center", "Landover, Md"),
    "1980-10-01": ("Warfield Theatre & Radio City Music Hall", "San Francisco, CA & New York, NY"), # Best guess or null?
    "1981-03-04": ("Club Front", "San Rafael, Ca"),
    "1981-12-11": ("Club Front", "San Rafael, Ca"),
    "1982-01-01": ("Mickey's ranch studio", "Novato, Ca"),
    "1982-11-26": ("Bob Marley Performing Arts Center", "Montego Bay, Jam"),
    "1985-04-21": ("Marin Veterans Memorial Auditorium", "Marin, Ca"),
    "1986-12-01": ("Club Front", "San Rafael, Ca"),
    "1987-03-28": ("Hampton Coliseum", "Hampton, Va"),
    "1987-06-01": ("Club Front", "San Rafael, Ca"),
    "1987-07-13": ("Robert F. Kennedy Stadium", "Washington, DC"),
    "1989-09-09": ("The Spectrum", "San Rafael, Ca"),
    "1990-08-28": ("Club Front", "San Rafael, Ca"),
    "1990-09-26": ("Club Front", "San Rafael, Ca"),
    "1990-09-27": ("Club Front", "San Rafael, Ca"),
    "1990-09-28": ("Club Front", "San Rafael, Ca"),
    "1992-02-13": ("Club Front", "San Rafael, Ca"),
    "1992-02-21": ("Club Front", "San Rafael, Ca"),
    "1993-02-10": ("Club Front", "San Rafael, Ca"),
    "1994-02-24": ("Oakland County Coliseum", "Oakland, Ca"),
    "1995-03-28": ("The Omni", "Atlanta, Ga")
}

def get_source_map(data):
    """Builds a map of shnid -> {sets: signature} for comparison."""
    source_map = {}
    for show in data:
        for source in show.get('sources', []):
            shnid = source.get('id')
            if not shnid: continue
            
            # Get Set Signature
            sets = source.get('sets', [])
            if not sets and 'source_sets' in source:
                 sets = source['source_sets']
            
            sig = []
            for s in sets:
                s_name = s.get('n', 'Unk')
                t_count = len(s.get('t', []))
                sig.append(f"{s_name}({t_count})")
            
            source_map[shnid] = ", ".join(sig)
    return source_map

# --- Classification Logic (Ported from fix_sets_api.py) ---
typical_closers = [
    "Sugar Magnolia", "Sunshine Daydream", "One More Saturday Night", 
    "Not Fade Away", "Goin' Down the Road Feeling Bad", "Good Lovin'", 
    "Around and Around", "Johnny B. Goode", "U.S. Blues", "Casey Jones", 
    "Turn On Your Love Light", "Estimated Prophet", "Morning Dew", 
    "The Music Never Stopped", "Throwing Stones", "Deal"
]

typical_encores = [
    "U.S. Blues", "One More Saturday Night", "Johnny B. Goode", 
    "Brokedown Palace", "And We Bid You Goodnight", "Baby Blue", 
    "Mighty Quinn", "Liberty", "Box of Rain", "Black Muddy River", 
    "I Fought the Law", "Werewolves of London"
]

def get_song_script_logic(song_title):
    # Data dictionary defining the role and script beats for each song
    dead_logic = {
        "Box of Rain": {
            "role": "Emotional Encore",
            "stat": "58% Encore frequency",
            "hook": "The spiritual send-off. Mention the 1986 bust-out and the 1995 finale."
        },
        "The Weight": {
            "role": "Curtain Call",
            "stat": "93% Encore frequency",
            "hook": "The vocal trade-off. Focus on the brotherhood of the final years."
        },
        "Casey Jones": {
            "role": "Set I Closer",
            "stat": "Rarely an Encore (6%)",
            "hook": "The 'runaway train' effect. It leaves the crowd hanging for Set II."
        },
        "Truckin'": {
            "role": "Set II Engine",
            "stat": "Near-zero Encore frequency",
            "hook": "The bridge to the jam. Not a destination, but a journey."
        },
        "Around and Around": {
            "role": "Rock & Roll Finale",
            "stat": "25% Show-ending frequency",
            "hook": "The high-octane gear shift. This is the 'lights up' song of the late 70s."
        },
        "One More Saturday Night": {
            "aliases": ["omsn", "saturday night", "e_omsn", "one saturday night (you were warned)"],
            "role": "Calendar Specialist", # Role maps to action
            "stat": "98% on Saturdays",
            "hook": "The automatic Saturday finale. If it's Saturday, Bobby is screaming the ending."
        },
        "The Weight": {
            "role": "Curtain Call",
            "stat": "Absolute final track of the 90s",
            "hook": "The 90s era 'curtain call' encore."
        },
        "Turn on Your Lovelight": {
             "aliases": ["love light", "lovelight", "turn on your love light #", "lovelight -", "turn on your love light"],
             "role": "Era-Dependent Finale",
             "stat": "Pigpen's 20-minute marathon",
             "hook": "In multi-set shows, this often ended Set 2 without a following encore."
        },
        "And We Bid You Goodnight": {
            "aliases": ["awbygn", "we bid you good night", "goodnight irene", "and we bid you good night", "we bid you goodnight"],
            "role": "Final Blessing",
            "stat": "A cappella finale",
            "hook": "Played a cappella after the instruments were down."
        },
        "Brokedown Palace": {
            "role": "The Lullaby",
            "stat": "Definitive sentimental encore",
            "hook": "If this is played, the night is over."
        },
        "Not Fade Away": {
            "aliases": ["not fade away -", "not fade away (1)", "not fade away*-"],
            "role": "Ritual Finale",
            "stat": "80% chance it closes Set II",
            "hook": "The Bo Diddley beat. Look for the 'Chant' in the script."
        },
        "Good Lovin'": {
            "role": "Party Closer",
            "stat": "15% chance as standalone encore",
            "hook": "Alternates with Sugar Magnolia."
        },
        "It's All Over Now Baby Blue": {
            "aliases": ["it's all over now, bbay blue", "(it's all over now) baby blue"],
            "role": "Soft Landing",
            "stat": "Standard Dylan Encore",
            "hook": "Standard 'Soft Landing' Dylan encore."
        },
        "Scarlet Begonias": {
            "role": "Second Set Opener",
            "stat": "< 1% Encore",
            "hook": "The spark plug. It signals that the heavy jamming is about to begin."
        },
        "Morning Dew": {
            "role": "Emotional Apex",
            "stat": "Second Set Ballad",
            "hook": "The 'spiritual center' of the show. Rarely the final song, but often the most important."
        },
        "Sugar Magnolia": {
            "aliases": ["sugar magnolia-", "sugar magnolia /", "sunshine daydream"],
            "role": "Set II Closer",
            "stat": "Usually the main set peak",
            "hook": "If played as encore, look for 'Sunshine Daydream' reprise."
        },
        "Revolution": {
            "role": "Special Event Encore",
            "stat": "91% Encore frequency",
            "hook": "A rare Beatles bust-out. Check for birthdays (Phil's or Lennon's)."
        },
        "Rain": {
            "role": "Atmospheric Closer",
            "stat": "51% First Set Closer",
            "hook": "Beatles cover (1992-1995). Check for outdoor weather context."
        }
    }

    # Case-insensitive lookup (exact match)
    song_map = {k.lower(): v for k, v in dead_logic.items()}
    found_logic = song_map.get(song_title.lower())
    
    if found_logic:
        return found_logic
        
    # Alias lookup
    lower_title = song_title.lower()
    for key, data in dead_logic.items():
        if "aliases" in data:
            for alias in data["aliases"]:
                if alias.lower() == lower_title: # Strict alias match? or 'in'? User aliases look specific.
                     return data
                     
    # Substring match on Key (Legacy fallback)
    # for key, data in dead_logic.items():
    #     if key.lower() in lower_title:
    #         return data



    # Logic to return the data or a default if song isn't found
    return {"role": "Varies", "stat": "N/A", "hook": "Standard rotation."}

def classify_dead_tracks(date, track_list):
    """
    date: 'YYYY-MM-DD'
    track_list: List of the final 4-5 songs of the show in order.
    """
    try:
        year = int(date.split('-')[0])
    except:
        year = 0
        
    last_song = track_list[-1]
    penultimate = track_list[-2] if len(track_list) > 1 else None

    # Result structure
    show_structure = {"Set_Closer": [], "Encore": []}

    # 1. PURE ENCORE LIST (Assume these are always encores if at the end)
    pure_encores = ["The Mighty Quinn", "Quinn the Eskimo", "Satisfaction", "(I Can't Get No) Satisfaction", "Brokedown Palace", "Liberty", "The Weight", "Lucy in the Sky with Diamonds"]
    
    # 2. PURE CLOSER LIST (Assume these trigger the encore break)
    # Around and Around Eras:
    # - 1970–1974: First Set Closer (High frequency)
    # - 1976–1980: Second Set Closer (Peak frequency)
    # - 1981–1995: Mid-Second Set (Lower frequency) -> If found at end, treat as Closer (or cut tape), NOT Encore.
    pure_closers = ["Around and Around", "Around & Around", "Sugar Magnolia", "Sunshine Daydream", "Good Lovin'"]

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

    # 5. Handle Casey Jones Eras
    # 1970–1973: Triple Encore Era
    # 1977–1984: Mid-Period Rarity
    # 1992–1993: 90s Revival
    if "Casey Jones" in [last_song, penultimate]:
        is_casey_encore = False
        if 1970 <= year <= 1973: is_casey_encore = True
        elif 1977 <= year <= 1984: is_casey_encore = True
        elif 1992 <= year <= 1993: is_casey_encore = True
        
        if is_casey_encore:
            if last_song == "Casey Jones":
                 show_structure["Encore"] = ["Casey Jones"]
                 show_structure["Set_Closer"] = [penultimate]
                 return show_structure
            elif penultimate == "Casey Jones" and last_song in ["Johnny B. Goode", "Uncle John's Band"]:
                 show_structure["Encore"] = ["Casey Jones", last_song]
                 show_structure["Set_Closer"] = [track_list[-3]]
                 return show_structure

    # 6. Handle "Day Job" Eras
    # 12/15/1982: Debut, only time closing Set 1.
    # 1982–1986: Standard Encore run.
    # 06/24/1995: The "Bust-Out" Encore.
    if last_song in ["Day Job", "Keep Your Day Job"]:
        if date == "1982-12-15":
             show_structure["Set_Closer"] = [last_song]
             return show_structure
        elif (1982 <= year <= 1986) or date == "1995-06-24":
             show_structure["Encore"] = [last_song]
             return show_structure

    # 7. Standard Era Logic (Post-1977)
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


    # 8. User Provided Script Logic
    script_logic = get_song_script_logic(last_song)
    role = script_logic.get("role", "")
    
    if "Encore" in role or "Curtain Call" in role or "Calendar Specialist" in role or "Lullaby" in role or "Final Blessing" in role or "Soft Landing" in role:
         if role == "Emotional Encore": # Special case for Box of Rain to ensure it's treated right
            show_structure["Encore"] = [last_song]
            show_structure["Set_Closer"] = [penultimate]
            return show_structure
         
         # The Weight (Curtain Call), OMSN (Calendar), Brokedown (Lullaby)
         show_structure["Encore"] = [last_song]
         show_structure["Set_Closer"] = [penultimate]
         return show_structure

    elif "Closer" in role or "Finale" in role or "Engine" in role or "Opener" in role or "Apex" in role:
         # Treat as Set Closer (SKIP)
         show_structure["Set_Closer"] = [last_song]
         show_structure["Encore"] = ["(No Encore Played)"]
         return show_structure

    # Ensure we return something even if no specific rules matched
    return show_structure

def generate_encore_rules(data):
    """Finds candidates for missing encores and groups by last track name."""
    candidates = defaultdict(lambda: {"count": 0, "types": defaultdict(int), "dates": []})
    
    for show in data:
        show_date = show.get('date', 'Unknown')
        for source in show.get('sources', []):
            sets = source.get('sets', [])
            if not sets and 'source_sets' in source: sets = source['source_sets']
            if not sets: continue
            
            has_set2 = any(s.get('n') == "Set 2" for s in sets)
            has_set3 = any(s.get('n') == "Set 3" for s in sets)
            has_encore = any(s.get('n') == "Encore" for s in sets)
            total_tracks = sum(len(s.get('t', [])) for s in sets)
            
            if total_tracks > 13 and (has_set2 or has_set3) and not has_encore:
                last_set = sets[-1]
                if last_set.get('t'):
                    # Get last few tracks for classification
                    track_names = [t.get('t', '') for t in last_set['t']]
                    last_track_name = track_names[-1].strip().lower()
                    
                    # Run Classification
                    classification = "Unknown"
                    if len(track_names) >= 1:
                        classified = classify_dead_tracks(show_date, track_names[-5:])
                        if classified.get("Encore") and classified["Encore"] != ["(No Encore Played)"]:
                            classification = "Encore"
                        elif classified.get("Encore") == ["(No Encore Played)"]:
                            classification = "Set_Closer"
                    
                    candidates[last_track_name]["count"] += 1
                    candidates[last_track_name]["types"][classification] += 1
                    candidates[last_track_name]["dates"].append(show_date)

    # Convert to rules list with smart defaults
    rules = []
    for name, info in sorted(candidates.items(), key=lambda x: x[1]["count"], reverse=True):
        # Determine likely classification (majority vote)
        likely_type = max(info["types"].items(), key=lambda x: x[1])[0]
        
        # Default Action
        default_action = "SKIP"
        if likely_type == "Encore":
            default_action = "MOVE_1"
        
        rules.append({
            "last_track": name,
            "count": info["count"],
            "classification": likely_type,
            "action": default_action
        })
    return rules

def apply_encore_rules(data, rules_path):
    """Applies encore fixes based on rules file."""
    try:
        with open(rules_path, 'r') as f:
            rules_list = json.load(f)
    except Exception as e:
        print(f"Error reading rules file: {e}")
        return data
        
    # Create lookup map
    rules_map = {r['last_track']: r['action'] for r in rules_list}
    
    applied_count = 0
    
    for show in data:
        show_date = show.get('date', 'Unknown')
        for source in show.get('sources', []):
            sets = source.get('sets', [])
            if not sets and 'source_sets' in source: sets = source['source_sets']
            if not sets: continue
            
            has_set2 = any(s.get('n') == "Set 2" for s in sets)
            has_set3 = any(s.get('n') == "Set 3" for s in sets)
            has_encore = any(s.get('n') == "Encore" for s in sets)
            total_tracks = sum(len(s.get('t', [])) for s in sets)
            
            if total_tracks > 13 and (has_set2 or has_set3) and not has_encore:
                last_set = sets[-1]
                if last_set.get('t'):
                    track_names = [t.get('t', '') for t in last_set['t']]
                    last_track_name = track_names[-1].strip().lower()
                    
                    action = "SKIP"
                    
                    # Special Rule: e_omsn
                    if last_track_name == "e_omsn":
                        # Rename in place
                        last_set['t'][-1]['t'] = "One More Saturday Night"
                        action = "MOVE_1"
                    else:
                        # 1. Try Dynamic Classification (Era-Aware)
                        classified = classify_dead_tracks(show_date, track_names[-5:])
                        
                        # Check if classification explicitly identified an encore
                        if classified.get("Encore") and classified["Encore"] != ["(No Encore Played)"]:
                            # Determine move count based on classified encore length
                            encore_len = len(classified["Encore"])
                            if encore_len == 1:
                                action = "MOVE_1"
                            elif encore_len == 2:
                                action = "MOVE_2"
                            
                    # 2. Fallback to Rules File if Classification was "Set_Closer" (SKIP) or inconclusive
                    # BUT, allow rules file to OVERRIDE "SKIP" -> "MOVE"? 
                    # If classification says "Set_Closer", we probably shouldn't move it unless user forced it.
                    # If classification detected an Encore, we definitely move it.
                    
                    if action == "SKIP":
                        # Check rules file
                        rule_action = rules_map.get(last_track_name, "SKIP")
                        if rule_action.startswith("MOVE"):
                            action = rule_action
                    
                    if action == "MOVE_1":
                        moved_track = last_set['t'].pop()
                        # Add to new Encore set
                        new_encore = {"n": "Encore", "t": [moved_track]}
                        sets.append(new_encore)
                        applied_count += 1
                        
                    elif action == "MOVE_2":
                        if len(last_set['t']) >= 2:
                            moved_track_2 = last_set['t'].pop()
                            moved_track_1 = last_set['t'].pop()
                            # Add to new Encore set (ordered 1 then 2)
                            new_encore = {"n": "Encore", "t": [moved_track_1, moved_track_2]}
                            sets.append(new_encore)
                            applied_count += 1
    
    print(f"Applied {applied_count} encore fixes.")
    return data
    
    print(f"Applied {applied_count} encore fixes.")
    return data

def report_messy_tracks(data):
    # Report Messy Track Names
    messy_tracks = []
    messy_pattern = re.compile(r'\d+d\d+t\d+', re.IGNORECASE)
    
    for show in data:
        show_date = show.get('date', 'Unknown')
        for source in show.get('sources', []):
            shnid = source.get('id', 'Unknown')
            for s in source.get('sets', []) + source.get('source_sets', []):
                 for t in s.get('t', []):
                     title = t.get('t', '')
                     if messy_pattern.search(title):
                         messy_tracks.append(f"- [{show_date}] Source {shnid}: {title}")

    if messy_tracks:
        with open('messy_track_names.md', 'w') as f:
            f.write("# Messy Track Names Report\n\n")
            f.write("Found the following tracks with 'd#t#' pattern:\n\n")
            f.write("\n".join(messy_tracks))
        print(f"Reported {len(messy_tracks)} messy track names to messy_track_names.md")
    else:
        print("No messy track names found.")

def remove_blacklisted_sources(data):
    """Removes specific SHNIDs requested by the user."""
    blacklist = ["71"] # String ID
    removed_count = 0
    for show in data:
        sources = show.get('sources', [])
        original_len = len(sources)
        show['sources'] = [s for s in sources if str(s.get('id', '')) not in blacklist]
        removed_count += original_len - len(show['sources'])
    
    if removed_count > 0:
        print(f"Removed {removed_count} blacklisted sources (Ids: {blacklist}).")
    return data

def audit_json(input_file, report_file, reference_file=None, output_file=None):
    print(f"Starting audit of {input_file}...")
    
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        print(f"FATAL: Could not read or parse JSON file: {e}")
        sys.exit(1)

    data = remove_blacklisted_sources(data)

    ref_data = None
    if reference_file:
        print(f"Loading reference file {reference_file}...")
        try:
            with open(reference_file, 'r', encoding='utf-8') as f:
                ref_data = json.load(f)
        except Exception as e:
            print(f"WARNING: Could not read reference file: {e}")

    if not isinstance(data, list):
        print("FATAL: Root element is not a list.")
        sys.exit(1)

    stats = {
        "total_shows": len(data),
        "total_sources": 0,
        "total_tracks": 0,
        "issues_found": 0,
        "duplicate_shnids": 0,
        "empty_sets": 0,
        "malformed_sources": 0,
        "suspicious_encores": 0,
        "single_track_set2": 0,
        "long_no_encore": 0,
        "us_blues_last_no_encore": 0,
        "us_blues_last_no_encore": 0,
        "omsn_last_no_encore": 0,
        "rain_last_no_encore": 0,
        "casey_jones_last_no_encore": 0,
        "shows_missing_l": 0,
        "missing_fields": defaultdict(int)
    }

    issues_log = []
    shows_missing_l_list = []
    corrections_log = []
    seen_shnids = {}

    for show in data:

        date = show.get('date', 'UNKNOWN_DATE')
        sources = show.get('sources', [])
        
        if not sources:
            stats["missing_fields"]["no_sources"] += 1
            issues_log.append({"msg": f"[{date}] Show has no sources.", "source": None})
            continue
            
        if 'l' not in show:
            stats["shows_missing_l"] += 1
            shows_missing_l_list.append(f"[{date}] {show.get('name', 'N/A')}")

        # Check against Known Corrections
        if date in KNOWN_VENUE_LOCATIONS:
            expected_venue, expected_location = KNOWN_VENUE_LOCATIONS[date]
            current_venue = show.get('name', '')
            current_location = show.get('l', '')
            
            # Apply corrections if mismatched
            updates = []
            if expected_venue and expected_venue != current_venue:
                show['name'] = expected_venue
                updates.append(f"Venue: '{current_venue}' -> '{expected_venue}'")
            
            if expected_location and expected_location != current_location:
                show['l'] = expected_location
                updates.append(f"Location: '{current_location}' -> '{expected_location}'")
            
            if updates:
                stats["issues_found"] += 1 
                # Log as applied correction
                corrections_log.append(f"[{date}] Applied Known Corrections: {'; '.join(updates)}")


        for source in sources:
            stats["total_sources"] += 1
            shnid = source.get('id')
            
            # Check ID
            if not shnid:
                 stats["missing_fields"]["source_id"] += 1
                 stats["malformed_sources"] += 1
                 issues_log.append({"msg": f"[{date}] Malformed source (missing ID).", "source": source})
                 continue
            
            # Check Duplicates
            if shnid in seen_shnids:
                stats["duplicate_shnids"] += 1
                issues_log.append({"msg": f"[{date}] Duplicate SHNID {shnid} (previously seen in {seen_shnids[shnid]})", "source": source})
            else:
                seen_shnids[shnid] = date

            # Check Sets
            sets = source.get('sets', [])
            if not sets:
                 if 'source_sets' in source:
                     sets = source['source_sets']
                 else:
                     stats["missing_fields"]["no_sets"] += 1
                     issues_log.append({"msg": f"[{date}] Source {shnid} has no sets.", "source": source})
                     continue
            
            has_set2 = False
            has_encore = False
            set2_tracks = 0
            total_source_tracks = 0
            
            issues_found_in_source = []

            for s in sets:
                set_name = s.get('n', 'Unknown')
                tracks = s.get('t', [])
                count = len(tracks)
                total_source_tracks += count
                stats["total_tracks"] += count

                if not tracks:
                    stats["empty_sets"] += 1
                    issues_found_in_source.append(f"Set '{set_name}' is empty.")
                
                # Check Track Fields
                for t in tracks:
                    if 't' not in t:
                        stats["missing_fields"]["track_title"] += 1
                    if 'u' not in t:
                        stats["missing_fields"]["track_filename"] += 1
                
                # Logic Checks
                if set_name == "Set 2":
                    has_set2 = True
                    set2_tracks = count
                
                if set_name == "Encore":
                    has_encore = True
                    if count >= 5:
                        stats["suspicious_encores"] += 1
                        issues_found_in_source.append(f"Suspiciously long Encore ({count} tracks).")

            if has_set2 and set2_tracks == 1:
                stats["single_track_set2"] += 1
                issues_found_in_source.append(f"Single track Set 2.")
            
            if total_source_tracks > 13 and not has_encore:
                 stats["long_no_encore"] += 1
                 issues_found_in_source.append(f"Long show ({total_source_tracks} tracks) with NO Encore.")
            
            # Check for specific closers not in Encore
            if sets:
                last_set = sets[-1]
                if last_set.get('n') != "Encore" and last_set.get('t'):
                    last_track = last_set['t'][-1]
                    lt_name_lower = last_track.get('t', '').lower()
                    
                    if "u.s. blues" in lt_name_lower or "us blues" in lt_name_lower:
                        stats["us_blues_last_no_encore"] += 1
                        issues_found_in_source.append("U.S. Blues is last track but NOT in Encore.")
                    
                    if "one more saturday night" in lt_name_lower:
                         stats["omsn_last_no_encore"] += 1
                         issues_found_in_source.append("One More Saturday Night is last track but NOT in Encore.")

                    if "rain" in lt_name_lower and lt_name_lower.endswith("rain"):
                         stats["rain_last_no_encore"] += 1
                         issues_found_in_source.append("Last track ends with 'Rain' but NOT in Encore.")

                    if "casey jones" in lt_name_lower:
                         stats["casey_jones_last_no_encore"] += 1
                         issues_found_in_source.append("Casey Jones is last track but NOT in Encore.")
            



            if issues_found_in_source:
                for issue in issues_found_in_source:
                    issues_log.append({"msg": f"[{date}] Source {shnid}: {issue}", "source": source})

    # Write Output JSON if requested
    if output_file:
         print(f"Writing optimized JSON to {output_file}...")
         try:
             with open(output_file, 'w', encoding='utf-8') as f:
                 # Use separators for minified output similar to fix_sets_api
                 json.dump(data, f, separators=(',', ':'))
             print("Done.")
         except Exception as e:
             print(f"FATAL: Could not write output file: {e}")



    # Write Report
    print(f"Audit complete. Found {len(issues_log)} issues.")
    print(f"Writing report to {report_file}...")
    
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write("# JSON Data Audit Report\n\n")
        
        f.write("## Summary Statistics\n\n")
        f.write("| Metric | Count |\n")
        f.write("| :--- | :--- |\n")
        f.write(f"| Total Shows | {stats['total_shows']} |\n")
        f.write(f"| Total Sources | {stats['total_sources']} |\n")
        f.write(f"| Total Tracks | {stats['total_tracks']} |\n")
        f.write(f"| **Issues Found** | **{len(issues_log)}** |\n")
        f.write("\n")
        
        if ref_data:
            f.write("## Comparison with Reference\n\n")
            input_map = get_source_map(data)
            ref_map = get_source_map(ref_data)
            
            new_ids = set(input_map.keys()) - set(ref_map.keys())
            missing_ids = set(ref_map.keys()) - set(input_map.keys())
            common_ids = set(input_map.keys()) & set(ref_map.keys())
            
            changed_structures = []
            for shnid in common_ids:
                if input_map[shnid] != ref_map[shnid]:
                    changed_structures.append(f"- {shnid}: `{ref_map[shnid]}` -> `{input_map[shnid]}`")
            
            f.write(f"- **New Sources:** {len(new_ids)}\n")
            f.write(f"- **Removed Sources:** {len(missing_ids)}\n")
            f.write(f"- **Sources with Set Structure Changes:** {len(changed_structures)}\n\n")
            
            if changed_structures:
                f.write("### Structure Changes (Sample)\n")
                for change in changed_structures[:50]:
                    f.write(f"{change}\n")
                if len(changed_structures) > 50:
                    f.write(f"... and {len(changed_structures) - 50} more.\n")
            f.write("\n")
        
        f.write("## Integrity Issues\n\n")
        f.write(f"- **Duplicate SHNIDs:** {stats['duplicate_shnids']}\n")
        f.write(f"- **Empty Sets:** {stats['empty_sets']}\n")
        f.write(f"- **Malformed Sources:** {stats['malformed_sources']}\n")
        f.write(f"- **Suspicious Encores (5+ tracks):** {stats['suspicious_encores']}\n")
        f.write(f"- **Single Track Set 2:** {stats['single_track_set2']}\n")
        f.write(f"- **Long Shows with NO Encore (>13 tracks):** {stats['long_no_encore']}\n")
        f.write(f"- **'U.S. Blues' last but NO Encore:** {stats['us_blues_last_no_encore']}\n")
        f.write(f"- **'One More Saturday Night' last but NO Encore:** {stats['omsn_last_no_encore']}\n")
        f.write(f"- **Ends with 'Rain' but NO Encore:** {stats['rain_last_no_encore']}\n")
        f.write(f"- **'Casey Jones' last but NO Encore:** {stats['casey_jones_last_no_encore']}\n")

        f.write(f"- **Shows missing Location 'l':** {stats['shows_missing_l']}\n")
        f.write("\n")
        
        if stats["missing_fields"]:
             f.write("### Missing Fields (Counts)\n")
             for field, count in stats["missing_fields"].items():
                 f.write(f"- {field}: {count}\n")
             f.write("\n")

        if shows_missing_l_list:
            f.write("## Shows Missing Location\n\n")
            for item in shows_missing_l_list:
                f.write(f"- {item}\n")
            f.write("\n")

        if corrections_log:
            f.write("## Applied Venue/Location Corrections\n\n")
            for item in corrections_log:
                f.write(f"- {item}\n")
            f.write("\n")

        f.write("## Issue Log\n\n")
        if issues_log:
            limit = 1000
            if len(issues_log) > limit:
                f.write(f"*(Displaying first {limit} of {len(issues_log)} issues)*\n\n")
            
            for i, item in enumerate(issues_log):
                if i >= limit: break
                
                msg = item['msg']
                source = item['source']
                
                f.write(f"### {i+1}. {msg}\n")
                if source:
                    desc = source.get('_d', 'N/A')
                    f.write(f"- **Source Path:** `{desc}`\n")
                    f.write(f"- **Archive URL:** https://archive.org/details/{desc}\n")
                    f.write("- **Tracks:**\n")
                    
                    sets = source.get('sets') or source.get('source_sets') or []
                    if sets:
                        for s in sets:
                            s_name = s.get('n', 'Set')
                            f.write(f"  - **{s_name}**\n")
                            for idx, t in enumerate(s.get('t', []), 1):
                                t_name = t.get('t', 'Unknown')
                                t_fn = t.get('u', '')
                                f.write(f"    {idx}. {t_name} `({t_fn})`\n")
                    else:
                        f.write("  *No tracks found property.*\n")
                
                f.write("\n---\n")

        else:
            f.write("No specific issues logged. Data structure appears healthy.\n")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Audit JSON data integrity.')
    parser.add_argument('--input', default='assets/data/output.optimized_src.json', help='Input JSON file')
    parser.add_argument('--report', default='audit_report.md', help='Output report file')
    parser.add_argument('--generate-encore-rules', help='Output JSON file for encore rules')
    parser.add_argument('--apply-encore-rules', help='Input JSON file with encore rules to apply')
    parser.add_argument('--output', help='Optional output JSON file to save corrections')
    args = parser.parse_args()
    
    if args.generate_encore_rules:
        with open(args.input, 'r') as f:
            data = json.load(f)
        data = remove_blacklisted_sources(data)
        rules = generate_encore_rules(data)
        with open(args.generate_encore_rules, 'w') as f:
            json.dump(rules, f, indent=2)
        print(f"Generated encore rules to {args.generate_encore_rules}")
        report_messy_tracks(data)
        
    elif args.apply_encore_rules and args.output:
        with open(args.input, 'r') as f:
            data = json.load(f)
        data = remove_blacklisted_sources(data)
        new_data = apply_encore_rules(data, args.apply_encore_rules)
        with open(args.output, 'w') as f:
            json.dump(new_data, f, separators=(',', ':'))
        print(f"Saved patched data to {args.output}")
        report_messy_tracks(new_data)
        
    else:
        audit_json(args.input, args.report, None, args.output)
        # Note: audit_json doesn't return data easily, so we might skip messy track report here or read file separately.
        # But wait, audit_json logic was just modified to NOT include messy tracks!
        # I extracted the logic out of audit_json.
        # So I need to read the data here to run report_messy_tracks, or pass it into audit_json.
        # Let's just read it quickly if needed, or better, let audit_json handle it?
        # Actually, let's just run it on the input file data for consistent reporting.
        with open(args.input, 'r') as f:
             data = json.load(f)
        report_messy_tracks(data)
