# Enterprise MCP Discovery

**Discovery tool for enterprise system MCP builders.**

Help non-developers (and agents) map the apps and SaaS a company actually uses, confirm the stack, find **official → community → custom** MCP servers, scaffold what’s missing, smoke-test, and ship a **coworker install kit**.

Built for accounting / sales / purchasing / ERP / CRM kickstarts when Codex or Claude don’t ship a native plugin — including common Québec stacks (Acomba, Maestro, Business Central, SoftExpert, …).

## Repo layout

```text
skills/
  enterprise-mcp-discovery/   # v0.2 — this skill
  …                           # future skills go here
```

Each skill is a Codex/Claude-compatible folder (`SKILL.md` + helpers).

## Skill: `enterprise-mcp-discovery` (v0.2)

| Phase | What happens |
|---|---|
| 0 | User opens daily work apps/tabs → says DONE |
| 1 | Bash inventory (running/installed apps) |
| 2 | Browser tab **URL + title** (not passwords / full DOM) |
| 3 | Group & filter productivity vs noise |
| 4 | Pre-fill questionnaire → user confirms + gap-fill (CRM/ERP/docs) |
| 5 | Computer use for versions / SaaS vs on-prem |
| 6 | MCP search: **official → community → custom** |
| 7 | Install + smoke test (read-only default) |
| 8 | `COWORKER_INSTALL_PROMPT.md` for peer machines |

### Install in Codex

Copy the skill folder into your Codex skills directory:

```bash
cp -R skills/enterprise-mcp-discovery ~/.codex/skills/
```

Or clone this repo and point Codex at `skills/enterprise-mcp-discovery`.

### Quick inventory scripts (macOS)

```bash
cd skills/enterprise-mcp-discovery
bash scripts/inventory_macos.sh > /tmp/inventory_apps.json
bash scripts/browser_tabs_macos.sh > /tmp/inventory_tabs.json
# merge, then:
python3 scripts/filter_productivity.py < merged.json
```

## Principles

- Consent before scanning
- Read-only MCP tools by default
- Prefer configuring official MCPs over reinventing M365/Slack
- Export-folder bridges (Class B) are valid “next week” wins

## License

MIT — see [LICENSE](LICENSE).

## Author

Dave Girard ([@iomegalinux1840](https://github.com/iomegalinux1840))
