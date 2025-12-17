import json

def inspect_tracks():
    try:
        with open('assets/data/output.optimized_src.json', 'r') as f:
            data = json.load(f)
        
        count = 0
        print("Examples of tracks with '&gt;':")
        for show in data:
            for source in show.get('sources', []):
                for track in source.get('tracks', []):
                    title = track.get('title', '')
                    if '&gt;' in title:
                        print(f" - {title}")
                        count += 1
                        if count >= 20:
                            return
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    inspect_tracks()
