---
name: enterprise-mcp-discovery
description: >-
  Discover an SMB department's work apps, browser systems, and business-data folders;
  research and verify agent access paths and produce a complete agent-ready systems
  report. Use for workstation-based discovery and readiness assessments, with an
  optional read-only connector kit after discovery.
---

# Enterprise Systems Discovery (v0.4)

## Outcome and scope
Produce a confirmed map of the department's systems and business data, a technical
access register another agent can use, and a plain-language Agent-Ready Report.
The report is required even when access is blocked. Connector installation is an
optional follow-up; do not let it delay the report.

Start by choosing the department, sponsor, and one primary workflow (for example,
match supplier invoices to purchase orders). List every data source that workflow
needs. Discover the wider department stack, but assess readiness for this explicit
workflow; do not imply company-wide coverage from one workstation.

## Boundaries
- Before collecting workstation metadata, explain the scope and obtain consent.
  Ask the user to open work apps, tabs, and relevant file folders. Existing explicit
  authorization counts. Offer manual discovery if they decline scanning.
- Default collection is metadata: app names, sanitized URLs/titles, folder paths,
  extensions, sizes and modification dates. Do not read file contents until the
  user authorizes a bounded read test. Keep collected inventories local.
- Do not scan the entire disk or every network share. Confirm candidate roots,
  exclusions and scan limits before folder traversal. Do not follow symlinks or
  download cloud placeholders. Record denied, offline and incomplete results.
- Strip URL credentials, query strings and fragments before saving. Redact secrets
  in names, screenshots or paths where necessary; never collect passwords/tokens.
- Discovery is read-only. Do not install connectors, change permissions, create
  credentials or send consultant messages unless authorized for that action.
- Finding documentation or installing a connector does not prove data access.
  Keep observed, user-confirmed, documented, and tested evidence distinct.

## 1. Prepare and inventory
Tell the user: “Open the apps, browser tabs and folders your department uses,
including invoices, POs, spreadsheets, shared drives, notes and task boards. I will
record app names, sanitized tab addresses and folder locations, without reading
file contents. Tell me when ready.” Explain macOS Automation prompts and let the
user decide whether to allow the requested access.

Run scripts from this skill directory. Store outputs in the engagement workspace.
On macOS:
```bash
bash scripts/inventory_macos.sh > inventory_raw.json
bash scripts/browser_tabs_macos.sh > tabs.json
python3 scripts/merge_inventory.py inventory_raw.json tabs.json inventory_raw.json
python3 scripts/filter_productivity.py < inventory_raw.json > inventory_candidates.json
```
On Windows (PowerShell 5.1+):
```powershell
powershell -NoProfile -File scripts\inventory_windows.ps1 | Out-File -Encoding utf8 inventory_raw.json
powershell -NoProfile -File scripts\browser_tabs_windows.ps1 | Out-File -Encoding utf8 tabs.json
python scripts\merge_inventory.py inventory_raw.json tabs.json inventory_raw.json
Get-Content -Raw inventory_raw.json | python scripts\filter_productivity.py | Out-File -Encoding utf8 inventory_candidates.json
```
If Python is unavailable, use `py` or collect the same fields manually.
Read scripts' `collection_errors` and limitations before drawing conclusions.
Inventory captures running GUI apps, installed app names, network mounts, open
Finder/Explorer folders and common local/cloud folder candidates. Candidates are
not confirmed business sources. No background-service completeness is implied.
Windows browser collection yields window titles, not every tab or URL; obtain
addresses via available browser/computer-use tools or a user-provided list.
On macOS, unsupported or denied browser collection must be reported as incomplete.

Group candidates in `inventory_grouped.md`. Preserve folder candidates, mounted
shares and collection errors when filtering. Keep unknown running apps for user
confirmation. Do not treat installed software as proof it is used by this department.

## 2. Confirm systems and discover data folders
Present a short proposed systems list and ask the user to correct it. Ask about
missing accounting, purchasing/inventory, sales/CRM, email/chat, notes/tasks,
document stores and remote desktop systems. Use N/A for genuinely irrelevant domains.
Ask specifically where invoices, POs, customer orders, inventory exports, reports,
and working spreadsheets live, and which are authoritative versus copies.

For every relevant folder or cloud library, identify:
- Exact path/UNC/library URL, purpose, business owner and department.
- Local, NAS/network, synced cloud, cloud-only, export inbox or archive storage.
- Relationship to systems/workflows; required or optional for the primary workflow.
- Authoritative source, sync/export schedule and freshness expectations.
- Allowed roots, excluded subfolders, access owner and required read permissions.

Use open folders and mounted shares as leads. Also check user-confirmed local
Documents/Desktop locations, OneDrive/SharePoint sync roots, Google Drive/Dropbox,
and app export destinations through available UI/settings. Common-root detection
is only a lead: it misses custom installations and cloud-only libraries.
Use computer use to inspect folder addresses and app export settings if needed.
Do not infer that a share root contains the invoices without locating the subfolder.

