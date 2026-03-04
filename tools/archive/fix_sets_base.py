import json
import os
import re
import requests # Assuming requests is available for fetching
from bs4 import BeautifulSoup # Assuming BeautifulSoup is available for parsing
from datetime import datetime, timedelta

# --- Configuration ---
CACHE_DIR = "jerrybase_cache"
# Ensure the cache directory exists
os.makedirs(CACHE_DIR, exist_ok=True)

# --- Helper Functions ---
def process_jerrybase_page(date_str):
    """
    Fetches data from jerrybase.com for a given date, extracts setlist info,
    and saves it to a cache file. Skips if data cannot be found or if there's an error.
    """
    try:
        year = int(date_str.split('-')[0])
        month = int(date_str.split('-')[1])
        day = int(date_str.split('-')[2])
        
        # Construct the URL for jerrybase.com events page
        url = f"https://jerrybase.com/events/{year}{month:02d}{day:02d}"
        print(f"Processing: {url}")
        
        # Fetch page content
        response = requests.get(url, timeout=10)
        response.raise_for_status() # Raise an exception for bad status codes (4xx or 5xx)

        soup = BeautifulSoup(response.text, 'html.parser')

        # --- Data Extraction Logic ---
        # NOTE: The following selectors are placeholders. They would need to be
        # verified and updated by inspecting the actual HTML structure of jerrybase.com.

        sets_data = {}
        sets_found = False

        # Example extraction for Set 1, Set 2, Set 3, Encore
        # This part is highly dependent on the website's HTML structure.
        set_elements = soup.find_all('div', class_='set-list') # Example selector for set lists

        if set_elements:
            sets_found = True
            set_counter = 1
            for i, set_element in enumerate(set_elements):
                set_name = f"Set {set_counter}" # Default name
                
                # Heuristic to identify Encore set based on common text patterns
                set_header = set_element.find('h3') # Example: assume set name is in an h3 tag
                if set_header and "Encore" in set_header.text:
                    set_name = "Encore"
                elif set_header and "Set" in set_header.text:
                    set_name = set_header.text.strip() # Use actual set name if available
                elif not set_header: # If no header, use default naming
                    set_name = f"Set {set_counter}"

                # If it's not an encore, increment set counter for next set
                if set_name != "Encore":
                    set_counter += 1
                
                songs = []
                # Example selector for song titles within a set
                song_elements = set_element.find_all('a', class_='song-title') 
                for song_element in song_elements:
                    songs.append(song_element.text.strip())
                
                sets_data[set_name] = songs

        if not sets_found:
            print(f"Skipping {url} - No set data found or extraction failed.")
            return None # Skip pages where set data cannot be found

        # Save to cache
        cache_filename = f"{date_str}_jerrybase.txt"
        cache_path = os.path.join(CACHE_DIR, cache_filename)
        with open(cache_path, 'w', encoding='utf-8') as f:
            f.write(f"Show Date: {date_str}\n")
            f.write(f"URL: {url}\n\n")
            if sets_data:
                for set_name, song_list in sets_data.items():
                    f.write(f"**{set_name}**\n")
                    for i, song in enumerate(song_list):
                        f.write(f"  {i+1}. {song}\n")
                    f.write("\n")
            else:
                f.write("No sets found.\n")
        
        print(f"Saved data for {date_str} to {cache_path}")
        return True # Indicate success

    except requests.exceptions.RequestException as e:
        print(f"Error fetching {url}: {e}")
        return None # Skip on fetch error
    except Exception as e:
        print(f"Error processing {url}: {e}")
        return None # Skip on other processing errors

# --- Main script logic ---
def main():
    start_date = datetime(1969, 1, 1)
    end_date = datetime(1969, 12, 31)
    
    current_date = start_date
    while current_date <= end_date:
        date_str = current_date.strftime("%Y-%m-%d")
        
        # Attempt to process the page
        process_jerrybase_page(date_str)
        
        # Move to the next day
        current_date += timedelta(days=1)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Fix set placement and missing locations against API with caching.')
    parser.add_argument('--input', default='assets/data/output.optimized_src.json', help='Input JSON file')
    parser.add_argument('--output', default='assets/data/output.optimized_src_api.json', help='Output JSON file')
    parser.add_argument('--report', default='fix_report.md', help='Output report file')
    parser.add_argument('--long-encore-report', default='long_encore_report.md', help='Output report file for encores with 3 or less tracks')
    parser.add_argument('--very-long-encore-report', default='very_long_encore_report.md', help='Output report file for encores with 4 or more tracks')
    parser.add_argument('--detailed-report', default='detailed_report.md', help='Output report file for detailed comparison')
    parser.add_argument('--unlabeled-encores-report', default='unlabeled_encores_report.md', help='Output report file for potential unlabeled encores')
    parser.add_argument('--limit', type=int, help='Limit number of dates to process')
    parser.add_argument('--apply-changes', action='store_true', help='Apply setlist changes to the output file. Default is a mock run.')
    parser.add_argument('--online', action='store_true', help='Enable API calls to Setlist.fm (default is Offline)')
    args = parser.parse_args()
    fix_sets(args.input, args.output, args.report, args.long_encore_report, args.very_long_encore_report, args.detailed_report, args.unlabeled_encores_report, args.limit, args.apply_changes, args.online)