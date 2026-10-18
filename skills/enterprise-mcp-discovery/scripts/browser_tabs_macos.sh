#!/usr/bin/env bash
# Export open tab URL + title for common browsers (AppleScript).
# Does NOT read page body or passwords.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PYTHONPATH="$SCRIPT_DIR${PYTHONPATH:+:$PYTHONPATH}" python3 - <<'PY'
import json, subprocess
from inventory_utils import sanitize_url
errors = []

def is_running(app):
    try:
        return subprocess.check_output(["osascript", "-e", f'application "{app}" is running'], text=True, timeout=5).strip() == "true"
    except Exception as exc:
        errors.append({"source": app, "error": type(exc).__name__})
        return False

# Delimiter is defined OUTSIDE the browser `tell` block as an ASCII char,
# because the AppleScript keyword `tab` collides with each browser's tab
# object and would otherwise emit the literal text "tab" instead of "\t".
DELIM_DEF = 'set d to (ASCII character 9)'

def tabs_chrome_family(app):
    script = f'''
    {DELIM_DEF}
    set output to ""
      tell application "{app}"
        if (count of windows) is 0 then return ""
        repeat with w in windows
            repeat with t in tabs of w
              set output to output & (title of t) & d & (URL of t) & linefeed
            end repeat
        end repeat
      end tell
    return output
    '''
    try:
        raw = subprocess.check_output(["osascript", "-e", script], text=True, stderr=subprocess.PIPE, timeout=30)
    except Exception as exc:
        errors.append({"source": "browser_tabs", "error": type(exc).__name__})
        return []
    rows = []
    for line in raw.splitlines():
        if not line.strip():
            continue
        parts = line.split("\t", 1)
        if len(parts) != 2:
            continue
        title, url = parts
        rows.append({"browser": app, "title": title.strip(), "url": sanitize_url(url.strip())})
    return rows

def tabs_safari():
    script = '''
    set d to (ASCII character 9)
    set output to ""
      tell application "Safari"
        if (count of windows) is 0 then return ""
        repeat with w in windows
            repeat with t in tabs of w
              set output to output & (name of t) & d & (URL of t) & linefeed
            end repeat
        end repeat
      end tell
    return output
    '''
    try:
        raw = subprocess.check_output(["osascript", "-e", script], text=True, stderr=subprocess.PIPE, timeout=30)
    except Exception as exc:
        errors.append({"source": "browser_tabs", "error": type(exc).__name__})
        return []
    rows = []
    for line in raw.splitlines():
        parts = line.split("\t", 1)
        if len(parts) == 2:
            rows.append({"browser": "Safari", "title": parts[0].strip(), "url": sanitize_url(parts[1].strip())})
    return rows

out = []
for app in ("Google Chrome", "Microsoft Edge", "Arc", "Brave Browser", "Chromium"):
    if is_running(app):
        out.extend(tabs_chrome_family(app))
if is_running("Safari"):
    out.extend(tabs_safari())
print(json.dumps({"browser_tabs": out, "collection_errors": errors, "tabs_urls_unavailable": bool(errors), "tabs_note": "Supported running browsers only; errors mean incomplete collection. Firefox and other unsupported browsers require manual/UI discovery."}, indent=2))
PY
