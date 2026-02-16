# Skill: Generate Tests

## Description
Generate unit tests for a given file, class, or function. Produces tests that cover happy paths, edge cases, and error conditions.

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| `target` | Yes | File path, class, or function to generate tests for |
| `framework` | No | Test framework to use (auto-detected: Jest, pytest, xUnit, etc.) |
| `coverage_goal` | No | Target coverage level (default: "comprehensive") |
| `style` | No | Test style preference (e.g., "AAA pattern", "BDD", "given-when-then") |

## Steps

1. **Read the target code** — Understand the function/class signatures, dependencies, and behavior.
2. **Identify the test framework** — Detect from project config (`package.json`, `pytest.ini`, `.csproj`, etc.) or use the specified framework.
3. **Analyze test scenarios**:
   - **Happy path**: Normal inputs, expected outputs
   - **Edge cases**: Empty inputs, boundary values, null/undefined
   - **Error cases**: Invalid inputs, exceptions, timeout scenarios
   - **Integration points**: Mock external dependencies
4. **Generate test file** — Create a properly structured test file following project conventions.
5. **Include setup/teardown** if needed (beforeEach, fixtures, etc.).
6. **Add descriptive test names** using the pattern: `should [expected behavior] when [condition]`.
7. **Run the tests** to verify they pass (if possible).

## Output

- A new test file created at the conventional location (e.g., `__tests__/`, `*.test.ts`, `*_test.py`).
- Summary of test coverage:

```markdown
## Test Generation Summary: {{filename}}

### Tests Created
- ✅ `should return correct sum when given positive numbers`
- ✅ `should return 0 when given empty array`
- ✅ `should throw TypeError when given non-array input`
- ...

### Coverage
- Statements: X scenarios covered
- Branches: X/Y branches covered
- Edge cases: X identified and tested
```

## Referenced Prompts
- `prompts/system/default_system.md`

## Referenced Tools
- None

## Tags
`testing`, `unit-tests`, `coverage`
