import json
import os

# Songs that almost always start Set 2
SET_2_OPENERS = {
    # The "Big Three"
    "Scarlet Begonias", "Playing In The Band", "China Cat Sunflower", 
    
    # The 80s/90s Standards
    "Iko Iko", "Shakedown Street", "Samson And Delilah", "Victim Or The Crime", 
    "Picasso Moon", "Box Of Rain", "Foolish Heart", "Mississippi Half-Step",
    "Eyes Of The World", "Man Smart (Woman Smarter)",
    
    # The Rare "Big" Openers
    "Help On The Way", "Bertha", "Sugar Magnolia", "Saint Of Circumstance"
}

# Songs that are almost exclusively encores
ENCORE_STAPLES = {
    "Johnny B. Goode", "U.S. Blues", "Brokedown Palace", "The Weight", 
    "Black Muddy River", "Knockin' On Heaven's Door", "Baby Blue", 
    "It's All Over Now, Baby Blue", "(It's All Over Now) Baby Blue",
    "One More Saturday Night", "Keep Your Day Job", "Werewolves Of London", 
    "Attics Of My Life", "Liberty", "I Fought The Law", "Rain", "The Mighty Quinn",
    "Quinn The Eskimo", "Lucy In The Sky With Diamonds", "Lucy In The Sky",
    "And We Bid You Goodnight", "We Bid You Good Night", "Bid You Goodnight",
    "I Gotta Serve Somebody"
}

ENCORE_MARKERS = {"Encore Break", "Crowd", "applause", "NFA Crowd Chant", "(encore)"}

# Songs that definitely shouldn't be in an encore (if found after a trigger, the trigger is false)
NON_ENCORE_SONGS = SET_2_OPENERS.union({
    "Drums", "Space", "Dark Star", "The Other One", "St. Stephen", "The Eleven", 
    "Cryptical Envelopment", "Turn On Your Lovelight", "Caution (Do Not Stop On Tracks)",
    "Feedback", "And It's Stoned Me"
})

# Songs that are almost exclusively Set 1 Closers (should not be at start of Set 2)
SET_1_CLOSERS = {
    "Don't Ease Me In", "Deal", "Might As Well", "The Promised Land", 
    "The Music Never Stopped", "Touch Of Grey"
}

