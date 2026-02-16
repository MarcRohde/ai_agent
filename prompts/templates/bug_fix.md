# Prompt Template: Bug Fix

## Purpose
Guide the agent through diagnosing and fixing a bug.

## Template

```
You are fixing a bug in the codebase.

**Bug Description**: {{bug_description}}
**File(s) Affected**: {{file_paths}}
**Expected Behavior**: {{expected_behavior}}
**Actual Behavior**: {{actual_behavior}}
**Steps to Reproduce**: {{reproduction_steps}}

## Instructions

1. Read the affected file(s) thoroughly.
2. Identify the root cause of the bug (not just the symptom).
3. Propose a fix with a clear explanation of WHY it works.
4. Apply the fix.
5. If tests exist, run them to verify the fix.
6. If no tests exist, suggest a test case that would catch this regression.

## Output Format

### Root Cause
Explain the root cause in 1-3 sentences.

### Fix Applied
Describe what was changed and why.

### Verification
How to verify the fix works.
```

## Variables

| Variable | Description |
|----------|-------------|
| `{{bug_description}}` | User's description of the bug |
| `{{file_paths}}` | Comma-separated file paths |
| `{{expected_behavior}}` | What should happen |
| `{{actual_behavior}}` | What actually happens |
| `{{reproduction_steps}}` | How to trigger the bug |
