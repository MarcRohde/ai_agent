# Skill: Google Workspace (gws CLI)

## Description
Use the `gws` CLI to interact with Google Workspace services including Gmail, Calendar, Drive, Docs, Sheets, Tasks, Contacts, and more. Default to read-only operations unless the user explicitly requests a mutating action.

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| `task` | Yes | Natural language task to complete against a Google Workspace service |
| `service` | No | Target service: `gmail`, `calendar`, `drive`, `docs`, `sheets`, `tasks`, `people`, `chat`, `keep`, `meet`, `forms`, `slides` (inferred from task if omitted) |
| `mode` | No | `read-only` (default) or `mutating` |

## Preconditions
1. `gws` CLI is installed and reachable on `PATH`.
2. Auth is configured: run `gws auth login` if credentials are missing or expired (exit code 2).
3. Environment variables (optional overrides):
   - `GOOGLE_WORKSPACE_CLI_TOKEN` — pre-obtained OAuth2 access token (highest priority)
   - `GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE` — path to OAuth credentials JSON
   - `GOOGLE_WORKSPACE_CLI_CLIENT_ID` / `GOOGLE_WORKSPACE_CLI_CLIENT_SECRET`

## Service Reference

| Service | Common Operations |
|---------|------------------|
| `gmail` | Read, search, send, reply, forward messages; watch inbox |
| `calendar` | List/create/update events and calendars |
| `drive` | List, get, upload, download, share files and folders |
| `docs` | Read and write Google Docs |
| `sheets` | Read and write spreadsheet data |
| `tasks` | Manage task lists and individual tasks |
| `people` | Read and manage contacts and profiles |
| `chat` | Read and post to Chat spaces |
| `keep` | Read and manage Keep notes |
| `meet` | Manage Meet conferences |
| `forms` | Read Google Form definitions and responses |
| `slides` | Read and write Presentations |
| `admin-reports` | Access audit logs and usage reports |
| `workflow` | Cross-service productivity workflows (`gws wf`) |

## Steps

### 1. Confirm auth
```powershell
gws auth status
# If exit code is 2, run:
gws auth login
```

### 2. Infer service and operation
- Map the user's task to a service and the appropriate resource/method.
- Review schema when needed: `gws schema <service.resource.method>`
- Use helper commands when available (they simplify complex operations):
  - `gws gmail +triage` — unread inbox summary
  - `gws gmail +send` — compose and send email
  - `gws gmail +reply` / `+reply-all` — threaded reply
  - `gws gmail +forward` — forward a message
  - `gws gmail +watch` — stream new email as NDJSON
  - `gws workflow` / `gws wf` — cross-service tasks

### 3. Build the command
Standard pattern:
```
gws <service> <resource> [sub-resource] <method> --params '<JSON>' [--json '<JSON>'] [--format table|json|csv|yaml]
```

Common Gmail examples:
```powershell
# List last 5 inbox messages
gws gmail users messages list --params '{"userId":"me","maxResults":5,"labelIds":["INBOX"]}'

# Get a specific message
gws gmail users messages get --params '{"userId":"me","id":"<messageId>"}'

# Search messages
gws gmail users messages list --params '{"userId":"me","q":"from:someone@example.com","maxResults":10}'

# Send email (helper)
gws gmail +send --params '{"to":"addr@example.com","subject":"Hello","body":"Message body"}'

# Inbox triage summary
gws gmail +triage
```

Common Calendar examples:
```powershell
# List upcoming events
gws calendar events list --params '{"calendarId":"primary","maxResults":10,"orderBy":"startTime","singleEvents":true,"timeMin":"<RFC3339>"}'

# Create an event
gws calendar events insert --json '{"summary":"Meeting","start":{"dateTime":"..."},"end":{"dateTime":"..."}}'
```

Common Drive examples:
```powershell
# List recent files
gws drive files list --params '{"pageSize":10,"orderBy":"modifiedTime desc"}'

# Download a file
gws drive files get --params '{"fileId":"<id>","alt":"media"}' --output ./filename.ext
```

### 4. Handle pagination
- Use `--page-all` to auto-paginate (outputs NDJSON, one line per page).
- Use `--page-limit <N>` to cap pages.
- Use `--format table` for human-readable summaries.

### 4a. Fast Gmail triage wrapper (Phase 1)
For repeated mailbox cleanup workflows, prefer the wrapper script:

Precheck before running wrapper commands:
```powershell
gws auth status
# If exit code is 2, run:
gws auth login
```

