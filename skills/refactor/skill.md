# Skill: Refactor

## Description
Refactor code to improve readability, maintainability, or performance while preserving existing behavior.

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| `target` | Yes | File path or code selection to refactor |
| `goal` | No | Specific refactoring goal (e.g., "extract method", "reduce complexity", "apply SOLID") |
| `constraints` | No | Any constraints (e.g., "don't change public API", "keep backward compatible") |

## Steps

1. **Read and understand the code** — Fully read the target code and understand its purpose.
2. **Identify refactoring opportunities**:
   - Long methods → extract smaller functions
   - Duplicated code → DRY it up
   - Complex conditionals → simplify or use polymorphism
   - Magic numbers/strings → named constants
   - Deep nesting → early returns or guard clauses
   - God classes → split responsibilities
3. **Plan the refactoring** — List specific changes before making them.
4. **Apply changes incrementally** — Make one logical change at a time.
5. **Verify behavior preservation** — Ensure the refactored code does the same thing.
6. **Run existing tests** if available to confirm nothing broke.

## Output

- The refactored code applied directly to the file(s).
- A brief summary of changes made and why.

```markdown
## Refactoring Summary: {{filename}}

### Changes Made
1. Extracted `{{method_name}}` from line X-Y (reduces complexity)
2. Replaced magic number `42` with `MAX_RETRY_COUNT`
3. ...

### Before/After Complexity
- Cyclomatic complexity: X → Y
- Lines of code: X → Y
```

## Referenced Prompts
- `prompts/system/default_system.md`

## Referenced Tools
- None

## Tags
`code-quality`, `refactor`, `maintainability`
