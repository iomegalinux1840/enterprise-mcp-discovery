#!/usr/bin/env bash
# Read-only inventory of running GUI apps + /Applications names.
# Usage: bash inventory_macos.sh
set -euo pipefail
python3 - <<'PY'
import json, subprocess, os, glob
from datetime import datetime, timezone

def run(cmd):
    try:
        return subprocess.check_output(cmd, text=True, stderr=subprocess.DEVNULL)
    except Exception:
        return ""

# Running apps via osascript
osa = '''
set out to ""
tell application "System Events"
  set procs to (name of every process whose background only is false)
  repeat with p in procs
    set out to out & p & linefeed
  end repeat
end tell
return out
'''
running = []
raw = run(["osascript", "-e", osa])
for name in sorted({n.strip() for n in raw.splitlines() if n.strip()}):
    running.append({"name": name})

installed = []
for base in ["/Applications", os.path.expanduser("~/Applications")]:
    for path in glob.glob(base + "/*.app"):
        installed.append(os.path.basename(path)[:-4])
installed = sorted(set(installed))

print(json.dumps({
    "running_apps": running,
    "installed_apps": installed,
    "browser_tabs": [],  # filled by browser_tabs_macos.sh
    "collected_at": datetime.now(timezone.utc).isoformat(),
    "host": os.uname().nodename,
}, indent=2))
PY
