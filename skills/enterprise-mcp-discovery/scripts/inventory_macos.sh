#!/usr/bin/env bash
# Read-only location/app metadata; no folder traversal or file-content reads.
set -euo pipefail
python3 - <<'PY'
import glob
import json
import os
import re
import subprocess
from datetime import datetime, timezone

errors = []
def run(cmd, source):
    try:
        return subprocess.check_output(cmd, text=True, stderr=subprocess.PIPE, timeout=30)
    except Exception as exc:
        errors.append({"source": source, "error": type(exc).__name__})
        return ""

raw = run(["osascript", "-e", 'tell application "System Events" to get name of every process whose background only is false'], "running_apps")
running = [{"name": n.strip()} for n in raw.strip().split(",") if n.strip()]
installed = sorted({os.path.basename(p)[:-4] for base in ["/Applications", os.path.expanduser("~/Applications")] for p in glob.glob(base + "/*.app")})
mounts = []
for line in run(["mount"], "mounted_shares").splitlines():
    match = re.match(r"^(.*?) on (.*?) \(([^, )]+)", line)
    if match and match[3] in {"smbfs", "afpfs", "nfs"}:
        # SMB mount devices may include username or credentials.
        device = re.sub(r"^(//)[^/@]+@", r"\1", match[1])
        mounts.append({"device": device, "mount_point": match[2], "fs_type": match[3]})
script = '''tell application "Finder"
set output to ""
repeat with w in windows
try
set output to output & (POSIX path of (target of w as alias)) & linefeed
end try
end repeat
return output
end tell'''
folders = [p for p in run(["osascript", "-e", script], "open_folders").splitlines() if p]
candidates = [{"path": p, "evidence": "open_folder", "confirmed": False} for p in folders]
for pattern in ["~/Documents", "~/Desktop", "~/Library/CloudStorage/*", "~/OneDrive*", "~/Dropbox", "~/Google Drive"]:
    for p in glob.glob(os.path.expanduser(pattern)):
        if os.path.isdir(p):
            candidates.append({"path": p, "evidence": "common_location", "confirmed": False})
print(json.dumps({"running_apps": running, "installed_apps": installed, "browser_tabs": [],
                  "mounted_shares": mounts, "open_folders": folders,
                  "finder_target": folders[0] if folders else "", "folder_candidates": candidates,
                  "collection_errors": errors, "collected_at": datetime.now(timezone.utc).isoformat()}, indent=2))
PY
