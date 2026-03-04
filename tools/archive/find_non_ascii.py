import json

input_file = 'assets/data/output.cleaned_durations.json'

def main():
    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)

    found_chars = set()
    examples = []

    targets = set()
    for show in data:
        for source in show.get('sources', []):
            for s in source.get('sets', []):
                for t in s.get('t', []):
                    name = t.get('t', '')
                    if any(x in name for x in ["Goin", "He", "It", "Uncle John"]) and any(ord(c) > 127 for c in name):
                         # Extract the garbage part
                         if "Uncle John" in name:
                             garbage = name.replace("Uncle John", "").replace("s Band", "").replace("'s Band", "")
                             targets.add(garbage)
                         elif "Goin" in name:
                             garbage = name.replace("Goin", "").replace(" Down The Road Feelin", "").replace(" Bad", "")
                             parts = garbage.split() # Splitting unlikely to work if garbage is attached
                             # Just use the substrings found
                             # Hardcoding extraction based on known structure
                             if "Goin" in name and " Down" in name:
                                 start = name.find("Goin") + 4
                                 end = name.find(" Down")
                                 targets.add(name[start:end])
                                 
                                 start2 = name.find("Feelin") + 6
                                 end2 = name.find(" Bad")
                                 targets.add(name[start2:end2])
                         elif "It" in name and "All Over" in name:
                             start = name.find("It") + 2
                             end = name.find("'s")
                             targets.add(name[start:end])
                         elif "He" in name and "Gone" in name:
                             start = name.find("He") + 2
                             end = name.find("'s")
                             targets.add(name[start:end])

    print("target_strings = [")
    sorted_targets = sorted(list(targets), key=len, reverse=True)
    for t in sorted_targets:
        if t:
            print(f"    {repr(t)},")
    print("]")

if __name__ == '__main__':
    main()
