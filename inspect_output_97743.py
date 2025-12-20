import json

INPUT_FILE = 'assets/data/output.fixed_sets.json'

def main():
    try:
        with open(INPUT_FILE, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except FileNotFoundError:
        print("File not found.")
        return

    for show in data:
        for source in show.get('sources', []):
            if source.get('id') == '97743':
                print(f"Source 97743 ({show.get('date')}):")
                for t in source.get('tracks', []):
                    # Check d2t03
                    if 'd2t03' in t.get('u', ''):
                        print(f"  {t.get('t')} | Set: {t.get('s')} | File: {t.get('u')}")
                    # Check random others
                    if 'd2t01' in t.get('u', ''):
                        print(f"  {t.get('t')} | Set: {t.get('s')} | File: {t.get('u')}")

if __name__ == '__main__':
    main()
