# Skill: WorkIQ Mail MCP

## Description
Use the Work IQ Mail MCP server (`mcp_MailTools`) to retrieve, draft, update, and send mailbox content in a controlled workflow. Default to read-only operations unless the user explicitly requests a mutating action.

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| `task` | Yes | Natural language mailbox task to complete |
| `mode` | No | `read-only` (default) or `mutating` |
| `preview_tool_count` | No | Number of tools to preview during discovery (default: 5) |
| `try_tool_call` | No | When `true`, perform a tool invocation after discovery |

## Preconditions
1. `EXO_CLIENT_ID` and `EXO_TENANT_ID` are set.
2. `WORKIQ_MAIL_TOKEN` is set.
3. `.vscode/mcp.json` contains `workiq-mail`.
4. Use a single harness execution for `initialize`, `tools/list`, and any tool call; do not split MCP session steps across separate shell commands.

## Steps

1. **Acquire token**
   - Run `tools/scripts/Set-WorkIQMcpToken.ps1` with:
     - `-Scope 'McpServers.Mail.All'`
     - `-TokenEnvVar 'WORKIQ_MAIL_TOKEN'`
     - `-ServerAlias 'workiq-mail'`

2. **Validate server connectivity and tool listing**
   - Run `tools/scripts/Test-WorkIQMcpServer.ps1` against:
     - Endpoint: `https://agent365.svc.cloud.microsoft/agents/servers/mcp_MailTools/`
     - Token env var: `WORKIQ_MAIL_TOKEN`
   - Keep the connectivity check and any optional tool call inside the same script execution so the MCP session ID is preserved.

3. **Plan the tool call**
   - Run capability discovery first and do not assume the server supports a mailbox action just because the user requested it.
   - Pick the safest tool that satisfies `task`.
   - For destructive operations (`DeleteMessage`, `SendDraftMessage`, etc.), confirm intent before execution.

4. **Execute and inspect output**
   - Invoke the selected tool through MCP.
   - Capture server reply, message IDs, and any correlation metadata.

5. **Return a user-facing result**
   - Summarize what was completed.
   - Include limitations (for example, size metadata not available, delete semantics uncertain, or server capability missing).

## Operational Notes
- Treat `SearchMessages` results as candidate data, not complete message metadata. You may need to extract an encoded `ItemID` from an OWA citation link before follow-up actions.
- If a token env var is present but the endpoint still returns `401`, treat that as an auth validation failure rather than a configuration success. Refresh the token and re-run the harness.
- Prefer the repo test harness scripts over manual, multi-command REST experiments when diagnosing WorkIQ Mail MCP behavior.

## Output

```markdown
## WorkIQ Mail MCP Result

- Server: `workiq-mail`
- Scope: `McpServers.Mail.All`
- Task: `{task}`
- Tool used: `{tool_name}`
- Mode: `{read-only|mutating}`
- Status: `{success|failed}`

### Details
{Key response details, IDs, and constraints}

### Follow-up
- {Optional next step}
```

## Referenced Prompts
- `prompts/system/default_system.md`

## Referenced Tools
- `tools/scripts/Set-WorkIQMcpToken.ps1`
- `tools/scripts/Test-WorkIQMcpServer.ps1`
- `tools/scripts/Test-WorkIQMailMcp.ps1`

## Tags
`workiq`, `mcp`, `mail`, `microsoft-365`, `agent365`
