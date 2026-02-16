# Skill: Git Operations

## Description
Perform common git workflows including branching, committing with conventional messages, generating PR descriptions, and managing release workflows.

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| `operation` | Yes | The git operation: "branch", "commit", "pr-description", "changelog" |
| `context` | No | Additional context (e.g., ticket number, feature description) |

## Steps

### Operation: `branch`
1. Ask for or infer the branch type: `feature/`, `bugfix/`, `hotfix/`, `chore/`.
2. Generate a branch name from the context: `feature/TICKET-123-add-user-auth`.
3. Create and checkout the branch.

### Operation: `commit`
1. Run `git diff --staged` to see what's being committed.
2. Analyze the changes to determine the commit type.
3. Generate a **Conventional Commit** message:
   ```
   type(scope): description

   - Detail 1
   - Detail 2
   ```
   Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `perf`.
4. Present the message for approval, then commit.

### Operation: `pr-description`
1. Run `git log main..HEAD --oneline` to get the commits.
2. Run `git diff main..HEAD --stat` for a file change summary.
3. Read changed files for context.
4. Generate a PR description:
   ```markdown
   ## Summary
   Brief description of what this PR does.

   ## Changes
   - Change 1
   - Change 2

   ## Testing
   How to test these changes.

   ## Checklist
   - [ ] Tests added/updated
   - [ ] Documentation updated
   - [ ] No breaking changes
   ```

### Operation: `changelog`
1. Read git log between two tags or refs.
2. Group commits by type.
3. Generate a CHANGELOG entry in Keep a Changelog format.

## Output

Depends on the operation — either a terminal command executed, or a markdown document generated.

## Referenced Prompts
- `prompts/system/default_system.md`

## Referenced Tools
- Git CLI (via terminal)

## Tags
`git`, `workflow`, `automation`, `commits`
