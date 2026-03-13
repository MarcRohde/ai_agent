# M365 Scripts

This folder groups Microsoft 365 and Exchange-adjacent automation scripts.

## Scripts

| Script | Purpose |
|--------|---------|
| `Get-M365GraphAccessToken.ps1` | Acquire Graph access tokens using env cache, refresh token, Azure CLI, or device code flow |
| `Search-M365Knowledge.ps1` | Query Microsoft Graph search and return citation-friendly normalized results |
| `Get-ArchiveMessages.ps1` | Retrieve recent messages from the Archive folder |
| `Invoke-WorkIQMailAction.ps1` | Execute WorkIQ Mail MCP search/get/delete flows with confirmation, fallback handling, and post-delete verification |

## Usage Examples

```powershell
.\tools\scripts\M365\Get-M365GraphAccessToken.ps1
.\tools\scripts\M365\Search-M365Knowledge.ps1 -Query "Andis ODS dimCustomer"
.\tools\scripts\M365\Get-ArchiveMessages.ps1 -Top 10
.\tools\scripts\M365\Invoke-WorkIQMailAction.ps1 -Action search -Query "my last 5 emails from MCA ERP Support"
```

## WorkIQ Mail Notes

- Keep WorkIQ Mail `ItemID` values URL-encoded.
- `MoveMessage` may not be exposed by the current Mail MCP server; do not assume move-to-deleted semantics.
- For delete operations, verify the outcome with a follow-up `GetMessage` on the same `ItemID`.

## Related Workspace Scripts

Operational Exchange EWS scripts currently live in:

- `work-projects/scripts/Exchange/MailboxMove-EWS.ps1`
- `work-projects/scripts/Exchange/MailboxMove-EWS-User-Guide.md`
