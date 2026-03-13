# WorkIQ Mail MCP Recommendations

**Date:** 2026-03-12
**Based On:** Inbox retrieval and selective delete workflows executed through WorkIQ Mail MCP

---

## Header

- Purpose: Capture safe operational patterns and required guardrails for WorkIQ Mail MCP mutation workflows.
- Use when: Implementing mailbox search/get/delete/move-adjacent actions and related auth/bootstrap flows.
- Scope: `ai_agent` WorkIQ skills, prompts, scripts, and configuration.

---

## Content

## Lessons Learned

### 1. ItemID encoding must be preserved
- `DeleteMessage` and `GetMessage` expect URL-encoded ItemID values.
- Decoding `%2f` to `/` can break Graph segment parsing.
- Safe pattern: extract ItemID from OWA links and pass it unchanged.

### 2. Move-to-Deleted may not be supported
- Current tool list exposes `DeleteMessage` but not `MoveMessage`.
- User requests to "move to Deleted Items" require capability discovery first.
- If move is unavailable, fallback to delete should require explicit reconfirmation.

### 3. Delete verification should be mandatory
- `DeleteMessage` success alone is insufficient for operational confidence.
- Reliable pattern: call `GetMessage` with the same ItemID after delete.
- `not found` confirms removal from store.

### 4. Search output may require link parsing for IDs
- `SearchMessages` can return OWA citation links rather than explicit ItemID fields.
- Workflows should include a parse step for `ItemID=` from the OWA URL.

### 5. Environment variable presence is not auth readiness
- `WORKIQ_*` token variables can exist while MCP endpoints still return `401 Unauthorized`.
- Bootstrap and validation flows should separate three checks: env var presence, token refresh success, and endpoint authorization.
- Safe pattern: refresh tokens first, then run `Test-WorkIQAllMcp.ps1 -SkipToolCall -ContinueOnError` before task-specific work.

### 6. Canonical catalog should drive MCP configuration
- `config/work_iq_mcp/catalog.json` should remain the source of truth for WorkIQ server definitions.
- Regenerate `.vscode/mcp.json` from the catalog instead of editing the VS Code MCP config by hand.
- This reduces drift when adding servers or moving to a new machine.

### 7. Auth startup should resolve compatibility env vars
- Some tools expect `EXO_*` variables while others expect `MS_*` aliases.
- Startup scripts should resolve both names across `Process`, `User`, and `Machine` scope, then normalize them for the current session.
- Bootstrap should stamp both alias sets so auth flows remain portable across machines and scripts.

### 8. MCP testing must stay in one session
- For Agent365 MCP servers, `initialize`, `notifications/initialized`, `tools/list`, and `tools/call` should run in one script/process.
- Splitting the sequence across separate shell commands can lose the `Mcp-Session-Id` and produce misleading failures.
- Prefer the repo test harness scripts over ad hoc multi-command shell experiments.

---

## Recommended Library Updates

### Skill additions
- Add `skills/workiq_mail_operations/skill.md` for capability discovery, safe delete flow, and verification.

### Skill updates
- Expand `skills/workiq_mail_mcp/skill.md` with single-session harness guidance and capability-first execution.
- Expand `skills/dev_environment_bootstrap/skill.md` with WorkIQ env var aliasing, token refresh, and validation tiers.
- Expand `skills/oauth2_integration/skill.md` with token audience validation and stale-token troubleshooting for MCP endpoints.

### Prompt additions
- Add `prompts/templates/mail_action_request.md` to standardize action, target, fallback, and confirmation inputs.
- Update `prompts/system/default_system.md` with mailbox-specific destructive-action rules.

### Tooling additions
- Add `tools/scripts/M365/Invoke-WorkIQMailAction.ps1` to provide a safe wrapper around WorkIQ mail actions.

### Documentation updates
- Update WorkIQ rollout docs to explicitly document:
  - missing `MoveMessage`
  - hard-delete possibility
  - URL-encoded ItemID contract
- Update bootstrap/auth docs to explicitly document:
  - env var presence vs endpoint authorization
  - `EXO_*` and `MS_*` compatibility aliases
  - catalog-driven regeneration of `.vscode/mcp.json`
  - single-process MCP validation as the default test pattern
- Update tools and skill indexes so the new assets are discoverable.

---

## Action Items

- [x] Add skill file: `skills/workiq_mail_operations/skill.md`
- [x] Add prompt template: `prompts/templates/mail_action_request.md`
- [x] Update system prompt guardrails: `prompts/system/default_system.md`
- [x] Add script wrapper: `tools/scripts/M365/Invoke-WorkIQMailAction.ps1`
- [x] Update index docs: `skill_library.md`, `skills/README.md`, `tools/README.md`, `tools/scripts/M365/README.md`
- [x] Update WorkIQ docs/config: `config/work_iq_mcp/README.md`, `config/work_iq_mcp/catalog.json`
- [x] Update reusable skills with auth/bootstrap/session guidance: `skills/workiq_mail_mcp/skill.md`, `skills/dev_environment_bootstrap/skill.md`, `skills/oauth2_integration/skill.md`

---

## Impact Estimate

| Scenario | Time Saved | Quality Impact |
|----------|------------|----------------|
| Repeated sender-targeted mailbox cleanup | 20-30 minutes per run | Fewer wrong-target deletes via confirmation + preview |
| Move/delete requests under missing capabilities | 10-15 minutes per request | Lower risk through explicit fallback gate |
| Incident verification after delete | 5-10 minutes per operation | Higher confidence using GetMessage post-check |
| New-machine WorkIQ setup and validation | 20-40 minutes per setup | Fewer false-ready states caused by stale tokens or config drift |

---

## Notes

This recommendation set focuses on safety and repeatability for mailbox operations where tool capability surfaces can differ from user intent.

---

## Learning Log

- 2026-03-12 | Preserve URL-encoded ItemID values exactly; decoding can break downstream Graph parsing.
- 2026-03-12 | Capability discovery must occur before move-to-deleted workflows because MoveMessage may be unavailable.
- 2026-03-12 | Delete operations should be verified with a follow-up GetMessage call for operational confidence.
- 2026-03-12 | Search outputs may require parsing OWA links to extract ItemID values.
- 2026-03-12 | Token environment variables alone do not prove endpoint authorization readiness.
- 2026-03-12 | `catalog.json` should remain the canonical source for MCP server config and regeneration.
- 2026-03-12 | MCP test flows must run in one process/session to preserve session identity.
