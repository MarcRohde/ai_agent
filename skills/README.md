# Skills Directory

This directory contains individual skill definitions. Each skill is organized in its own named subfolder with a standardized `skill.md` file.

## Folder Structure

```
skills/
├── code_review/
│   └── skill.md
├── documentation/
│   └── skill.md
├── explain_code/
│   └── skill.md
├── generate_tests/
│   └── skill.md
├── git_operations/
│   └── skill.md
├── refactor/
│   └── skill.md
└── README.md
```

## Conventions

- One skill per folder
- Folder names: `snake_case` (e.g., `code_review/`)
- The skill definition is always named `skill.md` inside the folder
- Additional skill-specific assets (scripts, configs, examples) can live alongside `skill.md`
- Every skill follows the structure in `../templates/skill_template.md`
- Register new skills in `../skill_library.md`

## Available Skills

| Folder | Category | Description |
|--------|----------|-------------|
| `code_review/` | Code Quality | Structured code review |
| `refactor/` | Code Quality | Code refactoring |
| `generate_tests/` | Testing | Unit test generation |
| `explain_code/` | Explanation | Code explanation |
| `git_operations/` | Git & Workflow | Git workflows |
| `documentation/` | Documentation | Doc generation |
