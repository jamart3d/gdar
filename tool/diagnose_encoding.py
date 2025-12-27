import json

input_file = 'assets/data/output.cleaned_underscores.json'

def main():
    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)

    for show in data:
        for source in show.get('sources', []):
            for s in source.get('sets', []):
                for t in s.get('t', []):
                    name = t.get('t', '')
                    # Check for patterns
                    if "Don" in name and "t Ease Me In" in name:
                        print(f"Found: {name}")
                        print(f"Repr: {repr(name)}")
                    if "It" in name and "s All Over Now" in name:
                         print(f"Found: {name}")
                         print(f"Repr: {repr(name)}")
                    if "Ã" in name:
                        print(f"Found Suspicious: {name}")
                        print(f"Repr: {repr(name)}")
                        # Print only the first few to avoid spam
                        return

if __name__ == '__main__':
    main()