```powershell
# Find messages with headers only
.\tools\scripts\GoogleWorkspace\Invoke-GwsGmailTriage.ps1 -Action find -Query 'from:chase' -MaxResults 200

# Dry-run sweep (default) with keep rules
.\tools\scripts\GoogleWorkspace\Invoke-GwsGmailTriage.ps1 -Action sweep -Query 'from:chase' -MaxResults 200 -KeepSubjectPattern 'daily summary'

# Apply sweep (requires explicit confirmation)
.\tools\scripts\GoogleWorkspace\Invoke-GwsGmailTriage.ps1 -Action sweep -Query 'from:chase' -MaxResults 200 -KeepSubjectPattern 'daily summary' -Apply -ConfirmDelete

# Verify status after delete
.\tools\scripts\GoogleWorkspace\Invoke-GwsGmailTriage.ps1 -Action verify -Query 'from:chase' -MaxResults 200

# Keep specific senders while sweeping everything else in a query
.\tools\scripts\GoogleWorkspace\Invoke-GwsGmailTriage.ps1 -Action sweep -Query 'newer_than:7d' -MaxResults 500 -KeepFromPattern 'three harbors|kanwa tho' -Apply -ConfirmDelete

# Delete only marketing-style subjects from a broader sender query
.\tools\scripts\GoogleWorkspace\Invoke-GwsGmailTriage.ps1 -Action sweep -Query 'from:chase' -MaxResults 200 -DeleteSubjectPattern '(?i)deal|promo|offer' -Apply -ConfirmDelete
```

Phase 1 guarantees:
- Single-entry workflow for retrieve/filter/delete/verify
- Dry-run by default for sweep operations
- Explicit `-Apply -ConfirmDelete` gate before any delete
- Operation artifact JSON written per run for traceability
- Post-delete verification against Gmail labels

### 4b. Recommended iterative cleanup workflow
Use this loop for high-speed, low-risk triage sessions:

1. Run `find` and generate a numbered reference list from the artifact (`Ref`, `Id`, `From`, `Subject`).
2. Have the user respond with refs to delete or keep.
3. Convert refs to IDs and run `sweep` with explicit `-Ids` plus `-Apply -ConfirmDelete`.
4. Run `verify` against the same IDs and return per-message status.
5. Retrieve the next batch and exclude previously kept IDs to avoid repeated noise.

Minimal command pattern:
```powershell
# 1) Retrieve and map refs
.\tools\scripts\GoogleWorkspace\Invoke-GwsGmailTriage.ps1 -Action find -Query 'in:inbox' -MaxResults 40

# 2) Delete explicit IDs selected from refs
.\tools\scripts\GoogleWorkspace\Invoke-GwsGmailTriage.ps1 -Action sweep -Ids '<id1>','<id2>' -Apply -ConfirmDelete

# 3) Verify the same IDs
.\tools\scripts\GoogleWorkspace\Invoke-GwsGmailTriage.ps1 -Action verify -Ids '<id1>','<id2>'
```

### 4c. Backlog for Phase 2 speed improvements
- Add `delete-refs` support so users can submit `G1,G4,G9` directly from the latest artifact.
- Add a `next` action to return the next `N` messages while excluding kept and already-processed IDs.
- Add optional state persistence (`StatePath`) for crash recovery and cross-turn continuity.
- Add concise operation summaries (`requested`, `deleted`, `verified`, `failed`, `remaining`) for faster decisions.
- Add optional parallel message-header retrieval for large `find` operations.

### 5. Mutating operations — confirmation required
Before executing any of the following, confirm intent explicitly with the user:
- Sending email (`+send`, `messages.send`)
- Deleting messages or files (`messages.delete`, `files.delete`)
- Modifying calendar events (`events.update`, `events.delete`)
- Creating or modifying Drive files (`files.create`, `files.update`)

### 6. Return results
- Summarize what was retrieved or performed.
- Include key identifiers (message IDs, file IDs, event IDs) for follow-up operations.
- Note any scope or permission limitations encountered.

## Auth Troubleshooting

| Exit Code | Meaning | Resolution |
|-----------|---------|------------|
| 0 | Success | — |
| 1 | API error | Check `--params` JSON and resource path |
| 2 | Auth error | Run `gws auth login` |
| 3 | Validation | Fix bad arguments or JSON |
| 4 | Discovery | API schema unavailable; try `--api-version` override |
| 5 | Internal | Unexpected failure; re-run with `--dry-run` to verify inputs |

## Output

```markdown
## Google Workspace Result

- Service: `{service}`
- Resource: `{resource.method}`
- Task: `{task}`
- Mode: `{read-only|mutating}`
- Status: `{success|failed}`

### Details
{Key response data, IDs, summaries}

### Follow-up
- {Optional next step or related operation}
```

## Safety Guardrails
- Never expose OAuth tokens, client secrets, or credential file contents.
- Treat `GOOGLE_WORKSPACE_CLI_TOKEN` as a secret; do not print it.
- Confirm all mutating operations before executing.
- Use `--dry-run` to validate requests locally before sending.
- Request only the minimum scopes required for the task.

## Tags
`gmail` `google-workspace` `calendar` `drive` `docs` `sheets` `gws` `cli` `read-only`
