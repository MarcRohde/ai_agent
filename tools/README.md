# Tools Directory

This directory contains helper scripts and tool definitions that skills can invoke.

## Structure

```
tools/
├── README.md
└── scripts/          # Executable scripts
    └── lint_and_fix.ps1
```

## Conventions

- Scripts include a usage header comment.
- Scripts handle errors gracefully and provide clear output.
- Add new scripts here when a skill needs to automate a terminal operation.
