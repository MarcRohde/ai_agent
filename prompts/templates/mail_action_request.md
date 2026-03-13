# Prompt Template: Mail Action Request

## Purpose
Standardize mailbox actions through WorkIQ Mail MCP with explicit safety checks for destructive operations.

## Template

```text
Execute a WorkIQ Mail operation using the parameters below.

Action: {{action}}                        # search | get | delete
Query: {{query}}                          # required for search
ItemID: {{item_id}}                       # required for get/delete; keep URL-encoded
OWAUrl: {{owa_url}}                       # optional alternative source for ItemID
MoveToDeletedItems: {{move_to_deleted_items}}   # true | false
AllowDeleteFallback: {{allow_delete_fallback}}  # true | false
ConfirmDelete: {{confirm_delete}}                # true | false
ConfirmDeleteFallback: {{confirm_delete_fallback}} # true | false
Top: {{top}}                              # search results limit

Instructions:
1. Run capability discovery (`tools/list`) and confirm available mail tools.
2. Validate required fields for the selected action.
3. Preserve URL-encoded ItemID exactly as provided.
4. If only `OWAUrl` is provided, extract the `ItemID` query parameter without decoding it.
5. For delete actions, preview target details using GetMessage before mutation.
6. If move is requested but MoveMessage is unavailable:
   - stop unless AllowDeleteFallback is true and ConfirmDeleteFallback is true.
7. Execute action.
8. For DeleteMessage, verify via follow-up GetMessage on same ItemID.
9. Return status, operation used, fallback usage, and warnings.
```

## Variables

| Variable | Description |
|----------|-------------|
| `{{action}}` | `search`, `get`, or `delete` |
| `{{query}}` | Natural-language search request |
| `{{item_id}}` | URL-encoded ItemID from OWA/citation link |
| `{{owa_url}}` | Optional OWA message URL containing `ItemID=` |
| `{{move_to_deleted_items}}` | Request move behavior when supported |
| `{{allow_delete_fallback}}` | Allow hard-delete fallback when move is unavailable |
| `{{confirm_delete}}` | Explicit confirmation for delete intent |
| `{{confirm_delete_fallback}}` | Explicit reconfirmation for move->delete fallback |
| `{{top}}` | Maximum search results to return |

## Output Format

```markdown
## Mail Action Result

### Request
- Action: `{action}`
- Query: `{query_or_n/a}`
- ItemID: `{item_id_or_n/a}`

### Outcome
- Status: `Success|Partial|Failed`
- Operation Used: `{SearchMessages|GetMessage|MoveMessage|DeleteMessage}`
- Fallback Used: `{Yes|No}`

### Verification
- {post-delete verification or reason not applicable}

### Warnings
- {capability gaps, encoding concerns, or data-loss warnings}
```
