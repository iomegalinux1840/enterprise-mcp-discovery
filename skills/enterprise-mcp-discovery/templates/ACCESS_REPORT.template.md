# Agent access register — {{company}} / {{department}}
Workflow: {{primary_workflow}} | Checked: {{date}} | Sponsor: {{sponsor}}

## Coverage
List all confirmed systems and data locations. Distinguish department discovery
coverage from workflow-required access. Record missing/unconfirmed sources explicitly.

| Source ID | System or folder | Business entities / purpose | Required? | Class A/B/C/D | Verification state | Blocker / owner |
|---|---|---|---|---|---|---|
| | | | | | | |

Class A = supported programmatic access; B = controlled file/export bridge;
C = UI-only/manual; D = out of scope with reason. Class is not proof of access.
Verification states: observed, user_confirmed, documented, tested, blocked, unverified.

## Access instructions — repeat for each source
- Source ID, product/version/hosting or storage type:
- Exact sanitized endpoint/path/tenant and data entities:
- Recommended method and why; alternatives considered:
- Vendor documentation URL, applicable edition/version, checked date:
- Official/community/custom connector provenance, maintenance/license requirements:
- Agent identity, authentication method, secure credential reference and owner:
- Minimum read permissions / allowlisted roots / excluded locations:
- Setup prerequisites, licensing/admin needs and ordered connection steps:
- Read/search/extraction steps; pagination, formats and OCR needs:
- Freshness/export/sync schedule and authoritative source:
- Evidence of read-only enforcement (or unverified):
- Test ID/date, expected vs actual aggregate result and coverage limits:
- Remaining blocker, accountable owner and next action:

## End-to-end workflow test
Required source IDs, tested agent identity, sanitized steps, result, freshness and
remaining manual steps. Link SMOKE_TEST.md; do not include raw customer/invoice data.

## Handoff
What another agent can use now, what needs owner action, and what must be revalidated
on another workstation. Never include credentials or imply untested access works.
