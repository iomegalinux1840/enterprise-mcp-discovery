# Enterprise MCP Discovery

**Discovery tool for enterprise system MCP builders.**

> **Before you buy another AI tool, answer one question: are you agent-ready?**  
> Not “do we have ChatGPT.” Is your data reachable by a normal AI agent — or locked in ERP screens, exports, and tribal knowledge?

Run this skill in **Claude** or **Codex**. It inventories your stack, checks what’s accessible, and produces a plain **Day 1 Agent-Ready Report**: what an agent can use today, what’s blocked, and what to fix before the next pilot.

Day 1 output isn’t a chatbot. It’s clarity a director can act on.

## Repo layout

```text
skills/
  enterprise-mcp-discovery/   # current skill (v0.4)
  …                           # future skills go here
```

## Skill: `enterprise-mcp-discovery` (v0.4)

| Phase | What happens |
|---|---|
| 1 | Consent, work apps/tabs/open folders, metadata inventory |
| 2 | Confirm systems; locate business folders and run bounded metadata scan |
| 3 | Identify versions; research APIs, databases, exports, files and connectors |
| 4 | Verify each required source and an end-to-end workflow read |
| 5 | Complete Agent-Ready Report, data-location map and technical access register |
| 6 | Optional connector installation and coworker kit when requested |

### Day 1 primary deliverable

`AGENT_READY_REPORT.md` includes:

- Verdict: **PASS / CONDITIONAL / NOT READY**
- Evidence scorecard covering every required system and folder, document extraction, freshness, read-only permissions and end-to-end reads
- Tables: reachable today vs blocked (owner + next step)

Technical detail lives in `ACCESS_REPORT.md`; leaders read the Agent-Ready Report first.

### Install in Codex

```bash
cp -R skills/enterprise-mcp-discovery ~/.codex/skills/
```

### Quick inventory scripts (macOS + Windows)

macOS:

```bash
cd skills/enterprise-mcp-discovery
bash scripts/inventory_macos.sh > /tmp/inventory_apps.json
bash scripts/browser_tabs_macos.sh > /tmp/inventory_tabs.json
python3 scripts/merge_inventory.py /tmp/inventory_apps.json /tmp/inventory_tabs.json /tmp/inventory_apps.json
```

Windows (PowerShell 5.1 or newer):

```powershell
cd skills\enterprise-mcp-discovery
powershell -NoProfile -File scripts\inventory_windows.ps1 | Out-File -Encoding utf8 inventory_apps.json
powershell -NoProfile -File scripts\browser_tabs_windows.ps1 | Out-File -Encoding utf8 inventory_tabs.json
python scripts\merge_inventory.py inventory_apps.json inventory_tabs.json inventory_apps.json
```

On Windows, browser URLs are not exposed to PowerShell, so the tab script captures
titles only and asks the user to paste the address-bar list.

## Principles

- Consent before scanning
- Read-only MCP tools by default
- Prefer official MCPs over reinventing M365/Slack
- Export-folder bridges (Class B) are valid week-1 wins

## License

MIT — see [LICENSE](LICENSE).

## Author

Dave Girard ([@iomegalinux1840](https://github.com/iomegalinux1840))

## Folder discovery and complete handoff

Inventory finds mounted shares, open folders and common local/cloud root candidates.
After the user confirms scan roots and exclusions, run metadata-only discovery:

```bash
python3 scripts/discover_folders.py --root "/approved/department" --exclude "/approved/department/HR" --max-depth 3 --max-entries 2000 --output folder_inventory.json
```

Run from the skill directory; put the output outside scanned roots. This inventories
folder paths, extension counts, sizes and modification ranges without opening file
contents. It skips links and detectable Windows cloud placeholders, and reports
errors/truncation. Cloud-only libraries need supported metadata API/UI discovery.

`DATA_LOCATIONS.md` records exact locations and ownership. `ACCESS_REPORT.md` records
per-source access steps, permissions, vendor references, freshness and test evidence.
`AGENT_READY_REPORT.md` distinguishes verified access from documented possibilities.
PASS requires all workflow-required sources, including folders, to pass intended
read tests and a read-only end-to-end workflow test. Connector installation is optional.

## Validation

```bash
python3 -m unittest discover -s tests -v
```

Tests use synthetic data and temporary folders; they do not scan the workstation.
Windows scripts require native Windows validation; Python tests cover BOM input,
folder propagation, URL sanitation, bounded traversal and error reporting.
