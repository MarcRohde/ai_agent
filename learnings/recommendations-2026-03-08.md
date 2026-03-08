# M365 and Exchange Script Lessons and Recommendations

**Date:** 2026-03-08
**Based On:** M365 Graph knowledge integration, token acquisition hardening, archive retrieval, and Playwright MCP bootstrap updates

---

## Lessons Learned

### Reliability Lessons
- Token flows should always use ordered fallback paths: cached access token, refresh token, Azure CLI, and device code.
- Script behavior improves significantly when locale-safe Graph endpoints are used (for example `/me/mailFolders/archive`).
- Strict mode catches hidden null-handling issues early; null-safe error parsing is required around API exceptions.
- Input validation on parameters (for example `Top` range checks) prevents malformed requests and noisy failures.

### Authentication Lessons
- JWT parsing must handle base64url payload encoding (`-` and `_`) to avoid false negatives in token validation.
- Refresh token reuse enables autonomous repeated runs and minimizes user interruption.
- Error messaging should map directly to recovery steps (for example when Azure CLI auth is blocked by tenant policy).

### UX and Operability Lessons
- Auto-opening browser/device code with clipboard copy reduces friction in interactive auth flows.
- Grouping related scripts under a domain folder (`tools/scripts/M365`) improves discoverability and maintenance.
- Consistent script paths in docs and skills are critical after refactors; stale paths quickly cause execution drift.

---

## New Updates to Skill Library, Prompts, and Tools

### Skill Library Updates
- Added a dedicated M365 knowledge retrieval skill: `skills/m365_graph_knowledge/skill.md`.
- Added Knowledge Retrieval category entries in `skill_library.md`.

### Prompt Updates
- Updated system guidance in `prompts/system/default_system.md` to favor Graph-first retrieval and citation-backed responses.

### Tooling and Script Updates
- Added/updated M365 scripts:
  - `tools/scripts/M365/Get-M365GraphAccessToken.ps1`
  - `tools/scripts/M365/Search-M365Knowledge.ps1`
  - `tools/scripts/M365/Get-ArchiveMessages.ps1`
- Added M365 script grouping documentation: `tools/scripts/M365/README.md`.
- Added Playwright MCP bootstrap support in `tools/scripts/Bootstrap-DevEnvironment.ps1`.
- Added MCP server configuration in `.vscode/mcp.json`.

---

## Recommendations

1. Add a small helper function shared across M365 scripts to reacquire token on 401 and retry once.
2. Add a lightweight smoke test script that validates token acquisition, Graph search, and archive retrieval end-to-end.
3. Introduce a script path constant or config entry so moves/refactors require fewer manual doc updates.
4. Keep Exchange EWS operational scripts synchronized with this folder strategy in a future consolidation pass.

---

## Next Steps

- [ ] Add retry-on-401 helper for M365 scripts.
- [ ] Add integration smoke test for M365 script chain.
- [ ] Evaluate moving operational Exchange EWS scripts into `tools/scripts/M365/Exchange/`.
