
import json
import os
import re

# Paths
SOURCE_FILE = r'c:\Users\jeff\StudioProjects\gdar\packages\shakedown_core\assets\data\output.optimized_src.json'
HINTS_FILE = r'c:\Users\jeff\StudioProjects\gdar\packages\shakedown_core\assets\data\audio\grateful_dead_song_structure_hints.json'

def normalize_title(title):
    if not title:
        return ""
    # Strip quotes
    title = title.strip().strip('"')
    
    # Remove markers of variations or transitions
    # e.g. "Clementine -", "Dark Star >", "Althea (false start)"
    markers = [" -", " >", " (", " [", " {", ">", "-"]
    for m in markers:
        if m in title:
            title = title.split(m)[0]
    
    # Clean up result
    title = title.strip()
    return title

def get_production_titles_with_counts():
    with open(SOURCE_FILE, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    counts = {}
    for show in data:
        for source in show.get('sources', []):
            for s_set in source.get('sets', []):
                for track in s_set.get('t', []):
                    title = normalize_title(track.get('t', ''))
                    if title:
                        counts[title] = counts.get(title, 0) + 1
    return counts

def create_id(title):
    # Simple ID generation: lower case, underscores, remove non-alnum
    s = title.lower()
    s = re.sub(r'[^a-z0-9\s]', '', s)
    s = s.strip().replace(' ', '_')
    return s

def get_template(title):
    return {
        "id": create_id(title),
        "title": title,
        "canonical_title": title,
        "variant": "main",
        "aliases": [title],
        "match_keys": [create_id(title)],
        "confidence": 0.8,
        "tempo": {
            "bpm_min": 70,
            "bpm_max": 140,
            "feel": "standard-rock",
            "swing": 0.0
        },
        "pulse": {
            "beats_per_bar": 4,
            "subdivision": "8th",
            "beat_strength": "medium"
        },
        "rhythm": {
            "density": "medium",
            "transient_profile": "snare",
            "notes": "Synchronized from production database."
        },
        "sections": [
            {
                "name": "verse",
                "tempo_bias": "stable",
                "pulse_confidence": 0.85
            }
        ],
        "detector_hints": {
            "prefer_pcm": False,
            "prefer_low_onsets": True,
            "prefer_mid_onsets": True,
            "phase_lock_strength": 0.7,
            "refractory_bias": "normal"
        }
    }

def main():
    print(f"Reading production titles from {SOURCE_FILE}...")
    prod_counts = get_production_titles_with_counts()
    prod_titles = set(prod_counts.keys())
    print(f"Found {len(prod_titles)} unique normalized production titles.")

    # Sort by frequency to see what's what
    sorted_by_freq = sorted(prod_counts.items(), key=lambda x: x[1], reverse=True)
    print("\nTop 50 titles by frequency:")
    for title, count in sorted_by_freq[:50]:
        print(f"{title}: {count}")

    print(f"\nReading hints from {HINTS_FILE}...")
    with open(HINTS_FILE, 'r', encoding='utf-8') as f:
        hints_data = json.load(f)
    
    existing_hints = hints_data.get('entries', [])
    new_entries = []
    
    # 1. Start with existing hints that match production titles (any frequency)
    used_prod_titles = set()
    for entry in existing_hints:
        raw_title = entry.get('title', '')
        title = normalize_title(raw_title)
        
        matched_title = None
        if title in prod_titles:
            matched_title = title
        elif raw_title in prod_titles:
            matched_title = raw_title
        else:
            # Check for case-insensitive matches
            for prod_t in prod_titles:
                if prod_t.lower() == title.lower():
                    matched_title = prod_t
                    break
        
        if matched_title:
            entry['title'] = matched_title
            new_entries.append(entry)
            used_prod_titles.add(matched_title)
        else:
            print(f"Dropping hint not in production: {raw_title}")

    # 2. Add skeleton entries for production titles that didn't have a hint
    # BUT only if they appear multiple times (likely real songs)
    # The GD repertoire is ~450 songs.
    
    exclude_keywords = [
        "tuning", "intro", "outro", "noise", "discussions", "technical difficulties", 
        "bill graham", "unknown", "talk", "chatter", "crowd", "intermission", "break", 
        "edit", "filler", "aborted", "false start", "take", "rehearsal", "interview", 
        "commentary"
    ]

    # Let's count how many songs we'd get with different thresholds
    # 1. Narrow down production titles to those with count >= 10
    core_prod_titles = set()
    for title, count in prod_counts.items():
        lower_t = title.lower()
        if any(x in lower_t for x in exclude_keywords): continue
        if len(title) < 4 or sum(c.isdigit() for c in title) > 2: continue
        if count >= 10:
            core_prod_titles.add(title)
    
    print(f"Core production titles (frequency >= 10): {len(core_prod_titles)}")
    
    # 2. Match hints to core titles
    new_entries = []
    used_core_titles = set()
    
    for entry in existing_hints:
        raw_title = entry.get('title', '')
        title = normalize_title(raw_title)
        
        matched_title = None
        if title in core_prod_titles:
            matched_title = title
        elif raw_title in core_prod_titles:
            matched_title = raw_title
        else:
            # Case-insensitive
            for prod_t in core_prod_titles:
                if prod_t.lower() == title.lower() or prod_t.lower() == raw_title.lower():
                    matched_title = prod_t
                    break
        
        if matched_title:
            entry['title'] = matched_title
            new_entries.append(entry)
            used_core_titles.add(matched_title)
        else:
            # Only log dropping of things that were actually in the original hints if possible
            # But here we just drop anything not in the core
            pass

    # 3. Add skeleton entries for core titles that didn't have a hint
    for prod_t in core_prod_titles:
        if prod_t not in used_core_titles:
            new_entries.append(get_template(prod_t))
            used_core_titles.add(prod_t)

    # Final cleanup and sort
    unique_new_entries = {e['title']: e for e in new_entries}
    new_entries = sorted(unique_new_entries.values(), key=lambda x: x['title'].lower())

    hints_data['entries'] = new_entries
    print(f"\nFinal Entry Count (Core Repertoire): {len(new_entries)} songs.")
    print("Sample of final titles:")
    import random
    sample = [e['title'] for e in random.sample(new_entries, min(50, len(new_entries)))]
    print(", ".join(sample))

    with open(HINTS_FILE, 'w', encoding='utf-8') as f:
        json.dump(hints_data, f, indent=4, ensure_ascii=False)
    
    print(f"Updated {HINTS_FILE} successfully.")

if __name__ == "__main__":
    main()
