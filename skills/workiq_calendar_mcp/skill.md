# Skill: WorkIQ Calendar MCP

## Description
Use the Work IQ Calendar MCP server (`mcp_CalendarTools`) to retrieve calendar events and scheduling context, and to perform requested calendar actions with explicit confirmation for mutating operations.

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| `task` | Yes | Calendar or scheduling request |
| `mode` | No | `read-only` (default) or `mutating` |
| `preview_tool_count` | No | Number of tools to preview during discovery (default: 5) |

## Preconditions
1. `EXO_CLIENT_ID` and `EXO_TENANT_ID` are set.
2. `WORKIQ_CALENDAR_TOKEN` is set.
3. `.vscode/mcp.json` contains `workiq-calendar`.

## Steps

1. **Acquire token**
   - Run `tools/scripts/Set-WorkIQMcpToken.ps1` with:
     - `-Scope 'McpServers.Calendar.All'`
     - `-TokenEnvVar 'WORKIQ_CALENDAR_TOKEN'`
     - `-ServerAlias 'workiq-calendar'`

2. **Validate server and list tools**
   - Run `tools/scripts/Test-WorkIQMcpServer.ps1` with endpoint:
     - `https://agent365.svc.cloud.microsoft/agents/servers/mcp_CalendarTools/`

3. **Choose safe operation path**
   - Read-only for availability and event lookup.
   - Confirm user intent before create/update/delete event actions.

4. **Execute and summarize**
   - Return event metadata, time windows, and any scheduling conflicts.

## Output

```markdown
## WorkIQ Calendar MCP Result

- Server: `workiq-calendar`
- Scope: `McpServers.Calendar.All`
- Task: `{task}`
- Tool used: `{tool_name}`
- Mode: `{read-only|mutating}`
- Status: `{success|failed}`

### Calendar Details
{Events, times, attendees, and any caveats}
```

## Referenced Prompts
- `prompts/system/default_system.md`

## Referenced Tools
- `tools/scripts/Set-WorkIQMcpToken.ps1`
- `tools/scripts/Test-WorkIQMcpServer.ps1`

## Tags
`workiq`, `mcp`, `calendar`, `scheduling`, `microsoft-365`, `agent365`
