import json

def get_source(file, sid):
    with open(file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    for show in data:
        for s in show.get('sources', []):
            if str(s.get('id')) == str(sid):
                return s
    return None

def print_tracks(label, source):
    print(f"\n{label}:")
    if not source:
        print("Source not found")
        return
    if 'sets' in source:
        for set_obj in source['sets']:
            print(f"Set: {set_obj.get('n', 'N/A')}")
            for t in set_obj.get('t', []):
                print(f"  {t.get('t')}")
    elif 'tracks' in source:
        for t in source['tracks']:
            print(f"  {t.get('t')}")

s1 = get_source('assets/data/output.optimized_src_last.json', '3927')
s2 = get_source('assets/data/output.optimized_src.json', '3927')
