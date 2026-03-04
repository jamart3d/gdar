import json
import re

def clean_tracks():
    input_file = 'assets/data/output.optimized_src.json'
    output_file = 'assets/data/output.optimized_srcFixed.json'

    try:
        print(f"Loading {input_file}...")
        with open(input_file, 'r') as f:
            data = json.load(f)

        count = 0
        cleaned_count = 0
        
        # Function to clean title
        def clean_title(title):
            # Regex to remove "&gt;" and everything after it
            # pattern: &gt; followed by anything (.*)
            # We also strip trailing whitespace resulting from the cut
            new_title = re.sub(r'&gt;.*', '', title).strip()
            return new_title

        print("Cleaning track names...")
        for show in data:
            for source in show.get('sources', []):
                for track in source.get('tracks', []):
                    # Check both 't' (short) and 'title' (long) keys just in case
                    if 't' in track:
                        original = track['t']
                        if '&gt;' in original:
                            count += 1
                            cleaned = clean_title(original)
                            if cleaned != original:
                                track['t'] = cleaned
                                cleaned_count += 1
                                # Print first few examples
                                if cleaned_count <= 5:
                                    print(f"Fixed: '{original}' -> '{cleaned}'")
                    
                    if 'title' in track: # In case some use full key
                        original = track['title']
                        if '&gt;' in original:
                            count += 1
                            cleaned = clean_title(original)
                            if cleaned != original:
                                track['title'] = cleaned
                                cleaned_count += 1

        print(f"Total tracks found with '&gt;': {count}")
        print(f"Total tracks updated: {cleaned_count}")

        print(f"Saving to {output_file}...")
        with open(output_file, 'w') as f:
            json.dump(data, f, separators=(',', ':')) # Minified output to match source style? Or default?
            # User didn't specify format, but usually these are minified. 
            # I'll use default dump but without spaces for compactness if the original was compact.
            # Original was likely compact.

        print("Done.")

    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    clean_tracks()
