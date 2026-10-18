#!/usr/bin/env python3
"""Merge browser-tabs JSON into the inventory JSON (used on macOS and Windows).

Reads both files fully before writing, so it is safe to overwrite the inventory
file in place.

Usage:
  python3 scripts/merge_inventory.py inventory_raw.json tabs.json inventory_raw.json
"""
from inventory_utils import sanitize_url
import json
import sys
from pathlib import Path


def load(path):
    with open(path, "r", encoding="utf-8-sig") as fh:
        return json.load(fh)


def main():
    inventory = load(sys.argv[1])
    tabs = load(sys.argv[2])
    out_path = Path(sys.argv[3])

    inventory["browser_tabs"] = [dict(tab, url=sanitize_url(tab.get("url", ""))) for tab in tabs.get("browser_tabs", [])]
    inventory.setdefault("collection_errors", []).extend(tabs.get("collection_errors", []))
    for key in ("tabs_urls_unavailable", "tabs_note"):
        if key in tabs:
            inventory[key] = tabs[key]

    out_path.write_text(
        json.dumps(inventory, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
