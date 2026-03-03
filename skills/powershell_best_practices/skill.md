# Skill: PowerShell Script Best Practices

## Description
Develop production-quality PowerShell scripts following Microsoft best practices: parameter validation, error handling, help documentation, pipeline support, ShouldProcess for destructive operations, and idiomatic PowerShell patterns.

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| `script_purpose` | Yes | What the script does (e.g., "migrate mailbox items") |
| `parameters` | Yes | List of input parameters with types and validation rules |
| `destructive_operations` | No | Whether script modifies/deletes data (triggers ShouldProcess) |
| `requires_admin` | No | Whether script needs elevated privileges |
| `multi_threading` | No | Whether to implement parallel processing with runspaces |

## Steps

1. **Define CmdletBinding and Parameters** — Use `[CmdletBinding()]` for common parameters (`-Verbose`, `-WhatIf`, `-ErrorAction`). Add appropriate attributes:
   - `[Parameter(Mandatory=$true)]` for required inputs
   - `[ValidateRange()]`, `[ValidateSet()]` for input validation
   - `[string]`, `[int]`, `[switch]` for type safety

2. **Add Comment-Based Help** — Include `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE` sections. Document throttling considerations, security requirements, and usage patterns.

3. **Set Strict Mode and Error Preferences** — Add `Set-StrictMode -Version Latest` and `$ErrorActionPreference = 'Stop'` for predictable error handling.

4. **Implement ShouldProcess for Destructive Operations** — Use `$PSCmdlet.ShouldProcess($target, $action)` before delete/modify operations. Set `ConfirmImpact = 'High'` for dangerous operations.

5. **Use Environment Variables for Credentials** — Never hardcode secrets. Default parameters to `$env:VARIABLE_NAME`. Provide clear error messages when required env vars are missing.

6. **Add Comprehensive Error Handling** — Use try/catch/finally blocks. Classify transient vs permanent errors. Log errors with context (operation, timestamp, error details).

7. **Implement Runspace Pools for Multi-Threading (if needed)** — For parallel processing:
   - Create runspace pool with `[RunspaceFactory]::CreateRunspacePool($minThreads, $maxThreads)`
   - Pass functions to worker threads using string definitions
   - Share immutable state (tokens, config) via scriptblock parameters
   - Collect results with `BeginInvoke()` and `EndInvoke()`
   - Dispose pools in `finally` blocks

8. **Use Idiomatic PowerShell** — Prefer cmdlet names over aliases (`Get-ChildItem` vs `ls`). Use proper object pipelines. Follow verb-noun naming conventions.

9. **Add Progress Reporting** — Use `Write-Host` for user-facing messages, `Write-Verbose` for diagnostic info, `Write-Progress` for long operations.

10. **Export Structured Logs** — Use `Export-Csv` with `-NoTypeInformation -Encoding UTF8` for result logs. Include timestamp, status, error details.

## Output

A production-ready PowerShell script following the template below.

```powershell
<#
.SYNOPSIS
    {{Brief description}}

.DESCRIPTION
    {{Detailed description including throttling, security, and performance notes}}

.PARAMETER ParameterName
    {{Parameter description}}

.EXAMPLE
    .\Script.ps1 -Param1 "value" -Confirm:$false
    {{What this example does}}
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $false)]
    [string]$TenantId = $env:TENANT_ID,
    
    [ValidateRange(1, 100)]
    [int]$BatchSize = 50
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Validate required environment variables
if ([string]::IsNullOrWhiteSpace($TenantId)) {
    throw 'TenantId is required. Pass -TenantId or set TENANT_ID environment variable.'
}

# Script logic with proper error handling
try {
    foreach ($item in $items) {
        if ($PSCmdlet.ShouldProcess($item, "Delete")) {
            # Destructive operation
        }
    }
}
catch {
    Write-Error "Operation failed: $_"
    throw
}
finally {
    # Cleanup
}
```

## Referenced Prompts
- `prompts/system/default_system.md`

## Referenced Tools
- `run_in_terminal` (PowerShell syntax validation with PSParser)

## Tags
`powershell`, `scripting`, `best-practices`, `automation`, `error-handling`
