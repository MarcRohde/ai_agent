# Skill: Documentation

## Description
Generate or update documentation for code, APIs, projects, or architecture. Supports README generation, inline doc comments, API docs, and architecture decision records.

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| `target` | Yes | File, directory, or project to document |
| `type` | No | Doc type: "readme", "api", "inline", "adr" (default: auto-detect) |
| `audience` | No | Target audience: "developers", "users", "stakeholders" |

## Steps

### Type: `readme`
1. Scan the project structure.
2. Read key files (`package.json`, `setup.py`, `*.csproj`, etc.) for metadata.
3. Generate a README with: Title, Description, Prerequisites, Installation, Usage, Configuration, Contributing, License.

### Type: `api`
1. Read source files and identify public interfaces.
2. Generate API documentation with: endpoint/method signature, parameters, return types, examples, error codes.

### Type: `inline`
1. Read the target file.
2. Add/update doc comments (JSDoc, docstrings, XML docs) for all public functions, classes, and modules.
3. Preserve existing documentation where accurate.

### Type: `adr` (Architecture Decision Record)
1. Gather context about the decision from the user.
2. Generate ADR using the template:
   ```markdown
   # ADR-NNN: Title

   ## Status
   Proposed | Accepted | Deprecated | Superseded

   ## Context
   What is the issue motivating this decision?

   ## Decision
   What is the change being proposed?

   ## Consequences
   What are the results of this decision?
   ```

## Output

- Generated documentation written to appropriate file(s).
- Summary of what was documented.

## Referenced Prompts
- `prompts/system/default_system.md`

## Referenced Tools
- None

## Tags
`documentation`, `readme`, `api-docs`, `adr`