def process_setlists(input_file, output_file):
    print(f"Reading from {input_file}...")
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"Error: Input file {input_file} not found.")
        return

    fixed_sets_count = 0
    extracted_encores_count = 0
    d2_tracks_in_set2_count = 0 # New counter for d2 filenames in Set 2
    moved_to_set1_count = 0 # New counter for Set 2 -> Set 1 moves
    
    # Store report data
    # Format: {'date': '...', 'id': '...', 'action': 'Split Sets'|'Extracted Encore', 'details': '...'}
    report_data = []

    for show in data:
        show_date = show.get('date', 'Unknown Date')
        
        # CONSTRAINT: Do not touch sets pre 1970
        try:
            year_part = show_date.split('-')[0]
            if year_part.isdigit() and int(year_part) < 1970:
                continue
        except Exception:
            pass

        for source in show.get('sources', []):
            source_id = source.get('id', 'Unknown ID')
            original_sets = source.get('sets', [])
            if not original_sets:
                continue

            processed_sets = []
            source_modified = False
            split_happened = False
            encore_extracted = False
            
            # Logic 3 (Pre-Processing): Fix existing Set 1 / Set 2 boundaries
            # Check if we have Set 1 and Set 2, and if Set 2 starts with a Set 1 Closer
            s1_index = next((i for i, s in enumerate(original_sets) if s.get('n') == "Set 1"), -1)
            s2_index = next((i for i, s in enumerate(original_sets) if s.get('n') == "Set 2"), -1)
            
            if s1_index != -1 and s2_index != -1 and s2_index > s1_index:
                s1 = original_sets[s1_index]
                s2 = original_sets[s2_index]
                s1_tracks = s1.get('t', [])
                s2_tracks = s2.get('t', [])
                
                moved_tracks = []
                while s2_tracks:
                    first_track = s2_tracks[0]
                    title = first_track.get('t', '')
                    
                    is_s1_closer = title in SET_1_CLOSERS
                    # Also check for "Tuning" if the NEXT track is a S1 closer? 
                    # For now, let's just move the closer itself.
                    # Actually, if we move a closer, we should probably move preceding tuning?
                    # Let's keep it simple: Only move the specific songs for now.
                    
                    if is_s1_closer:
                        moved_tracks.append(s2_tracks.pop(0))
                    else:
                        break
                
                if moved_tracks:
                    # s1_tracks.extend(moved_tracks) # DISABLED per user request: "usually it not good to move the track from set 2 to set 1"
                    # We just report it now.
                    
                    # Put them back for the sake of the script continuing correctly without altering data
                    s2_tracks = moved_tracks + s2_tracks 
                    
                    report_data.append({
                        'date': show_date,
                        'id': source_id,
                        'action': 'Potential Set 1 Closer in Set 2',
                        'details': f"Found {len(moved_tracks)} tracks at start of Set 2 that look like Set 1 Closers. Action Skipped. Tracks: {', '.join([t.get('t','') for t in moved_tracks])}",
                        'trigger': f"Set 1 Closer found in Set 2: '{moved_tracks[0].get('t','')}'",
                        'set_lists': [
                             {'name': 'Set 2 (Start)', 'tracks': [t.get('t', 'Unknown') for t in s2_tracks[:3]], 'start_idx': 1}
                        ]
                    })


            for set_obj in original_sets:
                tracks = set_obj.get('t', [])
                set_name = set_obj.get('n', '')
                
                # Logic 1: Split a single "Set 1" into "Set 1" and "Set 2"
                # CONSTRAINT: Only if Set 1 has MORE THAN 18 tracks (User request: "shows 18 or less tracks should not be split")
                if len(original_sets) == 1 and set_name == "Set 1" and len(tracks) > 18:
                    s1_tracks = []
                    s2_tracks = []
                    found_set2 = False
                    trigger_reason = "Unknown"
                    
                    for i, track in enumerate(tracks):
                        title = track.get('t', '')
                        
                        # 1. PRIORITY Check: Physical Disc 2 Start (d2t01)
                        # "make the split with the track that had d2t01 in it"
                        # CONSTRAINT: Must not be the very first track (i=0) or we carry over nothing to Set 1
                        url_lower = track.get('u', '').lower()
                        if not found_set2 and i > 0 and ("d2t01" in url_lower or "d2_01" in url_lower or "d2_t01" in url_lower or "d2t101" in url_lower or "d2t201" in url_lower):
                             found_set2 = True
                             trigger_reason = f"Disc 2 Start found: '{track.get('u', '')}'"

                             found_set2 = True
                             trigger_reason = f"Disc 2 Start found: '{track.get('u', '')}'"

                        # 2. Look-ahead: If this is tuning and the NEXT track is an opener, start Set 2 now
                        # DISABLED per user request: "i still see tracks list get split with a url thatdoes not have 'd2t201' in it"
                        # We are now strictly splitting ONLY on filename markers.
                        
                        # if not found_set2 and i > 3 and i < len(tracks) - 1:
                        #     next_title = tracks[i+1].get('t', '')
                        #     is_tuning = any(m.lower() in title.lower() for m in ["tuning", "crowd"])
                        #     
                        #     # Identify specific opener
                        #     matched_opener = next((opener for opener in SET_2_OPENERS if opener.lower() in next_title.lower()), None)
                        #     
                        #     if is_tuning and matched_opener:
                        #         found_set2 = True
                        #         trigger_reason = f"Tuning before Set 2 Opener: '{matched_opener}'"
                        
                        # 3. Standard check: Is the current track an opener?
                        # DISABLED per user request.
                        
                        # if not found_set2 and i > 3:
                        #     matched_opener = next((opener for opener in SET_2_OPENERS if opener.lower() in title.lower()), None)
                        #     if matched_opener:
                        #         found_set2 = True
                        #         trigger_reason = f"Set 2 Opener found: '{matched_opener}'"
                        
                        if found_set2:
                            s2_tracks.append(track)
                        else:
                            s1_tracks.append(track)
                    
                    if s2_tracks:
                        processed_sets.append({"n": "Set 1", "t": s1_tracks})
                        processed_sets.append({"n": "Set 2", "t": s2_tracks})
                        fixed_sets_count += 1
                        split_happened = True
                        
                        # Calculate original index for reporting
                        # s1_tracks has length len(s1_tracks), so the next track (start of s2) was at index len(s1_tracks) + 1 (1-based)
                        split_idx = len(s1_tracks) + 1
                        
                        s2_opener_track = s2_tracks[0]
                        s2_opener_url = s2_opener_track.get('u', 'No URL')
                        
                        preceding_info = ""
                        if "d2" in s2_opener_url.lower() and s1_tracks:
                            pre_track = s1_tracks[-1]
                            pre_url = pre_track.get('u', 'No URL')
                            preceding_info = f" [Preceding: `{pre_url}`]"

                        # Check for d2t01 specifically to verify alignment
                        d2t01_info = ""
                        # Search in s1_tracks + s2_tracks (the whole original set)
                        all_tracks_split = s1_tracks + s2_tracks
                        for idx, t in enumerate(all_tracks_split):
                            url = t.get('u', '')
                            if "d2t01" in url.lower() or "d2_01" in url.lower() or "d2_t01" in url.lower() or "d2t101" in url.lower() or "d2t201" in url.lower():
                                # Found distinct Disc 2 start
                                # idx is 0-based index in the combined list. 
                                # Track Number would be idx + 1.
                                d2t01_info = f" [**d2t01 found at Track {idx + 1}**: `{url}`]"
                                break

                        d2_hits = 0
                        for t in s2_tracks:
                            url = t.get('u', '')
                            if 'd2' in url.lower():
                                d2_hits += 1
                        d2_tracks_in_set2_count += d2_hits
                        
                        d2_note = f" (d2 files: {d2_hits}/{len(s2_tracks)})" if d2_hits > 0 else ""
                        
                        report_data.append({
                            'date': show_date,
                            'id': source_id,
                            'action': 'Split Single Set',
                            'details': f"Split into Set 1 ({len(s1_tracks)} tracks) and Set 2 ({len(s2_tracks)} tracks). Set 2 starts at **Track {split_idx}**: {s2_opener_track.get('t', 'Unknown')} (`{s2_opener_url}`){preceding_info}{d2t01_info}{d2_note}",
                            'trigger': trigger_reason,
                            'set_lists': [
                                {'name': 'Set 1', 'tracks': [t.get('t', 'Unknown') for t in s1_tracks], 'start_idx': 1},
                                {'name': 'Set 2', 'tracks': [t.get('t', 'Unknown') for t in s2_tracks], 'start_idx': split_idx}
                            ]
                        })
                    else:
                        processed_sets.append(set_obj)
                        
                        # REPORTING: Captured skipped split candidates (User request: "list sources not fixed , and why")
                        # We only report "interesting" skips (>= 12 tracks) to avoid reporting every tiny fragment.
                        if len(tracks) >= 12:
                            report_data.append({
                                'date': show_date,
                                'id': source_id,
                                'action': 'Skipped Split',
                                'details': f"Single 'Set 1' with {len(tracks)} tracks left as is.",
                                'trigger': "No Disc 2 marker (d2t01/d2t101/d2t201) found",
                                'set_lists': [] # No change to show
                            })

                else:
                    processed_sets.append(set_obj)
                    
                    # REPORTING: Captured skipped split candidates (User request: "list sources not fixed , and why")
                    # Check if it was a candidate (Single Set 1) that failed the length constraint
                    if len(original_sets) == 1 and set_name == "Set 1" and 12 <= len(tracks) <= 18:
                         report_data.append({
                            'date': show_date,
                            'id': source_id,
                            'action': 'Skipped Split',
                            'details': f"Single 'Set 1' with {len(tracks)} tracks left as is.",
                            'trigger': f"Too short to split (Track count {len(tracks)} <= 18)",
                            'set_lists': []
                        })

            # Logic 2: Extract Encore from the final set
            final_sets = []
            for i, set_obj in enumerate(processed_sets):
                tracks = set_obj.get('t', [])
                is_last_set = (i == len(processed_sets) - 1)
                
                # Only try to pull an encore if it's not already labeled as one
                # CONSTRAINT: If it was originally a single Set 1 with < 12 tracks, we shouldn't have reached here if we skipped adding it to processed_sets differently, 
                # but since we append unmodified set_obj in Logic 1, we need to check length here too if it's that minimal case.
                # However, the user said "if there is less than 12 tracks in the set 1 , don;t move or make a set 2 or encore".
                # If we have a single set that is short, we shouldn't extract encore either.
                
                should_check_encore = True
                
                # CONSTRAINT: "don't move track to encore if its not in set 2 or 3"
                # If the set name is "Set 1", do not extract encore.
                # (Note: If we successfully split Set 1 into Set 1/Set 2 earlier, this set_obj will be 'Set 2', so it will pass.)
                if set_obj.get('n') == 'Set 1':
                     should_check_encore = False
                
                # Previous constraint (redundant now but keeping logic clear):
                if len(processed_sets) == 1 and set_obj.get('n') == 'Set 1':
                     should_check_encore = False

                if is_last_set and "Encore" not in set_obj['n'] and should_check_encore:
                    main_music = []
                    encore_music = []
                    found_encore = False
                    trigger_reason = "Unknown"
                    
                    for j, track in enumerate(tracks):
                        title = track.get('t', '')
                        
                        if not found_encore:
                            # 1. Check for Look-ahead (Tuning/Crowd before a Trigger)
                            if j < len(tracks) - 1:
                                is_tuning_track = any(m.lower() in title.lower() for m in ["tuning", "crowd"])
                                if is_tuning_track:
                                    next_track = tracks[j+1]
                                    next_title = next_track.get('t', '')
                                    
                                    # Check if next track would be a trigger
                                    next_marker = next((m for m in ENCORE_MARKERS if m.lower() in next_title.lower()), None)
                                    next_is_staple = next_title in ENCORE_STAPLES and (j + 1) >= len(tracks) - 3
                                    
                                    if next_marker:
                                        found_encore = True
                                        trigger_reason = f"Tuning before Encore Marker: '{next_marker}'"
                                    elif next_is_staple:
                                        found_encore = True
                                        trigger_reason = f"Tuning before Encore Staple: '{next_title}'"

                            # 2. Check current track (Standard Trigger)
                            if not found_encore:
                                matched_marker = next((m for m in ENCORE_MARKERS if m.lower() in title.lower()), None)
                                is_marker = matched_marker is not None
                                
                                # Staples only count as encores if they are in the last 3 tracks
                                is_staple = title in ENCORE_STAPLES and j >= len(tracks) - 3

                                # Add a specific check in your loop for a cappella/vocal closers
                                if "bid you good night" in title.lower():
                                    is_staple = True

                                # Specific check for Baby Blue
                                if "baby blue" in title.lower():
                                    year_int = 0
                                    try:
                                        year_int = int(show_date.split('-')[0])
                                    except:
                                        pass
                                    
                                    if year_int >= 1980 or j >= len(tracks) - 2:
                                        is_staple = True
                                
                                # Specific check for I Fought The Law (Always Trigger)
                                if "i fought the law" in title.lower():
                                    found_encore = True
                                    trigger_reason = f"Encore Staple: '{title}'"
                                
                                # Specific check for Sugar Magnolia (Only if Last Track)
                                elif "sugar magnolia" in title.lower() and j == len(tracks) - 1:
                                    found_encore = True
                                    trigger_reason = f"Encore Staple (Last Track): '{title}'"

                                # CONSTRAINT: Don't start encore at the very first track (j=0)
                                if (is_marker or is_staple) and j > 0 and not found_encore:
                                    # CONSTRAINT: "do not move to encore if next track is not going to be in encore"
                                    # If the next track is a known "Non-Encore" song, correct this false positive.
                                    next_is_invalid = False
                                    if j < len(tracks) - 1:
                                        next_title_ck = tracks[j+1].get('t', '')
                                        # Strict check against NON_ENCORE_SONGS
                                        if next_title_ck in NON_ENCORE_SONGS:
                                            next_is_invalid = True
                                    
                                    if not next_is_invalid:
                                        found_encore = True
                                        if is_marker:
                                            trigger_reason = f"Encore Marker: '{matched_marker}'"
                                        elif is_staple:
                                            trigger_reason = f"Encore Staple Song: '{title}'"
                        
                        if found_encore:
                            encore_music.append(track)
                        else:
                            main_music.append(track)
                    
                    if encore_music:
                        set_obj['t'] = main_music
                        final_sets.append(set_obj)
                        final_sets.append({"n": "Encore", "t": encore_music})
                        extracted_encores_count += 1
                        
                        # Calculate start index of encore
                        encore_start_idx = len(main_music) + 1
                        
                        report_data.append({
                            'date': show_date,
                            'id': source_id,
                            'action': 'Extracted Encore',
                            'details': f"Extracted {len(encore_music)} tracks as Encore from '{set_obj['n']}'. Encore starts at **Track {encore_start_idx}**: {encore_music[0].get('t', 'Unknown')}",
                            'trigger': trigger_reason,
                            'set_lists': [
                                {'name': 'Encore', 'tracks': [t.get('t', 'Unknown') for t in encore_music], 'start_idx': encore_start_idx}
                            ]
                        })
                    else:
                        final_sets.append(set_obj)
                else:
                    final_sets.append(set_obj)

            source['sets'] = final_sets

    print(f"Saving to {output_file}...")
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, separators=(',', ':'))
        
    # Generate Report
    report_filename = 'set_structure_fix_report_v2.md'
    print(f"Generating report to {report_filename}...")
    
    skipped_count = len([d for d in report_data if d['action'] == 'Skipped Split'])

    with open(report_filename, 'w', encoding='utf-8') as f:
        f.write("# Set Structure Fix Report (v2)\n\n")
        f.write(f"- **Input File**: `{input_file}`\n")
        f.write(f"- **Output File**: `{output_file}`\n")
        f.write(f"- **Total Split Sets**: {fixed_sets_count}\n")
        f.write(f"- **Total Skipped Splits**: {skipped_count}\n")
        f.write(f"- **Total Extracted Encores**: {extracted_encores_count}\n")
        f.write(f"- **Total Tracks in New 'Set 2' with 'd2' in Filename:** {d2_tracks_in_set2_count}\n\n")
        f.write("---\n\n")
        
        # Group by date for cleaner reading
        current_date = None
        for item in sorted(report_data, key=lambda x: (x['date'], x['id'])):
            if item['date'] != current_date:
                if current_date is not None:
                     f.write("\n")
                f.write(f"### {item['date']}\n")
                current_date = item['date']
            
            if "Split" in item['action'] and "Skipped" not in item['action']:
                action_icon = "✂️"
            elif "Skipped" in item['action']:
                action_icon = "🛑"
            elif "Potential" in item['action']:
                action_icon = "⚠️"
            else:
                action_icon = "🎸"
            
            # Simplify details for readability
            details = item['details'].replace("Extracted ", "").replace("Split into ", "").replace("Moved ", "")
            trigger = item.get('trigger', 'Unknown')
            
            f.write(f"- {action_icon} **{item['action']}** [Source `{item['id']}`]: {details}\n")
            f.write(f"    - **Trigger**: {trigger}\n")
            f.write(f"    - *To exclude next run, add the trigger text (e.g. song name) to the exclusion list in the script.*\n")
            
            if 'set_lists' in item:
                for set_data in item['set_lists']:
                    f.write(f"    - **{set_data['name']}**:\n")
                    start_num = set_data.get('start_idx', 1)
                    for idx, track_name in enumerate(set_data['tracks']):
                         f.write(f"        {start_num + idx}. {track_name}\n")
            f.write("\n")

    print(f"Process complete.")
    print(f"  - Split single 'Set 1' shows: {fixed_sets_count}")
    print(f"  - Extracted Encores: {extracted_encores_count}")
    print(f"  - d2 tracks in Set 2: {d2_tracks_in_set2_count}")

# Execution
if __name__ == "__main__":
    input_path = 'assets/data/output.cleaned_trailing.json'
    output_path = 'assets/data/output.cleaned_trailing_set_fix1.json'
    process_setlists(input_path, output_path)
