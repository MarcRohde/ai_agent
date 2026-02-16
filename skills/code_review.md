# Skill: Code Review

## Description
Perform a structured code review on a file or set of changes, providing actionable feedback on correctness, readability, performance, security, and best practices.

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| `target` | Yes | File path, selection, or diff to review |
| `focus` | No | Specific area to focus on (e.g., "security", "performance") |
| `language` | No | Programming language (auto-detected if omitted) |

## Steps

1. **Read the target code** — Open and read the file or diff provided.
2. **Identify the language and framework** — Detect the language and any frameworks in use.
3. **Analyze for issues** across these dimensions:
   - **Correctness**: Bugs, logic errors, edge cases
   - **Readability**: Naming, structure, comments, complexity
   - **Performance**: Inefficiencies, unnecessary allocations, O(n²) patterns
   - **Security**: Injection, auth issues, sensitive data exposure
   - **Best Practices**: Idiomatic patterns, DRY, SOLID principles
4. **Prioritize findings** — Rank by severity: 🔴 Critical, 🟡 Warning, 🔵 Suggestion.
5. **Provide fix suggestions** — For each finding, suggest a concrete fix.

## Output

Return a structured review in this format:

```markdown
## Code Review: {{filename}}

### Summary
Brief overall assessment (1-2 sentences).

### Findings

#### 🔴 Critical
- **[Line X]**: Description of issue
  - **Fix**: Suggested correction

#### 🟡 Warnings
- **[Line X]**: Description of issue
  - **Fix**: Suggested correction

#### 🔵 Suggestions
- **[Line X]**: Description of suggestion
  - **Fix**: Suggested improvement

### Score: X/10
```

## Referenced Prompts
- `prompts/system/default_system.md`

## Referenced Tools
- None

## Tags
`code-quality`, `review`, `analysis`
