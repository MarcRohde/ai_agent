# Skill: Explain Code

## Description
Explain what a piece of code does, including its purpose, patterns used, control flow, and trade-offs. Adapts explanation depth to the user's apparent level.

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| `target` | Yes | File path, selection, or code snippet to explain |
| `depth` | No | Explanation depth: "brief", "detailed", or "beginner-friendly" (default: "detailed") |
| `focus` | No | Specific aspect to focus on (e.g., "algorithm", "architecture", "data flow") |

## Steps

1. **Read the code** — Open and fully read the target code.
2. **Identify the high-level purpose** — What problem does this code solve?
3. **Break down the structure**:
   - Key functions/classes and their roles
   - Data flow (inputs → transformations → outputs)
   - Control flow (branching, loops, async patterns)
4. **Identify patterns and techniques**:
   - Design patterns (Observer, Factory, Strategy, etc.)
   - Language-specific idioms
   - Architectural patterns (MVC, event-driven, etc.)
5. **Note trade-offs and alternatives**:
   - Why was this approach chosen?
   - What are the limitations?
   - What alternatives exist?
6. **Adjust depth** based on the `depth` input.

## Output

```markdown
## Explanation: {{filename or description}}

### Purpose
What this code does in 1-2 sentences.

### How It Works
Step-by-step walkthrough of the logic.

### Key Concepts
- **Pattern**: Description of pattern used
- **Technique**: Description of notable technique

### Trade-offs
- ✅ Advantage 1
- ✅ Advantage 2
- ⚠️ Limitation 1

### Related
- Links to similar patterns or documentation
```

## Referenced Prompts
- `prompts/system/default_system.md`

## Referenced Tools
- None

## Tags
`explanation`, `learning`, `documentation`
