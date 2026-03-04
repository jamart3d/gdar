import json
import os

INPUT_FILE = 'assets/data/output.optimized_set1.json'
OUTPUT_FILE = 'assets/data/output.optimized_set1list.json'
REPORT_FILE = 'report_set1_urls.md'

def main():
    if not os.path.exists(INPUT_FILE):
        print(f"Error: {INPUT_FILE} not found.")
        return

    try:
        with open(INPUT_FILE, 'r') as f:
            data = json.load(f)
    except json.JSONDecodeError as e:
        print(f"Error decoding JSON: {e}")
        return

    urls = []
    
    print(f"Processing {len(data)} shows...")

    for show in data:
        for source in show.get('sources', []):
            identifier = source.get('_d')
            if identifier:
                url = f"https://archive.org/details/{identifier}"
                urls.append(url)
            else:
                print(f"Warning: Source ID {source.get('id')} in show {show.get('name')} missing '_d' field.")

    # Save JSON list
    try:
        with open(OUTPUT_FILE, 'w') as f:
            json.dump(urls, f, indent=2)
        print(f"Successfully saved {len(urls)} URLs to {OUTPUT_FILE}")
    except IOError as e:
        print(f"Error writing to {OUTPUT_FILE}: {e}")

    # Generate Report
    with open(REPORT_FILE, 'w') as f:
        f.write(f"# Set 1 Sources URL Report\n\n")
        f.write(f"**Total URLs Extracted:** {len(urls)}\n\n")
        f.write("## URLs\n\n")
        for url in urls:
            f.write(f"- {url}\n")
    
    print(f"Report saved to {REPORT_FILE}")

if __name__ == "__main__":
    main()
