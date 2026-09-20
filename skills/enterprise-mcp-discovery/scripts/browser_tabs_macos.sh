#!/usr/bin/env bash
# Export open tab URL + title for common browsers (AppleScript).
# Does NOT read page body or passwords.
set -euo pipefail
python3 - <<'PY'
import json, subprocess

def tabs_chrome_family(app):
    script = f'''
    set output to ""
    try
      tell application "{app}"
        if (count of windows) is 0 then return ""
        repeat with w in windows
          try
            repeat with t in tabs of w
              set output to output & (title of t) & tab & (URL of t) & linefeed
            end repeat
          end try
        end repeat
      end tell
    end try
    return output
    '''
    try:
        raw = subprocess.check_output(["osascript", "-e", script], text=True, stderr=subprocess.DEVNULL)
    except Exception:
        return []
    rows = []
    for line in raw.splitlines():
        if not line.strip():
            continue
        parts = line.split("\t", 1)
        if len(parts) != 2:
            continue
        title, url = parts
        rows.append({"browser": app, "title": title.strip(), "url": url.strip()})
    return rows

def tabs_safari():
    script = '''
    set output to ""
    try
      tell application "Safari"
        if (count of windows) is 0 then return ""
        repeat with w in windows
          try
            repeat with t in tabs of w
              set output to output & (name of t) & tab & (URL of t) & linefeed
            end repeat
          end try
        end repeat
      end tell
    end try
    return output
    '''
    try:
        raw = subprocess.check_output(["osascript", "-e", script], text=True, stderr=subprocess.DEVNULL)
    except Exception:
        return []
    rows = []
    for line in raw.splitlines():
        parts = line.split("\t", 1)
        if len(parts) == 2:
            rows.append({"browser": "Safari", "title": parts[0].strip(), "url": parts[1].strip()})
    return rows

out = []
for app in ("Google Chrome", "Microsoft Edge", "Arc", "Brave Browser", "Chromium"):
    out.extend(tabs_chrome_family(app))
out.extend(tabs_safari())
print(json.dumps({"browser_tabs": out}, indent=2))
PY
