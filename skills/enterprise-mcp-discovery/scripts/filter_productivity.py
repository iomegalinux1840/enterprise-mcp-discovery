#!/usr/bin/env python3
"""Group inventory into productivity candidates vs noise."""
from __future__ import annotations
import json, re, sys
from urllib.parse import urlparse

NOISE = re.compile(
    r"(spotify|steam|discord|wallpaper|screensa|photo booth|chess|tv\b|music$|podcasts|facetime)",
    re.I,
)
PRODUCTIVITY_APP = re.compile(
    r"(excel|word|outlook|teams|slack|acomba|maestro|sage|quickbooks|dynamics|sap|salesforce|hubspot|"
    r"notion|obsidian|clickup|todoist|asana|jira|trello|chrome|edge|safari|arc|finder|onedrive|sharepoint|"
    r"zoom|webex|cisco|power\s*bi|tableau|filezilla|cyberduck|remote\s*desktop|company\s*portal|"
    r"front|azure\s*data\s*studio|edrawings|forticlient|pulseway)",
    re.I,
)
SAAS_HINTS = [
    (r"dynamics\.com|businesscentral|^bc\.", "Business Central / Dynamics"),
    (r"salesforce\.com", "Salesforce"),
    (r"hubspot\.com", "HubSpot"),
    (r"quickbooks\.intuit\.com|intuit\.com", "QuickBooks"),
    (r"sharepoint\.com|onedrive\.live\.com|office\.com|microsoft365|teams\.microsoft\.com", "Microsoft 365"),
    (r"slack\.com", "Slack"),
    (r"clickup\.com", "ClickUp"),
    (r"notion\.so", "Notion"),
    (r"atlassian\.net|jira\.|confluence\.", "Atlassian"),
    (r"github\.com", "GitHub"),
    (r"gitlab\.com", "GitLab"),
    (r"base44\.com", "Base44"),
]

def main():
    data = json.load(sys.stdin)
    running = [a.get("name", "") for a in data.get("running_apps", [])]
    installed = data.get("installed_apps", [])
    tabs = data.get("browser_tabs", [])

    candidates, noise, saas = [], [], []
    for name in sorted(set(running + installed)):
        if NOISE.search(name) and not PRODUCTIVITY_APP.search(name):
            noise.append({"name": name, "reason": "non_productivity_heuristic"})
        elif PRODUCTIVITY_APP.search(name) or name in running:
            # keep running apps even if unknown — user will confirm
            bucket = "productivity_guess" if PRODUCTIVITY_APP.search(name) else "needs_confirm"
            candidates.append({"name": name, "bucket": bucket, "evidence": "app"})

    for t in tabs:
        url = t.get("url") or ""
        host = urlparse(url).netloc.lower()
        if not host:
            # Windows: URL may be empty because only window titles are captured.
            # Keep the title so the user can confirm the SaaS later.
            saas.append({
                "title": t.get("title"),
                "url": url,
                "host": host,
                "guess": "needs_url",
                "note": "title-only (see tabs_note)",
                "browser": t.get("browser"),
            })
            continue
        match_against = host or url
        matched = None
        for pat, label in SAAS_HINTS:
            if re.search(pat, match_against, re.I):
                matched = label
                break
        saas.append({
            "title": t.get("title"),
            "url": url,
            "host": host,
            "guess": matched or "unknown_saas",
            "browser": t.get("browser"),
        })

    out = {
        "candidates": candidates,
        "filtered_out": noise,
        "saas_from_tabs": saas,
        "tabs_urls_unavailable": data.get("tabs_urls_unavailable", False),
        "tabs_note": data.get("tabs_note", ""),
        "missing_expected_check": ["crm", "erp_accounting", "document_ecm", "notes", "tasks", "chat"],
    }
    print(json.dumps(out, indent=2))

if __name__ == "__main__":
    main()
