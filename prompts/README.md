# Prompts Directory

This directory contains reusable prompt templates that skills can reference.

## Structure

```
prompts/
├── system/           # System-level prompts (persona, rules, tone)
│   └── default_system.md
└── templates/        # Task-specific prompt templates
    ├── bug_fix.md
    └── feature_request.md
```

## Conventions

- System prompts set the agent's persona and ground rules.
- Templates use `{{placeholder}}` syntax for variable substitution.
- Keep prompts focused — one purpose per file.
