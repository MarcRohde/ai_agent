# Skill: Dev Environment Bootstrap

## Description
Create portable bootstrap scripts that configure new development environments with required environment variables, tool installations, configuration files, and credential setup. Ensure consistency across team members and new machine setups.

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| `environment_type` | Yes | Type of environment (e.g., PowerShell, Python, Node.js, .NET) |
| `required_env_vars` | Yes | List of environment variables with default values (mask secrets) |
| `required_tools` | No | Tools/packages to validate or install |
| `config_files` | No | Configuration files to create/update (e.g., .gitconfig, profiles) |
| `persist_scope` | No | Environment variable scope (User, Machine) - default: User |

## Steps

1. **Identify Required Configuration** — List all environment variables, tools, credentials, and config files needed for the development workflow.
    - For integrations with compatibility layers, identify both canonical variable names and alias names that downstream tools still expect.

2. **Create Bootstrap Script** — Build a parameterized script that:
   - Sets environment variables at User or Machine scope
   - Updates current session variables immediately (optional flag)
    - Writes compatibility aliases in the same run when multiple scripts depend on different env var prefixes
   - Validates prerequisites (e.g., PowerShell version, OS type)
   - Checks for admin rights when Machine scope is required
    - Chains into a subsystem-specific bootstrap when the environment includes a portable MCP stack such as Work IQ
    - Resolves required values from `Process`, `User`, and `Machine` scope when starting dependent auth helpers

3. **Add Validation Function** — Create a companion validation script that checks environment readiness:
   - Verify all required env vars are set
   - Check tool installations and versions
   - Test connectivity to required services
   - Display pass/fail report
    - Distinguish configuration readiness from auth readiness; an env var or cached token can exist while endpoint authorization still fails
    - For Work IQ, run token refresh and then `Test-WorkIQAllMcp.ps1 -SkipToolCall` to detect `401` failures before task execution

4. **Document Usage** — Include clear instructions:
   - How to run on a new machine
   - What credentials need manual setup
   - How to verify successful configuration
   - Where to get tenant IDs, client IDs, API keys
    - Which canonical env vars and compatibility aliases are written by bootstrap

5. **Secure Credential Handling** — For secrets that can't be in the script:
   - Document manual steps (Azure Key Vault, Windows Credential Manager)
   - Provide placeholders with clear error messages
   - Never commit actual secrets to version control

6. **Capture Canonical Config Sources** — When a subsystem can regenerate local config files from a repo catalog or manifest:
    - Treat the catalog as the source of truth
    - Regenerate local config from the catalog instead of hand-editing generated files

7. **Add to Repository Documentation** — Update project README with:
   - "Getting Started" section referencing bootstrap script
   - Prerequisites checklist
   - Troubleshooting common setup issues

## Output

Two scripts: a bootstrap script for setup and a validation script for verification.

### Bootstrap Script (PowerShell Example)

```powershell
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$TenantId = '<your-tenant-id>',

    [ValidateSet('User', 'Machine')]
    [string]$PersistScope = 'User',

    [switch]$DoNotUpdateCurrentSession
)

# Validate prerequisites
if ($PersistScope -eq 'Machine' -and -not (Test-IsAdmin)) {
    throw 'Machine scope requires Administrator privileges'
}

# Set environment variables
[Environment]::SetEnvironmentVariable('TENANT_ID', $TenantId, $PersistScope)

if (-not $DoNotUpdateCurrentSession) {
    $env:TENANT_ID = $TenantId
}

Write-Host "Environment configured successfully" -ForegroundColor Green
```

### Validation Script

```powershell
[CmdletBinding()]
param()

$checks = @()

# Check environment variables
$checks += [PSCustomObject]@{
    Check = 'TENANT_ID set'
    Status = if ($env:TENANT_ID) { 'PASS' } else { 'FAIL' }
}

# Display results
$checks | Format-Table -AutoSize

$failed = $checks | Where-Object { $_.Status -eq 'FAIL' }
if ($failed) {
    Write-Host "Environment validation failed. Run Initialize-DevEnvironment.ps1" -ForegroundColor Red
    exit 1
}

Write-Host "Environment validated successfully" -ForegroundColor Green
```

## Referenced Prompts
- `prompts/system/default_system.md`

## Referenced Tools
- `run_in_terminal` (execute bootstrap and validation scripts)
- `tools/scripts/Bootstrap-DevEnvironment.ps1`
- `tools/scripts/Bootstrap-WorkIQEnvironment.ps1`

## Tags
`devops`, `environment-setup`, `configuration`, `automation`, `onboarding`
