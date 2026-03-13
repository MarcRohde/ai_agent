# Skill: WorkIQ Word MCP

## Description
Use the Work IQ Word MCP server (`mcp_WordServer`) for Microsoft Word document operations, including document retrieval, content inspection, and controlled edits where supported.

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| `task` | Yes | Word document operation request |
| `mode` | No | `read-only` (default) or `mutating` |
| `preview_tool_count` | No | Number of tools to preview during discovery (default: 5) |

## Preconditions
1. `EXO_CLIENT_ID` and `EXO_TENANT_ID` are set.
2. `WORKIQ_WORD_TOKEN` is set.
3. `.vscode/mcp.json` contains `workiq-word`.

## Steps

1. **Acquire token**
   - Run `tools/scripts/Set-WorkIQMcpToken.ps1` with:
     - `-Scope 'McpServers.Word.All'`
     - `-TokenEnvVar 'WORKIQ_WORD_TOKEN'`
     - `-ServerAlias 'workiq-word'`

2. **Validate server and discover tools**
   - Run `tools/scripts/Test-WorkIQMcpServer.ps1` with endpoint:
     - `https://agent365.svc.cloud.microsoft/agents/servers/mcp_WordServer/`

3. **Execute least-risk document operation**
   - Prefer retrieval and analysis.
   - Require confirmation before content changes.

4. **Return document-focused output**
   - Provide relevant sections, extraction results, or mutation summary.

## Output

```markdown
## WorkIQ Word MCP Result

- Server: `workiq-word`
- Scope: `McpServers.Word.All`
- Task: `{task}`
- Tool used: `{tool_name}`
- Mode: `{read-only|mutating}`
- Status: `{success|failed}`

### Document Result
{Document operations performed and outcomes}
```

## Referenced Prompts
- `prompts/system/default_system.md`

## Referenced Tools
- `tools/scripts/Set-WorkIQMcpToken.ps1`
- `tools/scripts/Test-WorkIQMcpServer.ps1`

## Tags
`workiq`, `mcp`, `word`, `documents`, `microsoft-365`, `agent365`