After root/exclusion confirmation, run bounded metadata discovery:
```bash
python3 scripts/discover_folders.py --root "/approved/department" --exclude "/approved/department/HR" --max-depth 3 --max-entries 2000 --output folder_inventory.json
```
Repeat `--root` and `--exclude` as needed. The script accepts local or mounted paths
(including Windows UNC paths when run on Windows). It never opens file contents;
it skips symlinks (including roots with symlinked ancestors; use their explicitly
approved canonical paths), records truncation/errors, and reports extension counts and
modification ranges. It skips detectable Windows offline/recall placeholders.
For cloud-only libraries use their supported metadata API/UI instead, and record
that method plus its pagination/coverage limits. Do not trigger a sync/download.

Write `DATA_LOCATIONS.md` using its template, including every confirmed source and
unresolved lead. Preserve the exact mapping between business data and its location.

## 3. Identify each system and research access
Use computer use for About/version dialogs, SaaS tenant URLs, remote sessions,
export menus and server/DSN clues. Never treat the remote-desktop client as the
business system itself. Mark inaccessible screens and ask the owner for details.

For each confirmed system AND data location, research vendor documentation first:
APIs, supported read-only database/views/ODBC, exports, file access and official
plugins/connectors/MCP. Then inspect maintained community options, then propose a
custom adapter or manual bridge. MCP is one transport, not a prerequisite.
Record exact source URLs, checked date, applicable product/version, licensing or
admin requirements and unresolved assumptions. Do not assume a cloud API exists
for the desktop edition of the same product.

Classify separately from verification:
- A: supported programmatic access (API, scoped database/view, native connector).
- B: controlled file/export bridge, with a known refresh process.
- C: UI-only/manual path, not yet suitable for this pilot.
- D: explicitly outside the chosen scope, with reason.

Complete `ACCESS_REPORT.md` and `discovery.json` using their templates/schema.
Use stable source IDs across systems, folders, tests and reports. Each required
source needs data entities, exact endpoint/path, access steps, permissions, owner,
credential reference (never values), freshness, evidence, and test status.
Record connector candidates in `mcp_catalog.json` when relevant, including official,
community or custom provenance. Do not generate empty adapter stubs as a report gate.

## 4. Verify actual read access
For each source required by the workflow, obtain authorization for the minimum
necessary read/search test; use synthetic or redacted samples where possible.
Use `templates/SMOKE_TEST.template.md`. Record in `SMOKE_TEST.md`: source ID, timestamp, method, sanitized query/action,
expected outcome, actual aggregate outcome, limits and evidence reference.
For files, verify listing/search under the allowlist, finding a known example, and
reading the minimum necessary fields only when authorized. Check that exclusions
remain excluded. Listing a folder alone does not prove PDF text extraction or
scanned-document OCR. Record extraction/OCR as tested, untested or unavailable.
For systems, exercise the intended agent identity and required entities, including
pagination and freshness where material. A TCP connection is not a data read test.
Test at least one end-to-end primary-workflow read across its required sources.
Do not persist raw invoice/customer contents in the report.
If credentials or consent are unavailable, mark access unverified/blocked with an
owner and next step. Never convert a documented possibility into “reachable today”.
Record evidence of read-only permissions; if writes cannot be ruled out, mark that
control unverified rather than claiming “writes off”.

## 5. Produce the complete report before optional installation
Always deliver:
- `inventory_raw.json`, `inventory_candidates.json`, `inventory_grouped.md`
- `folder_inventory.json` (or documented manual/cloud metadata equivalent)
- `discovery.json`, `DATA_LOCATIONS.md`, `ACCESS_REPORT.md`, `SMOKE_TEST.md`
- **`AGENT_READY_REPORT.md`** using its template: executive verdict, department and
  workflow scope, full systems/data-location coverage, evidence scorecard, verified
  access vs documented possibilities, blockers with owners, and one next action.
- `CONSULTANT_QUESTIONS.md` for unresolved owner/vendor questions; draft only.
- `NEXT_WEEK_PLAN.md` with the smallest useful follow-up.

Use plain language and the user's language in leader-facing files. Keep exact
technical instructions in the access register. Explain every unknown and discovery
limit; N/A needs a reason. Show the report and ask whether it matches the department.

Verdict rules are in the report template. Evaluate every workflow-required system
AND folder; no averaging and no bypass because one connector passed. An unknown
required source prevents PASS. A broken read-only boundary prevents a pilot-ready
verdict. The result describes readiness for this workflow, not the whole company.

## 6. Optional connector and coworker kit
Only when requested, configure official integrations first, then maintained
community connectors, then narrowly scoped custom adapters. Keep tools read-only,
use secure credential storage, and test the exact configured agent identity.
Update the report after verified results. Deliver `mcp_catalog.json`, adapter code
if needed, and `COWORKER_INSTALL_PROMPT.md` with prerequisites, scoped paths,
secret-owner references, setup, read tests and rollback. Reconfirm workstation-
specific paths/permissions on each coworker's machine; do not copy credentials.

## Completion check
The systems map is user-confirmed; data locations include exact paths and ownership;
every required source has an access plan and honest verification state; the report
exists even if blocked; verdict follows evidence; limits and next actions are clear.
