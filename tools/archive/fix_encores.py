import json
import os
import urllib.request
import urllib.parse
import urllib.error
import time
import argparse

# API Configuration
API_KEY = "0m8rBqaV2IQj4jUOozuCPf2o1RC5K8hB_tzU" # Using provided key
API_CACHE = {} # Simple in-memory cache for show dates

def normalize_track_name(name):
    return str(name).lower().replace('.', '').replace(' ', '')

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
                time.sleep(1.1) 
                
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

def check_official_placement(date_str, track_name):
    """
    Returns 'Encore', 'Set', or None based on official data.
    """
    official = get_official_setlist(date_str)
    if not official:
        return None
    
    sets_data = official.get("sets", {}).get("set", [])
    norm_name = normalize_track_name(track_name)
    
    for s in sets_data:
        songs = [normalize_track_name(song.get("name")) for song in s.get("song", [])]
        if norm_name in songs:
            if s.get("encore"):
                return 'Encore'
            else:
                return 'Set' # Belongs in a main set
                
    return None

def fix_encores_and_closers(input_file, output_file, report_file, use_api=True):
    print(f"Reading from {input_file}...")
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"Error: Input file {input_file} not found.")
        return

    actions_log = []

    satisfaction_count = 0
    omsn_moved_count = 0
    omsn_single_encore_count = 0
    us_blues_before_omsn_count = 0
    us_blues_after_omsn_count = 0
    us_blues_before_omsn_list = []
    omsn_before_us_blues_list = []
    
    set2_us_blues_omsn_count = 0
    set2_us_blues_omsn_list = []
    set3_us_blues_omsn_count = 0
    set3_us_blues_omsn_list = []

    # New lists for end-of-show patterns (last 2 tracks of the entire show)
    end_us_blues_val_omsn_list = []
    end_omsn_val_us_blues_list = []

    api_logs = set()

    for show in data:
        show_date = show.get('date', 'Unknown Date')
        venue = show.get('venue', 'Unknown Venue')
        
        for source in show.get('sources', []):
            source_id = source.get('id', 'Unknown ID')
            sets = source.get('sets', [])
            
            # ... (Pass 1 omitted for brevity in instruction, assume context is correct) ...

            # --- Pass 2: Fix One More Saturday Night (Encore -> Last Non-Encore Set) ---
            
            encore_index = -1
            last_non_encore_index = -1
            
            for i, set_obj in enumerate(sets):
                name = set_obj.get('n', '').lower()
                if "encore" in name:
                    encore_index = i
                else:
                    last_non_encore_index = i
            # ...
            if encore_index != -1 and last_non_encore_index != -1:
                encore_set = sets[encore_index]
                encore_tracks = encore_set.get('t', [])
                
                omsn_idx = -1
                us_blues_idx = -1
                
                for i, track in enumerate(encore_tracks):
                    t_title = track.get('t', '').lower()
                    if "one more saturday night" in t_title:
                        omsn_idx = i
                    elif "u.s. blues" in t_title or "us blues" in t_title:
                        us_blues_idx = i

                omsn_track_to_move = None
                move_reason = ""
                
                # Check for US Blues -> OMSN pair
                if omsn_idx != -1 and us_blues_idx != -1:
                    if us_blues_idx == omsn_idx - 1:
                        us_blues_before_omsn_count += 1
                        us_blues_before_omsn_list.append(f"{show_date} [{source_id}]")
                        
                        # API CHECK for OMSN in this specific pair context
                        should_move_pair_omsn = True # Default to User Request (Heuristic)
                        
                        if use_api:
                            print(f"  [API] Verifying {show_date} for US Blues -> OMSN pair...", flush=True)
                            placement = check_official_placement(show_date, "One More Saturday Night")
                            if placement:
                                api_logs.add(f"- **{show_date}**: API verified 'One More Saturday Night' is in **{placement}**.")

                            if placement == 'Encore':
                                should_move_pair_omsn = False
                        
                        if should_move_pair_omsn:
                            # User Request: Move OMSN to highest set (not both)
                            # So we move OMSN, leaving US Blues in Encore
                            omsn_track_to_move = encore_tracks.pop(omsn_idx)
                            move_reason = " (Follows US Blues)"
                        
                    elif us_blues_idx > omsn_idx:
                        us_blues_after_omsn_count += 1
                        omsn_before_us_blues_list.append(f"{show_date} [{source_id}]")

                # Standard check: OMSN at start of multi-track encore
                if not omsn_track_to_move and omsn_idx == 0:
                    track_obj = encore_tracks[0]
                    t_title = track_obj.get('t', '').lower()
                    
                    if "one more saturday night" in t_title:
                        
                        should_move = False
                        reason = ""
                        
                        # API CHECK
                        api_decision = None
                        if use_api:
                             print(f"  [API] Verifying {show_date} for standard OMSN check...", flush=True)
                             placement = check_official_placement(show_date, "One More Saturday Night")
                             if placement:
                                 api_logs.add(f"- **{show_date}**: API verified 'One More Saturday Night' is in **{placement}**.")

                             if placement == 'Encore':
                                 api_decision = 'KEEP'
                             elif placement == 'Set':
                                 api_decision = 'MOVE'
                        
                        if api_decision == 'KEEP':
                            should_move = False
                        elif api_decision == 'MOVE':
                            should_move = True
                            move_reason = " (API Confirmed)"
                        else:
                            # FALLBACK HEURISTIC
                            if len(encore_tracks) == 1:
                                omsn_single_encore_count += 1
                                should_move = False
                            else:
                                should_move = True
                                move_reason = "" # Heuristic
                        
                        if should_move:
                             omsn_track_to_move = encore_tracks.pop(0)

                if omsn_track_to_move:
                    target_set_name = sets[last_non_encore_index].get('n', 'Unknown Set')
                    sets[last_non_encore_index]['t'].append(omsn_track_to_move)
                    omsn_moved_count += 1
                    actions_log.append({
                        'date': show_date,
                        'id': source_id,
                        'action': 'Move One More Saturday Night',
                        'detail': f"Moved 'One More Saturday Night' from Encore to {target_set_name}{move_reason}.",
                        'track': omsn_track_to_move.get('t', '')
                    })

                if not encore_tracks:
                    sets.pop(encore_index)
            
            # --- Check Set 2 and Set 3 for "US Blues -> OMSN" Pattern ---
            for s_idx, s in enumerate(sets):
                s_name = s.get('n', '').lower()
                s_tracks = s.get('t', [])
                
                check_set = None
                if "set 2" in s_name or "set ii" in s_name:
                    check_set = 'Set 2'
                elif "set 3" in s_name or "set iii" in s_name:
                    check_set = 'Set 3'
                
                if check_set:
                    # Look for US Blues -> OMSN sequence
                    for i in range(len(s_tracks) - 1):
                        curr_track = s_tracks[i].get('t', '').lower()
                        next_track = s_tracks[i+1].get('t', '').lower()
                        
                        if ("u.s. blues" in curr_track or "us blues" in curr_track) and \
                           ("one more saturday night" in next_track):
                               if check_set == 'Set 2':
                                   set2_us_blues_omsn_count += 1
                                   set2_us_blues_omsn_list.append(f"{show_date} [{source_id}]")
                               elif check_set == 'Set 3':
                                   set3_us_blues_omsn_count += 1
                                   set3_us_blues_omsn_list.append(f"{show_date} [{source_id}]")
            
            # --- End-of-Show Check (Flattened) ---
            all_tracks = []
            for s in sets:
                all_tracks.extend(s.get('t', []))
            
            if len(all_tracks) >= 2:
                last_track = all_tracks[-1].get('t', '').lower()
                second_last_track = all_tracks[-2].get('t', '').lower()
                
                # Check for US Blues -> OMSN
                if ("u.s. blues" in second_last_track or "us blues" in second_last_track) and \
                   ("one more saturday night" in last_track):
                    end_us_blues_val_omsn_list.append(f"{show_date} [{source_id}]")
                    
                # Check for OMSN -> US Blues
                elif ("one more saturday night" in second_last_track) and \
                     ("u.s. blues" in last_track or "us blues" in last_track):
                    end_omsn_val_us_blues_list.append(f"{show_date} [{source_id}]")

    # Save Output
    print(f"Saving modified data to {output_file}...")
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, separators=(',', ':'))

    # Generate Report
    print(f"Performed {satisfaction_count} Satisfaction moves.")
    print(f"Performed {omsn_moved_count} One More Saturday Night moves.")
    print(f"OMSN Single Encore Count (Not Moved): {omsn_single_encore_count}")
    print(f"US Blues before OMSN in Encore: {us_blues_before_omsn_count}")
    print(f"US Blues after OMSN in Encore: {us_blues_after_omsn_count}")
    print(f"Set 2: US Blues -> OMSN: {set2_us_blues_omsn_count}")
    print(f"Set 3: US Blues -> OMSN: {set3_us_blues_omsn_count}")
    print(f"End of Show (Any Set): US Blues -> OMSN: {len(end_us_blues_val_omsn_list)}")
    print(f"End of Show (Any Set): OMSN -> US Blues: {len(end_omsn_val_us_blues_list)}")

    print(f"Generating report to {report_file}...")
    
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write("# Encore Structure Fix Report\n\n")
        f.write(f"- **Input File**: `{input_file}`\n")
        f.write(f"- **Output File**: `{output_file}`\n")
        f.write(f"- **Satisfaction Moves**: {satisfaction_count}\n")
        f.write(f"- **One More Saturday Night Moves**: {omsn_moved_count}\n")
        f.write(f"- **One More Saturday Night (Single Encore - Not Moved)**: {omsn_single_encore_count}\n")
        f.write(f"- **US Blues before OMSN (Encore Only)**: {us_blues_before_omsn_count}\n")
        f.write(f"- **US Blues after OMSN (Encore Only)**: {us_blues_after_omsn_count}\n")
        f.write(f"- **Set 2: US Blues -> OMSN**: {set2_us_blues_omsn_count}\n")
        f.write(f"- **Set 3: US Blues -> OMSN**: {set3_us_blues_omsn_count}\n")
        f.write(f"- **End of Show: US Blues -> OMSN**: {len(end_us_blues_val_omsn_list)}\n")
        f.write(f"- **End of Show: OMSN -> US Blues**: {len(end_omsn_val_us_blues_list)}\n")
        f.write("---\n\n")

        # Easy Copy-Paste Section
        if us_blues_before_omsn_list:
            f.write("### Easy Verification List (US Blues -> OMSN in Encore)\n")
            # Extract just dates for cleaner list, or keep ID? User just said "paste into chat". 
            # Compact format: Date [ID], Date [ID]...
            f.write("`" + ", ".join([x.split(' [')[0] for x in us_blues_before_omsn_list]) + "`\n\n")
            f.write("---\n\n")

        if us_blues_before_omsn_list:
             f.write("### Shows with US Blues Immediately Before OMSN in Encore (Detailed)\n")
             for item in us_blues_before_omsn_list:
                 f.write(f"- {item}\n")
             f.write("\n---\n\n")

        # if omsn_before_us_blues_list:
        #      f.write("### Shows with OMSN before US Blues in Encore (Detailed)\n")
        #      for item in omsn_before_us_blues_list:
        #          f.write(f"- {item}\n")
        #      f.write("\n---\n\n")
             
        if end_us_blues_val_omsn_list:
             f.write("### End of Show: US Blues -> OMSN (Any Set)\n")
             for item in end_us_blues_val_omsn_list:
                 f.write(f"- {item}\n")
             f.write("\n---\n\n")
             
        if end_omsn_val_us_blues_list:
             f.write("### End of Show: OMSN -> US Blues (Any Set)\n")
             for item in end_omsn_val_us_blues_list:
                 f.write(f"- {item}\n")
             f.write("\n---\n\n")

        if api_logs:
            f.write("### API Verification Activity\n")
            sorted_api_logs = sorted(list(api_logs))
            for log in sorted_api_logs:
                f.write(f"{log}\n")
            f.write("\n---\n\n")

        if not actions_log:
            f.write("No actions taken.\n")
        else:
            # Sort by date for all
            actions_log.sort(key=lambda x: (x['date'], x['id']))
            
            # Group by action type
            omsn_moves = [x for x in actions_log if x['action'] == 'Move One More Saturday Night']
            satisfaction_moves = [x for x in actions_log if x['action'] == 'Move Satisfaction']
            
            if omsn_moves:
                f.write("### One More Saturday Night Moves\n")
                for item in omsn_moves:
                    f.write(f"- **{item['date']}** [{item['id']}] {item['detail']} (`{item['track']}`)\n")
                f.write("\n")
                
            if satisfaction_moves:
                f.write("### Satisfaction Moves\n")
                for item in satisfaction_moves:
                     f.write(f"- **{item['date']}** [{item['id']}] {item['detail']} (`{item['track']}`)\n")
                f.write("\n")

    print("Done.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Fix encore structure in show data.')
    parser.add_argument('--input', default='assets/data/output.optimized_src.json', help='Input JSON file')
    parser.add_argument('--output', default='assets/data/output.optimized_src_encore_fix.json', help='Output JSON file')
    parser.add_argument('--report', default='fix_encores_report.md', help='Report Markdown file')
    parser.add_argument('--no-api', action='store_true', help='Disable Setlist.fm API verification')
    
    args = parser.parse_args()
    
    fix_encores_and_closers(args.input, args.output, args.report, use_api=not args.no_api)

    print("Done.")

