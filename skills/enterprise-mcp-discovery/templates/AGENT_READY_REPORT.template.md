# Agent-Ready System Report
Company: {{company}} | Department: {{department}} | Date: {{date}}
Sponsor: {{sponsor}} | Primary workflow: {{primary_workflow}}
Verdict: {{PASS / CONDITIONAL / NOT READY}}

## Executive summary
In five lines: what the agent can do today, the first wall it would hit, coverage
limits, the most consequential blocker and one recommended action for its owner.
Readiness applies to the named workflow, not the entire company.

## Systems and business data map
| Source ID | System / data location | Purpose and exact location (sanitized) | Owner | Required for workflow? | Observed / confirmed / documented / tested / blocked / unverified |
|---|---|---|---|---|---|
| | | | | | |

Include every confirmed department system and folder. Put unresolved leads in gaps.
Keep sensitive infrastructure details in the restricted technical appendix if needed.

## Evidence scorecard
Use ✅ verified, ⚠️ partial/untested, ❌ blocked/failed, or N/A with a reason.
Every row needs a source/test reference or a specific gap. No empty evidence cells.

| Check | Status | Evidence / limitation |
|---|---|---|
| Accounting data needed by workflow | | |
| Purchasing / inventory data needed by workflow | | |
| Sales / CRM data needed by workflow | | |
| Every required folder/library located, allowlisted and searchable | | |
| Required document reading/extraction/OCR demonstrated | | |
| Required email/chat and other sources accessible or explicitly out of scope | | |
| Every required source passed its intended read test | | |
| End-to-end primary-workflow read passed | | |
| Read-only permissions verified for the intended agent identity | | |
| Credential owner and secure retrieval procedure known | | |
| Freshness and authoritative data sources established | | |
| Blockers have accountable owners and actionable fixes | | |

## Verdict rules
- **PASS:** every workflow-required source (systems AND folders/libraries) has a
  successful intended read/search test, required extraction is demonstrated, the
  end-to-end read passes, read-only enforcement is verified, and credential ownership,
  scope and freshness expectations are established. Any required unknown prevents PASS.
- **CONDITIONAL:** a useful bounded pilot has a verified read-only path but explicit
  manual bridges, partial coverage or pending access tests remain. State exactly
  which reduced pilot is supported; never claim the full workflow works.
- **NOT READY:** an indispensable source has no demonstrated usable path and no
  verified bounded pilot exists, or read-only enforcement is failed/unverified.
- A verified export bridge can PASS if it meets the workflow's freshness and access
  needs. A connector class, installed package or documentation link alone cannot PASS.
- N/A is allowed only for sources irrelevant to the chosen workflow, with a reason.

## What an agent can use today
| Source ID | Available business data | Verified method and scope | Test reference / date | Limits / freshness |
|---|---|---|---|---|
| | | | | |

## Possible access, not yet verified
| Source ID | Documented method / source | Missing verification | Owner / next step |
|---|---|---|---|
| | | | |

## Blockers and discovery gaps
| Source ID or missing domain | Impact on workflow | Owner | Concrete fix | Priority |
|---|---|---|---|---|
| | | | | |

Call out denied/offline/truncated scans, missing URLs, remote systems not inspected,
unconfirmed folders, unsupported file formats and unavailable credentials.

## Recommended next action
One action, owner and expected result. Then list remaining fixes before the next pilot.

## Technical handoff
- DATA_LOCATIONS.md — exact data locations, ownership and scan coverage
- ACCESS_REPORT.md — per-source connection instructions and evidence
- discovery.json — structured systems and location register
- SMOKE_TEST.md — per-source and end-to-end verification
- inventory_grouped.md / folder_inventory.json — discovery evidence and limits
