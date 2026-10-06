---
name: enterprise-mcp-discovery
description: >-
  Use this when onboarding a non-developer so an agent can discover work apps
  (open-apps inventory + browser tabs), pre-fill a systems questionnaire, confirm
  with the user, deepen SaaS vs on-prem via computer use, find official then
  community MCP servers, scaffold missing ones, install/test, produce a director-facing agent-ready report with checkmarks,
  and a coworker install kit prompt. For accounting/sales/purchasing/ERP/CRM kickstarts
  when Codex/Claude lack native plugins (incl. Québec stacks).
---

# Enterprise Systems → MCP Kickstart (v0.3)

## Goal
From a live workstation, build a **confirmed systems map**, then a **MCP kit**
(official → community → custom) so agents can read accounting / sales / purchasing
(and related) data — ending with a director-facing **Agent-Ready Report** (checkmarks + verdict), then optional MCP kit + **coworker install prompt**.

## Role split (read this before writing)
- **Internal files** (``scripts/``, ``inventory_raw.json``, ``discovery.json``,
  ``mcp_catalog.json``, ``ACCESS_REPORT.md``, ``SMOKE_TEST.md``) may stay technical.
- **Outward-facing files** (``AGENT_READY_REPORT.md``, ``CONSULTANT_QUESTIONS.md``,
  ``COWORKER_INSTALL_PROMPT.md``, ``NEXT_WEEK_PLAN.md``) are read by non-developers:
  use plain language, no MCP/OData/OAuth/PKCE jargon, and the user's language.
- Templates under ``templates/`` that render outward files follow the same rule.

## Hard rules
- **Consent first.** Before any inventory, ask the user to open daily work apps and
  explicitly allow scanning running apps + browser tab *URLs* (not password fields).
  On macOS, warn them that **permission pop-ups will appear** (Automation / Apple
  Events access for Finder and the browsers) and tell them to click **Allow / OK**
  on each one. On Windows, the PowerShell scan is read-only and needs no such prompt.
- **Read-only by default** for all generated MCP tools until a later write phase.
- **Never invent credentials.** Mark `needs_secure_secret`; use Keychain/1Password/secure forms.
- **Never claim MCP works** until a smoke test passes on this machine.
- Prefer **narrow tools** over arbitrary SQL/shell.
- One **primary workflow** for the first kit (e.g. late POs), not boil-the-ocean.
- Do **not** scrape full page HTML/body content via bash/PowerShell unless the user opts in and
  the site is non-sensitive; default = **URLs + titles only**.

---

## Phase 0 — Prep (user action)
Tell the user (fr-CA or en matching them):

> Open every app and browser tab you use for work on a normal day (ERP, email,
> chat, Excel, banking portal, your notes app, your task board, your shared file
> folders, etc.). Leave them open. Say **DONE** when ready.
> I will inventory running apps, browser tab addresses, and mounted shared
> folders (not passwords or file contents).
>
> Heads-up: on macOS a few **permission pop-ups** will appear. Please click
> **Allow / OK** on each one so I can read the app and browser list.
> On Windows, the scan is read-only PowerShell and should not ask to install anything.

Wait for DONE. If they refuse scanning, fall back to manual questionnaire only.

---

## Phase 1 — Passive inventory (macOS or Windows)
Run the bundled scripts (or equivalent) on **their** machine.

### macOS
```bash
bash scripts/inventory_macos.sh > inventory_raw.json
bash scripts/browser_tabs_macos.sh > tabs.json
python3 scripts/merge_inventory.py inventory_raw.json tabs.json inventory_raw.json
```

