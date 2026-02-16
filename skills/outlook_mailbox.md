# Skill: Outlook Mailbox

## Description
Access and interact with the user's Outlook mailbox via Microsoft Graph API. Supports reading, searching, sending, replying to, and summarizing emails. Uses PowerShell with `Microsoft.Graph` modules or direct REST calls with a cached access token.

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| `operation` | Yes | The mailbox operation: "read", "search", "send", "reply", "summarize", "list-folders" |
| `count` | No | Number of emails to retrieve (default: 10, max: 50) |
| `folder` | No | Mail folder to target (default: "Inbox"). Examples: "Inbox", "SentItems", "Drafts", "Archive" |
| `query` | No | Search query for `search` operation (searches subject, body, sender) |
| `message_id` | No | Specific message ID for `reply` or single-message operations |
| `to` | No | Recipient email address(es) for `send` / `reply` |
| `subject` | No | Email subject for `send` |
| `body` | No | Email body for `send` / `reply` (supports plain text or HTML) |
| `summary_scope` | No | For `summarize`: "today", "unread", "last-week", or a custom date range |

## Prerequisites

### Authentication Setup (One-Time)
The helper script uses **Microsoft Graph PowerShell SDK** for authentication. Before first use:

1. **Install the module** (if not already installed):
   ```powershell
   Install-Module Microsoft.Graph -Scope CurrentUser
   ```

2. **Connect with required scopes**:
   ```powershell
   Connect-MgGraph -Scopes "Mail.Read", "Mail.Send", "Mail.ReadWrite"
   ```
   This opens a browser for interactive login and caches the token.

3. **Verify connection**:
   ```powershell
   Get-MgContext
   ```

> **Note**: Token expires after ~1 hour. Re-run `Connect-MgGraph` if you get 401 errors.

### Alternative: App Registration (Unattended)
For automated/recurring use, register an app in Azure AD:
1. Go to [Azure Portal → App registrations](https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationsListBlade).
2. Register a new app with **Mail.Read**, **Mail.Send** delegated permissions.
3. Store the Client ID and Tenant ID in environment variables:
   ```
   OUTLOOK_CLIENT_ID=<your-client-id>
   OUTLOOK_TENANT_ID=<your-tenant-id>
   ```

## Steps

### Operation: `read`
1. Ensure Microsoft Graph connection is active (run `Get-MgContext`, reconnect if needed).
2. Invoke the helper script:
   ```powershell
   & tools/scripts/outlook_mailbox.ps1 -Operation Read -Count {{count}} -Folder {{folder}}
   ```
3. Parse the output and present emails in a readable table.

### Operation: `search`
1. Ensure Microsoft Graph connection is active.
2. Invoke the helper script with a search query:
   ```powershell
   & tools/scripts/outlook_mailbox.ps1 -Operation Search -Query "{{query}}" -Count {{count}} -Folder {{folder}}
   ```
3. Present matching emails with subject, sender, date, and a snippet of the body.

### Operation: `send`
1. Confirm with the user before sending (show To, Subject, Body preview).
2. Invoke the helper script:
   ```powershell
   & tools/scripts/outlook_mailbox.ps1 -Operation Send -To "{{to}}" -Subject "{{subject}}" -Body "{{body}}"
   ```
3. Report success or failure.

### Operation: `reply`
1. Fetch the original message by ID to show context.
2. Confirm the reply content with the user.
3. Invoke the helper script:
   ```powershell
   & tools/scripts/outlook_mailbox.ps1 -Operation Reply -MessageId "{{message_id}}" -Body "{{body}}"
   ```

### Operation: `summarize`
1. Fetch emails matching the scope (today, unread, last week, etc.).
2. For each email, extract: sender, subject, date, key points from body.
3. Generate a concise summary grouped by sender or topic.
4. Present in the output format below.

### Operation: `list-folders`
1. Invoke the helper script:
   ```powershell
   & tools/scripts/outlook_mailbox.ps1 -Operation ListFolders
   ```
2. Display folder names with unread counts.

## Output

### For `read` / `search`

```markdown
## Inbox — {{count}} Messages

| # | From | Subject | Date | Unread |
|---|------|---------|------|--------|
| 1 | sender@example.com | Re: Project Update | 2026-02-16 09:30 | ✉️ |
| 2 | boss@company.com | Q1 Planning | 2026-02-15 16:00 | |

### Message Preview ({{selected}})
**From**: sender@example.com
**Date**: 2026-02-16 09:30
**Subject**: Re: Project Update

{{body_preview — first 500 chars}}
```

### For `send`

```markdown
## Email Sent ✅
**To**: {{to}}
**Subject**: {{subject}}
**Status**: Sent successfully at {{timestamp}}
```

### For `summarize`

```markdown
## Email Summary — {{scope}}

### Key Highlights
- 📩 **{{count}}** emails in scope, **{{unread}}** unread
- 🔴 **Action required**: {{list of emails needing response}}
- 📋 **FYI only**: {{list of informational emails}}

### By Sender
#### sender@example.com (3 emails)
- **Project Update** — Requesting feedback on design doc by Friday
- **Meeting Notes** — Shared notes from standup, no action needed
- **Build Failure** — CI pipeline failed on main, needs investigation

#### boss@company.com (1 email)
- **Q1 Planning** — Asked for team capacity estimates by EOD Tuesday
```

### For `list-folders`

```markdown
## Mail Folders

| Folder | Total | Unread |
|--------|-------|--------|
| Inbox | 1,234 | 12 |
| Sent Items | 890 | 0 |
| Drafts | 3 | 0 |
| Archive | 5,678 | 0 |
```

## Error Handling

| Error | Resolution |
|-------|------------|
| "Not connected to Microsoft Graph" | Run `Connect-MgGraph -Scopes "Mail.Read","Mail.Send"` |
| "Insufficient privileges" | Reconnect with required scopes: `Mail.Read`, `Mail.Send`, `Mail.ReadWrite` |
| "Token expired" | Run `Connect-MgGraph` again to refresh |
| "Message not found" | Verify the message ID; it may have been deleted or moved |

## Security Notes
- **Never log or display email bodies in full** unless the user explicitly asks.
- **Confirm before sending** — always show a preview before `send` or `reply`.
- **Tokens are user-scoped** — only the authenticated user's mailbox is accessible.
- **No credentials stored in this repo** — authentication is handled by Microsoft Graph SDK.

## Referenced Prompts
- `prompts/system/default_system.md`

## Referenced Tools
- `tools/scripts/outlook_mailbox.ps1`

## Tags
`outlook`, `email`, `microsoft-graph`, `productivity`, `communication`
