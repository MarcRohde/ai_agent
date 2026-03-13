# Skill: WorkIQ Mail Operations

## Description
Use WorkIQ Mail MCP to search, inspect, and delete messages with strict safeguards for destructive actions. This skill performs capability discovery first, preserves URL-encoded ItemIDs, and verifies delete outcomes.

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| `action` | Yes | `search`, `get`, or `delete` |
| `query` | Conditional | Required for `search`; natural-language mail query |
| `item_id` | Conditional | Required for `get` and `delete` unless `owa_url` is provided; URL-encoded message ItemID |
| `owa_url` | Conditional | Optional OWA message URL containing `ItemID=` for `get` and `delete` |
| `move_to_deleted_items` | No | If `true`, prefer `MoveMessage` when available |
| `allow_delete_fallback` | No | If `true`, allow fallback to `DeleteMessage` when move is unavailable |
| `confirm_delete` | No | Required `true` for delete actions |
| `confirm_delete_fallback` | No | Required `true` when fallback from move to delete is used |
| `top` | No | Search result count (default 10, max 50) |

## Preconditions
1. Confirm `WORKIQ_MAIL_TOKEN` is set and mail MCP endpoint is reachable.
2. Run tool discovery (`tools/list`) and cache capability names.
3. Preserve ItemID encoding exactly as supplied (do not decode `%2f`, `%2b`, or `%3d`).

## Steps

1. **Discover capabilities**
   - Call `tools/list` and check for `SearchMessages`, `GetMessage`, `DeleteMessage`, and `MoveMessage`.
   - If `move_to_deleted_items=true` and `MoveMessage` is missing, mark fallback path as required.

2. **Validate inputs**
   - `search`: require non-empty `query`.
   - `get` and `delete`: require non-empty `item_id` or `owa_url`.
   - If `owa_url` is supplied, extract the `ItemID` query parameter and keep it URL-encoded.
   - Reject malformed/decoded ItemIDs that contain raw path separators likely introduced by decoding.

3. **Execute non-destructive action**
   - `search`: call `SearchMessages` and return message candidates, including OWA links when present.
   - `get`: call `GetMessage` for target metadata and preview.

4. **Preview delete target**
   - For `delete`, call `GetMessage` first and present sender/subject/received time.
   - Require explicit confirmation (`confirm_delete=true`) before delete operation.

5. **Execute delete strategy**
   - If `move_to_deleted_items=true` and `MoveMessage` exists, attempt move.
   - If move requested but unavailable:
     - Require `allow_delete_fallback=true`.
     - Require `confirm_delete_fallback=true`.
     - Execute `DeleteMessage` only after both checks pass.
   - If move not requested, execute `DeleteMessage` directly after `confirm_delete=true`.

6. **Verify result**
   - For `DeleteMessage`, call `GetMessage` with the same ItemID.
   - Treat `not found` as success confirmation.
   - Report that Deleted Items visibility may vary by backend behavior/indexing.

7. **Return status**
   - Include operation used (`MoveMessage` or `DeleteMessage`), fallback usage, and verification result.

## Output

```markdown
## WorkIQ Mail Operation Result

### Request
- Action: `{action}`
- Target ItemID: `{item_id_or_n/a}`

### Status
- Result: `Success|Partial|Failed`
- Operation Used: `{SearchMessages|GetMessage|MoveMessage|DeleteMessage}`
- Fallback Used: `{Yes|No}`

### Details
- {summary of results or retrieved message metadata}

### Verification
- {post-delete GetMessage outcome or reason not applicable}

### Warnings
- {encoding, capability, or data-loss warnings if any}
```

## Safety Guardrails
- Never perform `delete` without explicit confirmation.
- Never assume move-to-deleted is supported; verify capability first.
- Never decode URL-encoded ItemIDs before `GetMessage` or `DeleteMessage`.
- Never bulk-delete based only on a broad search without explicit per-target confirmation.
- Always verify deletion by follow-up `GetMessage` on the same ItemID.

## Referenced Prompts
- `prompts/templates/mail_action_request.md`

## Referenced Tools
- `tools/scripts/M365/Invoke-WorkIQMailAction.ps1`
- WorkIQ Mail MCP tools: `SearchMessages`, `GetMessage`, `DeleteMessage` (and `MoveMessage` if available)

## Tags
`workiq`, `m365`, `mail`, `operations`, `destructive-action`, `verification`
