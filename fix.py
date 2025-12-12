import json

def correct_sets(data):
    for show in data:
        # Fix for Soldier Field, 07/09/1995
        if show.get("date") == "1995-07-09":
            print(f"Fixing setlist for {show['date']}...")
            for source in show.get("sources", []):
                for track in source.get("tracks", []):
                    name = track.get("t", "")

                    # Set 1 (No change needed, but listed for clarity)
                    # Touch of Grey, Little Red Rooster, Lazy River Road, Masterpiece,
                    # Childhood's End, Cumberland Blues, Promised Land

                    # Set 2 Corrections
                    if name in [
                        "Shakedown Street", "Samson and Delilah", "So Many Roads",
                        "Samba in the Rain", "Corrina", "Drums", "Space",
                        "Unbroken Chain", "Sugar Magnolia"
                    ]:
                        track["s"] = "Set 2"

                    # Encore Corrections
                    if name in ["Black Muddy River", "Box Of Rain", "Box of Rain"]:
                        track["s"] = "Encore"

    return data

# Load the file
input_filename = 'assets/data/output.optimized.json'
output_filename = 'assets/data/output.optimized2.json'

try:
    with open(input_filename, 'r') as f:
        data = json.load(f)

    # Apply corrections
    corrected_data = correct_sets(data)

    # Save the corrected file
    with open(output_filename, 'w') as f:
        json.dump(corrected_data, f, separators=(',', ':'))

    print(f"Success! Corrected file saved as: {output_filename}")

except FileNotFoundError:
    print(f"Error: Could not find file '{input_filename}'. Make sure it is in the same folder.")