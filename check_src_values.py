import json
from collections import Counter

def main():
    try:
        with open('assets/data/output.optimized_src.json', 'r') as f:
            shows = json.load(f)
    except FileNotFoundError:
        print("File not found.")
        return

    src_values = []
    source_src_values = []

    for show in shows:
        src_values.append(str(show.get('src')))
        for source in show.get('sources', []):
            source_src_values.append(str(source.get('src')))

    print("Show 'src' counts:")
    for k, v in Counter(src_values).most_common():
        print(f"  {k}: {v}")

    print("\nSource 'src' counts:")
    for k, v in Counter(source_src_values).most_common():
        print(f"  {k}: {v}")

if __name__ == "__main__":
    main()
