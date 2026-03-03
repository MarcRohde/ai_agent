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

2. **Create Bootstrap Script** — Build a parameterized script that:
   - Sets environment variables at User or Machine scope
   - Updates current session variables immediately (optional flag)
   - Validates prerequisites (e.g., PowerShell version, OS type)
   - Checks for admin rights when Machine scope is required

3. **Add Validation Function** — Create a companion validation script that checks environment readiness:
   - Verify all required env vars are set
   - Check tool installations and versions
   - Test connectivity to required services
   - Display pass/fail report

4. **Document Usage** — Include clear instructions:
   - How to run on a new machine
   - What credentials need manual setup
   - How to verify successful configuration
   - Where to get tenant IDs, client IDs, API keys

5. **Secure Credential Handling** — For secrets that can't be in the script:
   - Document manual steps (Azure Key Vault, Windows Credential Manager)
   - Provide placeholders with clear error messages
   - Never commit actual secrets to version control

6. **Add to Repository Documentation** — Update project README with:
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

## Tags
`devops`, `environment-setup`, `configuration`, `automation`, `onboarding`
