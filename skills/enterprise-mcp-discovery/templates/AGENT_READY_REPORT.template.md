# Agent-Ready Report (Day 1)

| Field | Value |
|---|---|
| **Company** | {{company}} |
| **Date** | {{date}} |
| **Primary workflow** | {{primary_workflow}} |
| **Sponsor** | {{sponsor}} |
| **Verdict** | {{PASS / CONDITIONAL / NOT READY}} |

## The only question that matters

**Are you agent-ready?**  
Not “do we have ChatGPT / Copilot.”  
Is your data reachable by a normal AI agent — or locked in ERP screens, exports, and tribal knowledge?

## Executive summary (5 lines max)
{{summary}}

## Scorecard (checkmarks)

Use ✅ / ⚠️ / ❌ only. Every row must have evidence.

| # | Check | Status | Evidence |
|---|---|---|---|
| 1 | **Accounting / GL** reachable by an agent (API, SQL view, or validated export path) | {{ }} | |
| 2 | **Purchasing / inventory** reachable the same way | {{ }} | |
| 3 | **Sales / orders / CRM** reachable the same way | {{ }} | |
| 4 | **Business files** (PO/invoice PDFs, SharePoint/NAS) searchable under an allowlist | {{ }} | |
| 5 | **Chat / email** either has an official MCP/plugin **or** is explicitly out of week-1 scope | {{ }} | |
| 6 | At least **one** end-to-end read smoke test passed for the primary workflow | {{ }} | |
| 7 | **Write actions disabled** (read-only) until a later approved phase | {{ }} | |
| 8 | Secrets path known (who owns credentials) — values not pasted into chat | {{ }} | |
| 9 | Blockers have an owner + next step (IT / vendor / process) | {{ }} | |
| 10 | Director can name **what to fix before the next AI pilot** | {{ }} | |

### Verdict rules
- **PASS:** checks 1–3 that matter for the workflow are ✅, check 6 ✅, check 7 ✅
- **CONDITIONAL:** workflow partially reachable (e.g. export bridge only) — pilot OK with limits
- **NOT READY:** the first system that matters for the workflow is ❌ (UI-only / no access path)

## What an agent can use **today**
| System | Domain | Access path | Class (A/B/C/D) | MCP status |
|---|---|---|---|---|
| | | | | |

## What’s **blocked**
| System | Why blocked | Owner | Fix before next pilot |
|---|---|---|---|
| | | | |

## Gaps called out in discovery
- CRM: {{found / missing / N/A}}
- ERP / accounting: {{ }}
- Document / ECM vault: {{ }}
- Other: {{ }}

## Recommended next step (one sentence)
{{e.g. Wire read-only MCP for late POs this week; defer CRM until export path exists.}}

## Appendix
- Full matrix: `ACCESS_REPORT.md`
- Inventory: `inventory_grouped.md`
- MCP catalog: `mcp_catalog.json`
- Smoke tests: `SMOKE_TEST.md`
