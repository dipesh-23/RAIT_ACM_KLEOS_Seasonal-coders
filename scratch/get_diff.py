import subprocess
import sys

def get_diff(file_path=None):
    cmd = ['git', 'diff', 'main', 'origin/dip']
    if file_path:
        cmd.append(file_path)
    result = subprocess.run(cmd, capture_output=True, text=True, encoding='utf-8')
    return result.stdout

if __name__ == '__main__':
    file_to_diff = sys.argv[1] if len(sys.argv) > 1 else None
    diff_text = get_diff(file_to_diff)
    print(diff_text[:30000]) # Print up to 30000 chars to avoid overwhelming output
