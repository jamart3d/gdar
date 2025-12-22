def find_raw_gt():
    try:
        with open('assets/data/output.optimized_src.json', 'r') as f:
            content = f.read()
            
        index = content.find('&gt;')
        if index == -1:
            print("No '&gt;' found in file.")
        else:
            print(f"Found '&gt;' at index {index}")
            start = max(0, index - 50)
            end = min(len(content), index + 50)
            print(f"Context: ...{content[start:end]}...")
            
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    find_raw_gt()
