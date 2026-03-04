import json
import urllib.request
import urllib.parse
import urllib.error
import time
import sys
import os

# Provided API Key and MBID
API_KEY = "0m8rBqaV2IQj4jUOozuCPf2o1RC5K8hB_tzU"
GD_MBID = "6faa7ca7-0d99-4a5e-b033-3b0d601f057d"

INPUT_FILE = "assets/data/output.optimized_src.json"
REPORT_FILE = "api_verification_report.md"

def get_official_setlist(date_str):
    """
    Fetches the setlist from setlist.fm.
    date_str is expected to be YYYY-MM-DD from the local JSON.
    Setlist.fm expects DD-MM-YYYY.
    """
    try:
        parts = date_str.split('-')
        if len(parts) != 3:
            return None
        formatted_date = f"{parts[2]}-{parts[1]}-{parts[0]}"
    except:
        return None
    
    base_url = "https://api.setlist.fm/rest/1.0/search/setlists"
    # Using artistName is often safer if MBIDs are tricky/variable
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
                time.sleep(1.2) # Rate limit is roughly 2/sec, but let's be safe
                
                if response.status == 200:
                    data = json.loads(response.read().decode('utf-8'))
                    if "setlist" in data and len(data["setlist"]) > 0:
                        return data["setlist"][0]
                    else:
                        return None # Empty list = not found
                
        except urllib.error.HTTPError as e:
            if e.code == 429:
                print(f"Rate limited (429) for {formatted_date}. Retrying in 5s...")
                time.sleep(5)
                continue
            elif e.code == 404:
                # 404 on search usually means "No matches found"
                # print(f"No setlist found (404) for {formatted_date}")
                return None
            else:
                print(f"Request failed for {formatted_date}: {e}")
                return None
        except Exception as e:
            print(f"Request failed for {formatted_date}: {e}")
            return None
        
    return None

def normalize_track_name(name):
    return str(name).lower().replace('.', '').replace(' ', '')

def main():
    if not os.path.exists(INPUT_FILE):
        print(f"Error: {INPUT_FILE} not found.")
        return

    print(f"Reading {INPUT_FILE}...")
    with open(INPUT_FILE, 'r') as f:
        data = json.load(f)

    # 1. Identify Candidate Shows From Local Data
    # We look for shows where the last two tracks involve US Blues and OMSN
    candidates = set()
    
    print("Scanning local data for candidate shows (ending with US Blues/OMSN)...")
    for show in data:
        show_date = show.get('date')
        if not show_date:
            continue
            
        sources = show.get('sources', [])
        if not sources:
            continue
            
        # Check first source to determine show structure signature
        # We assume all sources for a show have roughly same songs, 
        # checking one is sufficient for identifying the show as a candidate.
        source = sources[0]
        sets = source.get('sets', [])
        
        # Flatten simple tracklist
        all_tracks = []
        for s in sets:
            for t in s.get('t', []):
                 all_tracks.append(t.get('t', ''))
        
        if len(all_tracks) < 2:
            continue
            
        last_track = all_tracks[-1].lower()
        second_last = all_tracks[-2].lower()
        
        t1_us_blues = "u.s. blues" in last_track or "us blues" in last_track
        t1_omsn = "one more saturday night" in last_track
        
        t2_us_blues = "u.s. blues" in second_last or "us blues" in second_last
        t2_omsn = "one more saturday night" in second_last
        
        # Check for either order at the end
        if (t1_us_blues and t2_omsn) or (t1_omsn and t2_us_blues):
            candidates.add(show_date)

    sorted_dates = sorted(list(candidates))
    print(f"Found {len(sorted_dates)} candidates.")

    # 2. Verify with API
    report_lines = []
    report_lines.append("# Setlist.fm API Verification Report")
    report_lines.append(f"**Target Pattern**: Last two tracks are 'U.S. Blues' and 'One More Saturday Night' (Any Order)")
    report_lines.append(f"**Candidates Found in Local Data**: {len(sorted_dates)}")
    report_lines.append("")
    
    for date in sorted_dates:
        print(f"Verifying {date}...")
        official = get_official_setlist(date)
        
        report_lines.append(f"## Show Date: {date}")
        
        if not official:
            report_lines.append("❌ **Error**: Setlist not found on setlist.fm (or API error).")
            report_lines.append("\n---\n")
            continue
            
        # Parse Official Data
        venue = official.get("venue", {}).get("name", "Unknown Venue")
        report_lines.append(f"**Venue**: {venue}")
        
        sets_data = official.get("sets", {}).get("set", [])
        
        encore_tracks = []
        sets_structure = []
        
        for s in sets_data:
            songs = [song.get("name") for song in s.get("song", [])]
            if s.get("encore"):
                encore_tracks.extend(songs)
                sets_structure.append(f"Encore: {', '.join(songs)}")
            else:
                set_num = s.get("number", "")
                sets_structure.append(f"Set {set_num}: {', '.join(songs)}")
        
        # report_lines.append("\n**Official Setlist Structure:**")
        # for line in sets_structure:
        #     report_lines.append(f"- {line}")
            
        # Validation Logic
        # Check if both target songs are in the encore list
        e_str = " ".join(normalize_track_name(x) for x in encore_tracks)
        
        # Normalized checks
        has_us_blues_enc = "usblues" in e_str
        has_omsn_enc = "onemoresaturdaynight" in e_str
        
        status_icon = "❌"
        status_msg = "Incorrect - One or both are NOT in Encore."
        
        if has_us_blues_enc and has_omsn_enc:
            status_icon = "✅"
            status_msg = "Correct - Both are in the Encore."
        elif has_us_blues_enc or has_omsn_enc:
            status_icon = "⚠️"
            status_msg = "Partial - Only one is in the Encore."
            
        report_lines.append(f"\n{status_icon} **Status**: {status_msg}")
        report_lines.append(f"\n**Encore Tracks (Setlist.fm)**: {', '.join(encore_tracks) if encore_tracks else 'None'}")
        report_lines.append("\n---\n")

    # 3. Save Report
    with open(REPORT_FILE, 'w') as f:
        f.write("\n".join(report_lines))
    
    print(f"Done. Report saved to {REPORT_FILE}")

if __name__ == "__main__":
    main()
