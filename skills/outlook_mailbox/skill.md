# Skill: Outlook Mailbox

## Description
Access and interact with the user's Outlook mailbox via a **Microsoft Graph MCP server**. Supports reading, searching, sending, replying to, and summarizing emails. The agent invokes MCP tools directly — no PowerShell scripts or local modules are required.

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

### MCP Server Setup
This skill requires a Microsoft Graph MCP server registered in your VS Code MCP configuration. The server handles OAuth authentication and exposes mail operations as MCP tools.

#### Option A: Community MCP Server (Recommended)
Add one of the following to your VS Code `settings.json` or `.vscode/mcp.json`:

```jsonc
// .vscode/mcp.json
{
  "servers": {
    "outlook": {
      "command": "npx",
      "args": ["-y", "@nicekid1/outlook-email-mcp"],
      "env": {
        "MICROSOFT_CLIENT_ID": "<your-client-id>",
        "MICROSOFT_CLIENT_SECRET": "<your-client-secret>",
        "MICROSOFT_TENANT_ID": "<your-tenant-id>"
      }
    }
  }
}
```

#### Option B: Custom MCP Server via Microsoft Graph Toolkit
Use a self-hosted MCP server that wraps Microsoft Graph REST APIs:

```jsonc
// .vscode/mcp.json
{
  "servers": {
    "msgraph": {
      "command": "node",
      "args": ["path/to/msgraph-mcp-server/index.js"],
      "env": {
        "AZURE_CLIENT_ID": "<your-client-id>",
        "AZURE_TENANT_ID": "<your-tenant-id>",
        "AZURE_CLIENT_SECRET": "<your-client-secret>"
      }
    }
  }
}
```

#### Azure App Registration (Required for Both Options)
1. Go to [Azure Portal → App registrations](https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationsListBlade).
2. Register a new app with the following **delegated** permissions:
   - `Mail.Read`
   - `Mail.Send`
   - `Mail.ReadWrite`
3. Under **Certificates & secrets**, create a client secret.
4. Under **Authentication**, add `http://localhost` as a redirect URI.
5. Copy the Client ID, Tenant ID, and Client Secret into the MCP server configuration above.

> **Note**: The MCP server manages token refresh automatically. No manual `Connect-MgGraph` calls are needed.

### Discovering Available MCP Tools
Before first use, run `tool_search_tool_regex` with pattern `mcp_outlook|mcp_msgraph` to discover the exact tool names exposed by your configured MCP server. Common tool names include:

| Expected MCP Tool | Purpose |
|-------------------|---------|
| `mcp_outlook_list_emails` / `mcp_msgraph_list_messages` | Read emails from a folder |
| `mcp_outlook_search_emails` / `mcp_msgraph_search_messages` | Search emails by query |
| `mcp_outlook_send_email` / `mcp_msgraph_send_mail` | Send a new email |
| `mcp_outlook_reply_email` / `mcp_msgraph_reply_to_message` | Reply to an email |
| `mcp_outlook_list_folders` / `mcp_msgraph_list_mail_folders` | List mail folders |
| `mcp_outlook_get_email` / `mcp_msgraph_get_message` | Get a single email by ID |

> Adapt the tool names in the steps below to match what `tool_search_tool_regex` returns for your MCP server.

## Steps

### Step 0: Discover MCP Tools (Every Session)
1. Use `tool_search_tool_regex` with pattern `mcp_outlook|mcp_msgraph` to load the available MCP mail tools.
2. Note the exact tool names returned — use these in the steps below.
3. If no tools are found, verify the MCP server is configured and running (see Prerequisites).

### Operation: `read`
1. Call the MCP **list emails** tool with parameters:
   - `folder`: `{{folder}}` (default: "Inbox")
   - `count` / `top`: `{{count}}` (default: 10)
   - `orderBy`: `receivedDateTime desc`
   - `select`: `id,subject,from,receivedDateTime,isRead,bodyPreview`
2. Parse the returned JSON array of messages.
3. Present emails in a readable table (see Output section).

### Operation: `search`
1. Call the MCP **search emails** tool with parameters:
   - `query`: `{{query}}`
   - `folder`: `{{folder}}`
   - `count` / `top`: `{{count}}`
2. Present matching emails with subject, sender, date, and a snippet of the body.

### Operation: `send`
1. **Confirm with the user** before sending — show To, Subject, and Body preview.
2. Call the MCP **send email** tool with parameters:
   - `to`: `{{to}}`
   - `subject`: `{{subject}}`
   - `body`: `{{body}}`
   - `contentType`: "Text" or "HTML"
3. Report success or failure.

### Operation: `reply`
1. Call the MCP **get email** tool with `messageId`: `{{message_id}}` to fetch context.
2. Show the original message details and **confirm the reply** with the user.
3. Call the MCP **reply email** tool with parameters:
   - `messageId`: `{{message_id}}`
   - `comment` / `body`: `{{body}}`

### Operation: `summarize`
1. Call the MCP **list emails** tool with a filter matching the scope:
   - `today`: filter `receivedDateTime ge <today-start-UTC>`
   - `unread`: filter `isRead eq false`
   - `last-week`: filter `receivedDateTime ge <7-days-ago-UTC>`
2. For each email, extract: sender, subject, date, key points from body preview.
3. Generate a concise summary grouped by sender or topic.
4. Present in the output format below.

### Operation: `list-folders`
1. Call the MCP **list folders** tool.
2. Display folder names with total item counts and unread counts.

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
| No MCP tools found (`tool_search_tool_regex` returns nothing) | Verify the MCP server is configured in `.vscode/mcp.json` and VS Code has loaded it |
| "Unauthorized" / 401 | Check that the Azure App Registration has the correct permissions and the client secret is valid |
| "Insufficient privileges" / 403 | Ensure `Mail.Read`, `Mail.Send`, `Mail.ReadWrite` delegated permissions are granted and admin-consented |
| MCP server crashes or times out | Check server logs; restart VS Code to reload MCP servers |
| "Message not found" | Verify the message ID; it may have been deleted or moved |

## Security Notes
- **Never log or display email bodies in full** unless the user explicitly asks.
- **Confirm before sending** — always show a preview before `send` or `reply`.
- **Tokens are user-scoped** — only the authenticated user's mailbox is accessible.
- **No credentials stored in this repo** — authentication is managed by the MCP server and Azure AD.
- **Client secrets** should be stored in environment variables or a secrets manager, never committed to source control.

## Referenced Prompts
- `prompts/system/default_system.md`

## Referenced Tools
- MCP server: Microsoft Graph / Outlook MCP server (see Prerequisites for configuration)
- `tool_search_tool_regex` — used to discover available MCP mail tools at runtime

## Tags
`outlook`, `email`, `microsoft-graph`, `mcp`, `productivity`, `communication`
