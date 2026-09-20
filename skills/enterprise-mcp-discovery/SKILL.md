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

## Hard rules
- **Consent first.** Before any inventory, ask the user to open daily work apps and
  explicitly allow scanning running apps + browser tab *URLs* (not password fields).
- **Read-only by default** for all generated MCP tools until a later write phase.
- **Never invent credentials.** Mark `needs_secure_secret`; use Keychain/1Password/secure forms.
- **Never claim MCP works** until a smoke test passes on this machine.
- Prefer **narrow tools** over arbitrary SQL/shell.
- One **primary workflow** for the first kit (e.g. late POs), not boil-the-ocean.
- Do **not** scrape full page HTML/body content via bash unless the user opts in and
  the site is non-sensitive; default = **URLs + titles only**.

---

## Phase 0 — Prep (user action)
Tell the user (fr-CA or en matching them):

> Open every app and browser tab you use for work on a normal day (ERP, email,
> chat, Excel, banking portal, etc.). Leave them open. Say **DONE** when ready.
> I will inventory running apps and browser tab addresses (not passwords).

Wait for DONE. If they refuse scanning, fall back to manual questionnaire only.

---

## Phase 1 — Passive inventory (bash / OS)
Run the bundled scripts (or equivalent) on **their** machine:

```bash
bash scripts/inventory_macos.sh > inventory_raw.json
```

Capture:
1. **Running GUI apps** (`osascript` / `lsappinfo` / `ps`)
2. **Installed Applications** (name only under `/Applications`, `~/Applications`)
3. **Browser tabs** — URL + title for Chrome / Edge / Arc / Safari via AppleScript
   (see `scripts/browser_tabs_macos.sh`). If a browser blocks scripting, note
   `tabs_unavailable` and ask them to paste the address bar list.

Write `inventory_raw.json`:
```json
{
  "running_apps": [{"name": "...", "bundle_id": "..."}],
  "installed_apps": ["..."],
  "browser_tabs": [{"browser": "Chrome", "title": "...", "url": "..."}],
  "collected_at": "ISO-8601"
}
```

### Limits to tell the user honestly
- Bash/AppleScript gets **URLs and titles**, not full page DOM or “what the form says”.
- Deeper UI (version dialogs, About boxes) = **Phase 5 computer use**, not bash.
- Incognito / some enterprise browsers may hide tabs.

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
| Docs / files | SharePoint, Finder NAS, Google Drive, OneDrive |
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

## Phase 9 — Agent-Ready Report (required Day 1 output)

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
| `NEXT_WEEK_PLAN.md` | Single-workflow demo plan |

---

## Done means
- **`AGENT_READY_REPORT.md` written and shown** (verdict + all 10 checks filled)
- User confirmed systems map (not only agent guesses)
- Gaps (CRM/ERP/docs) explicitly asked if missing from inventory
- MCP search followed official → community → custom
- ≥1 MCP smoke-tested **or** clear blockers documented
- Coworker prompt ready to paste
- Writes still disabled

## Scripts in this skill
- `scripts/inventory_macos.sh` — running + installed apps → JSON lines
- `scripts/browser_tabs_macos.sh` — Chrome/Edge/Safari/Arc tab URL+title
- `scripts/filter_productivity.py` — group/filter heuristics (edit per locale)
