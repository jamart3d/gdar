import json

INPUT_FILE = 'assets/data/output.fixed_encores.json'

def main():
    with open(INPUT_FILE, 'r', encoding='utf-8') as f:
        data = json.load(f)

    found = False
    for show in data:
        for source in show.get('sources', []):
            if source.get('id') == '97743':
                print(f"Source 97743 ({show.get('date')}):")
                for t in source.get('tracks', []):
                    print(f"  {t.get('t')} | Set: {t.get('s')} | File: {t.get('u')}")
                found = True
                break
        if found: break

if __name__ == '__main__':
    main()
