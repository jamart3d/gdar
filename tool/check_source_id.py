import json
import os

def check_source(target_id):
    file_path = 'assets/data/output.optimized_src.json'
    if not os.path.exists(file_path):
        print(f"Error: {file_path} not found.")
        return

    with open(file_path, 'r') as f:
        data = json.load(f)

    found = False
    report_lines = []

    for show in data:
        for source in show.get('sources', []):
            if source.get('id') == target_id:
                found = True
                report_lines.append(f"# Report for Source ID: {target_id}")
                report_lines.append(f"**Show Date:** {show.get('date', 'Unknown')}")
                report_lines.append(f"**Venue:** {show.get('name', 'Unknown')}")
                report_lines.append(f"**Location:** {show.get('l', 'Unknown')}")
                report_lines.append(f"**Description (_d):** {source.get('_d', 'N/A')}")
                
                # Infer URL from _d if possible, or just print typical archive format
                # Usually the identifier is embedded in _d or is the _d itself minus suffix? 
                # Let's just print what we have.
                report_lines.append(f"**Source Type:** {source.get('src', 'N/A')}")
                
                report_lines.append("\n## Sets and Tracks")
                sets = source.get('sets', [])
                for s in sets:
                    set_name = s.get('n', 'Unknown Set')
                    report_lines.append(f"\n### {set_name}")
                    for t in s.get('t', []):
                        track_num = t.get('n', '-')
                        track_title = t.get('t', 'Unknown Title')
                        duration = t.get('d', '-')
                        url = t.get('u', '-')
                        report_lines.append(f"- **{track_num}.** {track_title} ({duration}) - *{url}*")
                
                break
        if found:
            break

    if not found:
        report_lines.append(f"Source ID {target_id} not found.")

    report_content = "\n".join(report_lines)
    print(report_content)
    
    with open('source_report.md', 'w') as f:
        f.write(report_content)

if __name__ == "__main__":
    check_source('166928')
