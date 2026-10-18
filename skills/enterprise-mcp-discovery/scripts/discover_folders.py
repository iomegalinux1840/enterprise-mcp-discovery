#!/usr/bin/env python3
"""Bounded metadata inventory of explicitly approved roots; never opens file data."""
import argparse
import json
import os
import stat
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path


def inventory(roots, excludes=(), max_depth=3, max_entries=2000):
    exclusions = [os.path.abspath(os.path.expanduser(p)) for p in excludes]
    result = {"collected_at": datetime.now(timezone.utc).isoformat(),
              "limits": {"max_depth": max_depth, "max_entries": max_entries},
              "excluded_roots": exclusions, "roots": []}
    budget = max_entries

    def excluded(path):
        return any(path == e or path.startswith(e + os.sep) for e in exclusions)

    for raw in roots:
        path = os.path.abspath(os.path.expanduser(raw))
        record = {"path": path, "folders": [], "errors": [], "skipped": [],
                  "truncated": False, "entries_examined": 0, "status": "unverified"}
        result["roots"].append(record)
        if excluded(path):
            record["status"] = "excluded"
            continue
        try:
            root_stat = os.lstat(path)
            if stat.S_ISLNK(root_stat.st_mode) or getattr(root_stat, "st_file_attributes", 0) & (0x400 | 0x1000 | 0x40000 | 0x400000):
                record["status"] = "symlink_skipped"
                continue
            if not stat.S_ISDIR(root_stat.st_mode):
                raise NotADirectoryError(path)
            # Reject roots reached through symlinked ancestors too.
            if os.path.normcase(os.path.realpath(path)) != os.path.normcase(path):
                record["status"] = "symlink_ancestor_skipped"
                continue
        except OSError as exc:
            record["errors"].append({"path": path, "error": str(exc)})
            record["status"] = "unavailable"
            continue
        stack = [(path, 0)]
        while stack and budget > 0:
            current, depth = stack.pop()
            row = {"path": current, "depth": depth, "files": 0, "bytes": 0,
                   "extensions": {}, "oldest_modified": None, "newest_modified": None}
            record["folders"].append(row)
            extensions = Counter()
            try:
                with os.scandir(current) as entries:
                    for entry in entries:
                        if budget <= 0:
                            record["truncated"] = True
                            break
                        budget -= 1
                        record["entries_examined"] += 1
                        full = os.path.abspath(entry.path)
                        if excluded(full):
                            record["skipped"].append({"path": full, "reason": "excluded"})
                            continue
                        try:
                            info = entry.stat(follow_symlinks=False)
                            attrs = getattr(info, "st_file_attributes", 0)
                            # Reparse points, offline files, recall-on-open/data-access.
                            if stat.S_ISLNK(info.st_mode) or attrs & (0x400 | 0x1000 | 0x40000 | 0x400000):
                                record["skipped"].append({"path": full, "reason": "link_or_cloud_placeholder"})
                                continue
                            if stat.S_ISDIR(info.st_mode):
                                if depth < max_depth:
                                    stack.append((full, depth + 1))
                                else:
                                    record["truncated"] = True
                                    record["skipped"].append({"path": full, "reason": "depth_limit"})
                            elif stat.S_ISREG(info.st_mode):
                                row["files"] += 1
                                row["bytes"] += info.st_size
                                extensions[Path(entry.name).suffix.lower() or "[no extension]"] += 1
                                stamp = datetime.fromtimestamp(info.st_mtime, timezone.utc).isoformat()
                                row["oldest_modified"] = min(row["oldest_modified"] or stamp, stamp)
                                row["newest_modified"] = max(row["newest_modified"] or stamp, stamp)
                        except OSError as exc:
                            record["errors"].append({"path": full, "error": str(exc)})
            except OSError as exc:
                record["errors"].append({"path": current, "error": str(exc)})
            row["extensions"] = dict(extensions)
        if stack or budget <= 0:
            record["truncated"] = True
        record["status"] = "partial" if record["truncated"] or record["errors"] else "metadata_collected"
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", action="append", required=True)
    parser.add_argument("--exclude", action="append", default=[])
    parser.add_argument("--max-depth", type=int, default=3)
    parser.add_argument("--max-entries", type=int, default=2000)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    if args.max_depth < 0 or args.max_entries < 1:
        parser.error("depth must be nonnegative and entries positive")
    # Refuse output inside a scanned root, avoiding inventorying our own report.
    output = os.path.abspath(args.output)
    for root in args.root:
        base = os.path.abspath(os.path.expanduser(root))
        if output == base or output.startswith(base + os.sep):
            parser.error("output must be outside scanned roots")
    data = inventory(args.root, args.exclude, args.max_depth, args.max_entries)
    Path(output).write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
