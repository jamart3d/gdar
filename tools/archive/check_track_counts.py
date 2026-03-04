import json

def main():
    try:
        with open('assets/data/output.optimized_src.json', 'r') as f:
            shows = json.load(f)
    except FileNotFoundError:
        print("File not found.")
        return

    total_tracks = 0
    empty_source_tracks = 0

    for show in shows:
        for source in show.get('sources', []):
            tracks = source.get('tracks', [])
            total_tracks += len(tracks)
            if not tracks:
                empty_source_tracks += 1

    print(f"Total Tracks: {total_tracks}")
    print(f"Sources with empty tracks: {empty_source_tracks}")

if __name__ == "__main__":
    main()
