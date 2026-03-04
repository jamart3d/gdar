import json

INPUT_FILE = 'assets/data/output.fixed_encores.json'

def main():
    with open(INPUT_FILE, 'r', encoding='utf-8') as f:
        data = json.load(f)

    for show in data:
        if '1970-01-03' in show.get('date', ''):
            print(f"Found Show: {show.get('date')} - {show.get('name')}")
            for source in show.get('sources', []):
                print(f"  Source: {source.get('id')}")
                for t in source.get('tracks', []):
                    if 'd2t03' in t.get('u', ''):
                        print(f"    Track: {t.get('t')} | Set: {t.get('s')} | File: {t.get('u')}")

        if '83-12-28' in show.get('date', '') or '1983-12-28' in show.get('date', ''):
             print(f"Found Show: {show.get('date')} - {show.get('name')}")
             for source in show.get('sources', []):
                print(f"  Source: {source.get('id')}")
                for t in source.get('tracks', []):
                    if 'd2t01' in t.get('u', ''):
                         print(f"    Track: {t.get('t')} | Set: {t.get('s')} | File: {t.get('u')}")

if __name__ == '__main__':
    main()
