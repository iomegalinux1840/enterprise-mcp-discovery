# Enterprise MCP Discovery

**Discovery tool for enterprise system MCP builders.**

> **Before you buy another AI tool, answer one question: are you agent-ready?**  
> Not “do we have ChatGPT.” Is your data reachable by a normal AI agent — or locked in ERP screens, exports, and tribal knowledge?

Run this skill in **Claude** or **Codex**. It inventories your stack, checks what’s accessible, and produces a plain **Day 1 Agent-Ready Report**: what an agent can use today, what’s blocked, and what to fix before the next pilot.

Day 1 output isn’t a chatbot. It’s clarity a director can act on.

## Repo layout

```text
skills/
  enterprise-mcp-discovery/   # current skill (v0.3)
  …                           # future skills go here
```

## Skill: `enterprise-mcp-discovery` (v0.3)

| Phase | What happens |
|---|---|
| 0 | User opens daily work apps/tabs → says DONE |
| 1–2 | Inventory + browser tabs (macOS + Windows) |
| 3–4 | Filter → confirm questionnaire + gap-fill |
| 5 | Computer use for versions / SaaS vs on-prem |
| 6–7 | MCP search official → community → custom; install + smoke |
| 8 | Coworker install prompt |
| 9 | Consultant questions (copy-paste, grouped by software) |
| **10** | **`AGENT_READY_REPORT.md`** — verdict + 10 checkmarks |

### Day 1 primary deliverable

`AGENT_READY_REPORT.md` includes:

- Verdict: **PASS / CONDITIONAL / NOT READY**
- Scorecard: accounting, purchasing, sales/CRM, files, chat, smoke test, read-only, secrets, blockers, “fix before pilot”
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
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\inventory_windows.ps1 | Out-File -Encoding utf8 inventory_apps.json
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\browser_tabs_windows.ps1 | Out-File -Encoding utf8 inventory_tabs.json
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
