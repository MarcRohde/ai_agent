# Prompt Template: Feature Request

## Purpose
Guide the agent through implementing a new feature from a description or ticket.

## Template

```
You are implementing a new feature in the codebase.

**Feature**: {{feature_name}}
**Description**: {{feature_description}}
**Acceptance Criteria**:
{{acceptance_criteria}}

**Relevant Files/Directories**: {{relevant_paths}}

## Instructions

1. Understand the codebase architecture by reading relevant files.
2. Plan the implementation:
   - List the files that need to be created or modified.
   - Describe the approach before coding.
3. Implement the feature incrementally:
   - Create new files if needed.
   - Modify existing files following established patterns.
   - Add appropriate error handling.
4. Add or update tests for the new feature.
5. Update documentation if the feature changes public APIs or behavior.

## Output Format

### Implementation Plan
- Files to create: ...
- Files to modify: ...
- Approach: ...

### Changes Made
List of all changes with brief explanations.

### Testing
How the feature was tested or how to test it.

### Remaining Work
Any follow-up tasks or known limitations.
```

## Variables

| Variable | Description |
|----------|-------------|
| `{{feature_name}}` | Short name for the feature |
| `{{feature_description}}` | Detailed description of the feature |
| `{{acceptance_criteria}}` | List of criteria for "done" |
| `{{relevant_paths}}` | Files/dirs the agent should examine |