### Windows (PowerShell 5.1 or newer)
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\inventory_windows.ps1 | Out-File -Encoding utf8 inventory_raw.json
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\browser_tabs_windows.ps1 | Out-File -Encoding utf8 tabs.json
python scripts\merge_inventory.py inventory_raw.json tabs.json inventory_raw.json
```

On Windows, `python` may be `py`; if neither exists, open the two JSON files and
set `browser_tabs` manually from `tabs.json`.

Capture:
1. **Running GUI apps** — macOS: `osascript` / System Events; Windows: `Get-Process`
   with a window title (excludes background services).
2. **Installed Applications** — macOS: names under `/Applications`, `~/Applications`;
   Windows: DisplayName from the Uninstall registry keys.
3. **Browser tabs** — macOS: URL + title for Chrome / Edge / Arc / Safari via
   AppleScript (`scripts/browser_tabs_macos.sh`). Windows: **titles only** — Chrome,
   Edge, and Firefox do not expose every tab URL to PowerShell, so
   `scripts/browser_tabs_windows.ps1` sets `tabs_urls_unavailable: true` and asks the
   user to paste the address-bar list or use a copy-all-tabs browser extension.
4. **Mapped file shares** — macOS: SMB/AFP/NFS mounts plus the active Finder window
   target (`finder_target`); Windows: mapped network drives (`Win32_LogicalDisk`,
   `DriveType=4`) plus the active File Explorer window target (`finder_target`).
   The user should open their shared folder in Finder / File Explorer so it is captured.

The merge step always runs so `inventory_raw.json` has the same shape on both OSes.

Write `inventory_raw.json`:
```json
{
  "running_apps": [{"name": "..."}],
  "installed_apps": ["..."],
  "browser_tabs": [{"browser": "Chrome", "title": "...", "url": "..."}],
  "mounted_shares": [{"device": "...", "mount_point": "...", "fs_type": "smbfs"}],
  "finder_target": "/Volumes/Commun/...",
  "tabs_urls_unavailable": false,
  "tabs_note": "...",
  "collected_at": "ISO-8601"
}
```

### Limits to tell the user honestly
- macOS AppleScript gets **URLs and titles**; Windows PowerShell gets **window titles
  only** (no tab URLs). Neither reads the full page DOM or “what the form says”.
- Deeper UI (version dialogs, About boxes) = **Phase 5 computer use**, not bash.
- Incognito / some enterprise browsers may hide tabs; on Windows, all URLs come from
  the user's pasted list or a browser extension.

---

## Phase 2 — Sort, group, filter
From inventory, produce `inventory_grouped.md` + `inventory_candidates.json`.

### Groups
| Group | Examples |
|---|---|
| ERP / accounting | Acomba, Maestro, BC, Sage, QuickBooks |
| Sales / CRM | Salesforce, HubSpot, Dynamics |
| Purchasing / inventory | ERP modules, SoftExpert |
| Collab / chat | Teams, Slack, Outlook |
| Docs / files | SharePoint, Finder/Explorer NAS, SMB shares, mapped drives, Google Drive, OneDrive |
| Notes / tasks | Obsidian, ClickUp, Notion, Todoist |
| Dev / IT | VS Code, Docker, Terminal — keep for IT context |
| Noise | Games, Spotify, personal social, wallpaper apps |

### Filter
- Drop **noise** (entertainment, pure personal) into `filtered_out` with reason.
- Keep ambiguous items in `needs_confirm` (e.g. Chrome only — tabs decide).
- From **URLs**, infer SaaS: `*.dynamics.com`, `app.hubspot.com`, `quickbooks.intuit.com`,
  Microsoft 365, banking, etc.
- Map hostnames → candidate system names.

---

## Phase 3 — Pre-fill questionnaire → user confirm
Build draft `discovery.json` from candidates. Present a **short confirmation list**:

> I think your company uses: …  
> Please confirm Y/N per line. Add anything missing.

Then ask **gap questions** for domains not seen:
- CRM?
- ERP / accounting?
- Document/ECM vault?
- Where do invoice/PO PDFs live?
- Notes system?
- Task / project system?

If a major domain is empty, mark `missing_expected: ["crm", …]` and ask explicitly.

Update `discovery.json` only after confirmation.

---

## Phase 4 — Questionnaire completeness gate
Ensure `discovery.json` has for each confirmed system:
- name, domain, hosting guess (`saas` | `on_prem` | `unknown`), evidence
  (`running_app` | `browser_tab` | `user_stated`)

Stop inventory loop when sponsor confirms the map is “good enough for week 1”.

---

## Phase 5 — Deepen with computer use (versions, SaaS vs on-prem)
For each **confirmed** productivity system (priority: accounting → purchasing → sales):

1. If **desktop app**: Computer Use → Help → About / splash / title bar → capture version.
2. If **browser SaaS**: note exact URL, tenant hints, whether login is SSO.
3. If **on-prem**: ask/find install path, server name, ODBC/DSN clues (read-only).
4. Record `version`, `hosting`, `access_path_guess` (`api` | `odbc` | `export` | `ui_only`).

Do **not** type passwords. If login wall: mark `needs_user_login` and pause.

Write updates into `ACCESS_REPORT.md` (compatibility matrix).

---

## Phase 6 — MCP discovery (search order — strict)
For each system that needs agent access:

### 6a — Official first
Search **official** registries/repos only first:
- Anthropic / Claude official MCP listings & docs
- OpenAI / Codex official MCP docs & example repos
- Vendor official MCP (Microsoft, Slack, Atlassian, …) when applicable
- GitHub orgs that are clearly vendor-official

Record hits in `mcp_catalog.json`: `{system, source: "official", repo, install}`.

### 6b — Community / directory
If none official: search MCP directories / awesome-mcp lists / GitHub topic `mcp-server`
for that product. Prefer maintained repos (recent commits, stars, license).

`source: "community"`.

### 6c — Custom scaffold
If still missing: plan **new read-only MCP** (Class A API/SQL or Class B export folder).
`source: "custom"`.

**Never** skip 6a→6b→6c order. Prefer configuring an official M365/Slack MCP over
rebuilding chat/file access.

---

## Phase 7 — Install found + build missing
1. Show user a checklist: install these official/community MCPs (exact steps).
2. Generate custom stubs under `mcp-servers/<slug>/` for gaps.
3. Help wire Codex + Claude Desktop config (stdio entries, env placeholders).
4. Run **smoke tests** (3 read calls each). Log pass/fail in `SMOKE_TEST.md`.
5. Failed smoke → fix or reclassify Class C with manual export SOP.

---

## Phase 8 — Coworker kit prompt
Create `COWORKER_INSTALL_PROMPT.md` — a copy-paste prompt another employee (or their
Codex/Claude) can run on **their** PC to install the same kit:

Must include:
- What was discovered (systems list)
- Which MCPs to install (URLs + config JSON snippets)
- Env vars needed (`needs_secure_secret` list — not secret values)
- Custom `mcp-servers/` how to build (`npm i` / `uv sync`) and register
- Smoke test commands
- Read-only reminder + who to ask for credentials (IT/sponsor)
- Rollback: how to remove MCP entries

Also emit `mcp-kit.zip` contents list (or folder) suitable to share internally.

---

---

## Phase 9 — Consultant questions (plain-language, copy-paste)

Create **`CONSULTANT_QUESTIONS.md`** — the file a **non-developer** actually sends out.
This is the bridge between discovery and access: it turns each open question into a
ready-to-send email/Slack message that a non-technical person can paste.

### Rules
- **No jargon.** Never say "MCP", "OData", "OAuth", "PKCE", "service principal", or
  "DCR" in the outgoing message. The technical person reads those fine, but the person
  copying the message should not have to understand them.
- **One block per software, each self-contained.** Consultants are usually different
  per product, so every block must make sense on its own and name its owner.
- **Grouped by software**, never by concept, phase, or "class".
- **Copy-paste ready**, with a clear `To:`, a one-line context, and a concrete ask.
- **Written in the user's language.** Default to **both languages for every block**
  when the company is Québec/French-first: put the `fr-CA` version followed by the
  `en` version inside the same block, so any consultant can read it. If the user asks
  for a single language, use that language for every block in the file.
- Each block = a short intro ("We're trying to connect an AI assistant to read data
  from X, read-only") + the exact ask ("Can you confirm the URL and how we log in,
  read-only?").
- **Never** put secrets, passwords, or keys in the file. The blocks ask where to get
  them; they never contain them.

Use `templates/CONSULTANT_QUESTIONS.template.md` and render one block per system that
needs confirmation (typically: ERP, dashboard/MRP, CRM, docs, any on-prem app).

Example block (en):

> **To:** ERP consultant
>
> Hi — we're setting up an AI assistant to help our purchasing team, and we'd like it
> to read our ERP data (read-only, nothing can be changed). The ERP vendor says there's
> a secure way for outside tools to connect. Could you confirm the exact web address
> (URL) we should use and how we should log in so the assistant can only *read* data?

Example block (fr-CA):

> **À :** consultant ERP
>
> Bonjour — on met en place un assistant IA pour aider l'équipe des achats, et on
> aimerait qu'il puisse *lire* les données de l'ERP (en lecture seule, sans rien
> modifier). Le fournisseur de l'ERP mentionne une connexion sécurisée pour les outils
> externes. Pourriez-vous confirmer l'adresse (URL) exacte à utiliser et la façon de se
> connecter pour que l'assistant puisse uniquement *lire* les données ?

---

## Phase 10 — Agent-Ready Report (required Day 1 output)

Before closing, write **`AGENT_READY_REPORT.md`** using
`templates/AGENT_READY_REPORT.template.md`.

This is the **primary deliverable** for leaders — not the MCP kit.
The kit can follow the same day; the report must exist even if every MCP is blocked.

### Must include
1. One-line **verdict**: `PASS` | `CONDITIONAL` | `NOT READY` (rules in the template)
2. **Scorecard** of 10 checks with ✅ / ⚠️ / ❌ and **evidence** (no empty rows)
3. Tables: **reachable today** vs **blocked** (with owner + fix)
4. Explicit answer to: *Would an agent hit a wall on the first system that matters?*
5. One recommended next step a director can act on

### Checkmarks the skill must evaluate (do not skip)
| # | Check |
|---|---|
| 1 | Accounting / GL agent-reachable |
| 2 | Purchasing / inventory agent-reachable |
| 3 | Sales / CRM agent-reachable |
| 4 | Business files allowlisted / searchable |
| 5 | Chat/email: official MCP/plugin or scoped out |
| 6 | ≥1 read smoke test for primary workflow |
| 7 | Writes still off |
| 8 | Secrets ownership known |
| 9 | Blockers have owner + next step |
| 10 | Clear “fix before next pilot” list |

Map Class A/B → likely ✅/⚠️, Class C/D → ❌ for the systems in the primary workflow.
If inventory never saw a domain, mark ❌ or ⚠️ and say **missing from discovery** — do not invent access.

Show the report to the user and ask: *Does this match how you see the company?*

## Deliverables (always)
| File | Purpose |
|---|---|
| `inventory_raw.json` | Apps + tab URLs |
| `inventory_grouped.md` | Sorted / filtered |
| `discovery.json` | Confirmed questionnaire |
| `ACCESS_REPORT.md` | A/B/C/D + versions + hosting |
| `mcp_catalog.json` | official / community / custom |
| `mcp-servers/**` | Custom stubs |
| `SMOKE_TEST.md` | Results |
| `COWORKER_INSTALL_PROMPT.md` | Peer install |
| `CONSULTANT_QUESTIONS.md` | Copy-paste messages per software |
| `NEXT_WEEK_PLAN.md` | Single-workflow demo plan |

---

## Done means
- **`AGENT_READY_REPORT.md` written and shown** (verdict + all 10 checks filled)
- User confirmed systems map (not only agent guesses)
- Gaps (CRM/ERP/docs) explicitly asked if missing from inventory
- MCP search followed official → community → custom
- ≥1 MCP smoke-tested **or** clear blockers documented
- Coworker prompt ready to paste
- Consultant questions written, grouped by software, copy-paste ready, no jargon
- Writes still disabled

## Scripts in this skill
- `scripts/inventory_macos.sh` — macOS: running + installed apps, mounts, Finder target → JSON
- `scripts/browser_tabs_macos.sh` — macOS: Chrome/Edge/Safari/Arc tab URL+title
- `scripts/inventory_windows.ps1` — Windows: running + installed apps, mapped drives, Explorer target → JSON
- `scripts/browser_tabs_windows.ps1` — Windows: browser window titles (URLs unavailable) → JSON
- `scripts/merge_inventory.py` — merge `tabs.json` into `inventory_raw.json` (macOS + Windows)
- `scripts/filter_productivity.py` — group/filter heuristics (edit per locale)
