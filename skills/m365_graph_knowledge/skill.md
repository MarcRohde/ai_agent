# Skill: M365 Graph Knowledge

## Description
Use Microsoft 365 Graph search (and optional WorkIQ-style connector content through `externalItem`) as a knowledge source for answering questions with citations. This skill is designed to retrieve non-synced OneDrive/SharePoint content that is available through Microsoft 365 permissions.

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| `question` | Yes | User question to answer from Microsoft 365 content |
| `scope` | No | Retrieval scope: `all` (default), `work`, `personal`, `mail`, `chat`, `communications` |
| `entity_types` | No | Graph entity types override (for example `driveItem,listItem,site`) |
| `include_mail` | No | Add Graph `message` entity type |
| `include_chat` | No | Add Graph `chatMessage` entity type |
| `include_mail_and_chat` | No | Convenience option to include both mail and chat in one query |
| `top` | No | Maximum results to retrieve (default: 10, max: 50) |
| `endpoint_version` | No | `v1.0` (default) or `beta` when needed for specific entities |
| `include_workiq` | No | `true` to include `externalItem` when connectors are configured |

## Preconditions
1. Confirm `config/m365_knowledge_config.json` exists and is readable.
2. Confirm Graph token is available through one of:
   - `M365_GRAPH_ACCESS_TOKEN` environment variable
   - Azure CLI login (`az login`) with browser-based OAuth flow
   - device code flow via `tools/scripts/M365/Get-M365GraphAccessToken.ps1` (requires `EXO_TENANT_ID` and `EXO_CLIENT_ID`)
3. Confirm least-privilege delegated permissions are granted for required sources.

## Steps

1. **Resolve retrieval scope**
   - Map `scope` to Graph entity types from `config/m365_knowledge_config.json`.
   - Use `scope=communications` or `include_mail_and_chat=true` to include mail and chat together.
   - If `include_workiq=true`, append `externalItem`.

2. **Acquire Graph token**
   - Reuse existing token when available.
   - Prefer Azure CLI browser login fallback for interactive local use.
   - Otherwise acquire a new token using `tools/scripts/M365/Get-M365GraphAccessToken.ps1`.

3. **Execute Graph search**
   - Run `tools/scripts/M365/Search-M365Knowledge.ps1` with the user question and resolved entity types.
   - Retrieve top ranked results with URLs and citation paths.

4. **Filter and rank evidence**
   - Exclude results that violate blocked extension/path rules in config.
   - Prioritize newest and most relevant work items for enterprise questions.

5. **Compose grounded answer**
   - Answer only from retrieved evidence.
   - Include citation paths or URLs for each key claim.
   - If confidence is low, return what was found and request scope/entity adjustments.

## Output

```markdown
## M365 Knowledge Response

### Answer
{Grounded answer synthesized from Graph results}

### Sources
1. `{citation_path_or_url}`
2. `{citation_path_or_url}`

### Retrieval Metadata
- Scope: `{scope}`
- Entity types: `{entity_types}`
- Result count: `{count}`
- Endpoint: `{v1.0|beta}`

### Gaps
- {Any missing access, connector, or scope limitations}
```

## Safety Guardrails
- Never claim content that is not present in retrieved Graph results.
- Never reveal access tokens, secrets, or raw credential values.
- Use least-privilege scopes and avoid broad mail/chat access unless required.
- Respect Microsoft 365 permissions; if access is denied, report it clearly.

## Referenced Prompts
- `prompts/system/default_system.md`

## Referenced Tools
- `tools/scripts/M365/Get-M365GraphAccessToken.ps1`
- `tools/scripts/M365/Search-M365Knowledge.ps1`

## Tags
`microsoft-365`, `graph`, `workiq`, `knowledge-retrieval`, `sharepoint`, `onedrive`
