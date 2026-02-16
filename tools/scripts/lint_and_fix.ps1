<#
.SYNOPSIS
    Runs linting and auto-fix on a target file or directory.

.DESCRIPTION
    Detects the project type (Node.js, Python, etc.) and runs the appropriate
    linter with auto-fix enabled. Supports ESLint, Prettier, Ruff, Black, and more.

.PARAMETER Target
    The file or directory to lint. Defaults to the current directory.

.PARAMETER Fix
    Whether to apply auto-fixes. Defaults to $true.

.EXAMPLE
    .\lint_and_fix.ps1 -Target "src/"
    .\lint_and_fix.ps1 -Target "app.py" -Fix $false
#>

param(
    [string]$Target = ".",
    [bool]$Fix = $true
)

$ErrorActionPreference = "Stop"

function Write-Step($message) {
    Write-Host "`n[lint_and_fix] $message" -ForegroundColor Cyan
}

# Detect project type
$hasPackageJson = Test-Path (Join-Path $Target "package.json") -or Test-Path "package.json"
$hasPyproject = Test-Path (Join-Path $Target "pyproject.toml") -or Test-Path "pyproject.toml"
$hasRequirements = Test-Path (Join-Path $Target "requirements.txt") -or Test-Path "requirements.txt"

if ($hasPackageJson) {
    Write-Step "Detected Node.js project"

    # Try ESLint
    if (Get-Command "npx" -ErrorAction SilentlyContinue) {
        $eslintArgs = @($Target)
        if ($Fix) { $eslintArgs += "--fix" }

        Write-Step "Running ESLint..."
        & npx eslint @eslintArgs

        Write-Step "Running Prettier..."
        $prettierArgs = @($Target)
        if ($Fix) { $prettierArgs += "--write" } else { $prettierArgs += "--check" }
        & npx prettier @prettierArgs
    }
}
elseif ($hasPyproject -or $hasRequirements) {
    Write-Step "Detected Python project"

    # Try Ruff (modern, fast)
    if (Get-Command "ruff" -ErrorAction SilentlyContinue) {
        Write-Step "Running Ruff..."
        $ruffArgs = @("check", $Target)
        if ($Fix) { $ruffArgs += "--fix" }
        & ruff @ruffArgs
    }
    # Fallback to Black + Flake8
    elseif (Get-Command "black" -ErrorAction SilentlyContinue) {
        Write-Step "Running Black..."
        $blackArgs = @($Target)
        if (-not $Fix) { $blackArgs += "--check" }
        & black @blackArgs
    }
}
else {
    Write-Step "Could not detect project type. Skipping lint."
    Write-Host "Supported: Node.js (package.json), Python (pyproject.toml / requirements.txt)"
}

Write-Step "Done."
