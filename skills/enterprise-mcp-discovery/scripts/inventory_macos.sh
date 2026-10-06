#!/usr/bin/env bash
# Read-only inventory of running GUI apps + installed apps + mounted file shares.
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

# Mounted network file shares (SMB/AFP/NFS) — read-only metadata only.
# Includes the active Finder window target so the user's open folder is captured.
mounts = []
raw_mount = run(["mount"])
for line in raw_mount.splitlines():
    # Format: "//server/share on /Volumes/Name (smbfs, nodev, ...)"
    if " on /Volumes/" not in line:
        continue
    tail = line.rsplit("(", 1)[-1].lower()
    if not any(p in tail for p in ("smbfs", "afpfs", "nfs")):
        continue
    # device = text before " on ", mount_point = text between " on " and " ("
    head, _, rest = line.partition(" on ")
    mount_point = rest.split(" (", 1)[0] if " (" in rest else rest
    if head and mount_point:
        mounts.append({
            "device": head.strip(),
            "mount_point": mount_point.strip(),
            "fs_type": [p for p in tail.split(",") if p in ("smbfs", "afpfs", "nfs")][0],
        })

finder_target = ""
try:
    finder_target = subprocess.check_output(
        ["osascript", "-e",
         'tell application "Finder" to return POSIX path of (target of front window as alias)'],
        text=True, stderr=subprocess.DEVNULL).strip()
except Exception:
    pass

print(json.dumps({
    "running_apps": running,
    "installed_apps": installed,
    "browser_tabs": [],  # filled by browser_tabs_macos.sh
    "mounted_shares": mounts,
    "finder_target": finder_target,
    "collected_at": datetime.now(timezone.utc).isoformat(),
    "host": os.uname().nodename,
}, indent=2))
PY
