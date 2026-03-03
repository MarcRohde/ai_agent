<#
.SYNOPSIS
    Generate a project-specific bootstrap script with hardcoded defaults.

.DESCRIPTION
    Creates a customized Bootstrap-DevEnvironment.ps1 wrapper for a specific project
    with environment variables pre-configured. Users can run the generated script
    without needing to specify variables manually.

.PARAMETER ProjectName
    Name of the project (used in script comments and filename).

.PARAMETER Variables
    Hashtable of environment variables with default values.

.PARAMETER OutputPath
    Path where the generated bootstrap script will be saved.

.PARAMETER DefaultScope
    Default persistence scope (User or Machine).

.EXAMPLE
    .\New-ProjectBootstrap.ps1 -ProjectName "MyProject" `
        -Variables @{API_KEY='default-key'; API_URL='https://api.example.com'} `
        -OutputPath ".\scripts\Initialize-MyProject.ps1"

.NOTES
    Author: AI Agent
    Date: 2026-03-02
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectName,

    [Parameter(Mandatory = $true)]
    [hashtable]$Variables,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [ValidateSet('User', 'Machine')]
    [string]$DefaultScope = 'User'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Build parameter definitions
$paramDefinitions = @()
foreach ($entry in $Variables.GetEnumerator()) {
    $paramDefinitions += @"
    [Parameter(Mandatory = `$false)]
    [string]`$$($entry.Key) = '$($entry.Value)'
"@
}

$paramBlock = $paramDefinitions -join ",`n`n"

# Build variables hashtable
$varHashtable = @()
foreach ($key in $Variables.Keys) {
    $varHashtable += "        $key = `$$key"
}
$varHashtableStr = $varHashtable -join "`n"

# Generate script content
$scriptContent = @"
<#
.SYNOPSIS
    Initialize development environment for $ProjectName.

.DESCRIPTION
    Sets required environment variables for $ProjectName development.
    This is a generated wrapper around Bootstrap-DevEnvironment.ps1.

.NOTES
    Auto-generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    Project: $ProjectName
#>

[CmdletBinding()]
param(
$paramBlock,

    [Parameter(Mandatory = `$false)]
    [ValidateSet('User', 'Machine')]
    [string]`$PersistScope = '$DefaultScope',

    [Parameter(Mandatory = `$false)]
    [switch]`$DoNotUpdateCurrentSession
)

Set-StrictMode -Version Latest
`$ErrorActionPreference = 'Stop'

Write-Host "$ProjectName Environment Bootstrap" -ForegroundColor Cyan
Write-Host ("=" * 60)
Write-Host ""

# Find the generic bootstrap script
`$bootstrapScript = Join-Path (Split-Path `$PSScriptRoot -Parent) "tools\scripts\Bootstrap-DevEnvironment.ps1"

if (-not (Test-Path `$bootstrapScript)) {
    # Try relative to ai_agent repo
    `$bootstrapScript = Join-Path `$PSScriptRoot "..\..\ai_agent\ai_agent\tools\scripts\Bootstrap-DevEnvironment.ps1"
}

if (-not (Test-Path `$bootstrapScript)) {
    Write-Error "Bootstrap-DevEnvironment.ps1 not found. Ensure ai_agent library is available."
    exit 1
}

# Build variables hashtable
`$variables = @{
$varHashtableStr
}

# Call the generic bootstrap script
& `$bootstrapScript ``
    -Variables `$variables ``
    -PersistScope `$PersistScope ``
    -DoNotUpdateCurrentSession:`$DoNotUpdateCurrentSession.IsPresent

exit `$LASTEXITCODE
"@

# Write the script
$outputDir = Split-Path $OutputPath -Parent
if ($outputDir -and -not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

Set-Content -Path $OutputPath -Value $scriptContent -Encoding UTF8

Write-Host "Project bootstrap script generated:" -ForegroundColor Green
Write-Host "  $OutputPath"
Write-Host ""
Write-Host "Usage:" -ForegroundColor Cyan
Write-Host "  .\$(Split-Path $OutputPath -Leaf)"
Write-Host "  .\$(Split-Path $OutputPath -Leaf) -PersistScope Machine"

foreach ($key in $Variables.Keys) {
    Write-Host "  .\$(Split-Path $OutputPath -Leaf) -$key '<custom-value>'"
}
<#
.SYNOPSIS
    Generate a project-specific bootstrap script with hardcoded defaults.

.DESCRIPTION
    Creates a customized Bootstrap-DevEnvironment.ps1 wrapper for a specific project
    with environment variables pre-configured. Users can run the generated script
    without needing to specify variables manually.

.PARAMETER ProjectName
    Name of the project (used in script comments and filename).

.PARAMETER Variables
    Hashtable of environment variables with default values.

.PARAMETER OutputPath
    Path where the generated bootstrap script will be saved.

.PARAMETER DefaultScope
    Default persistence scope (User or Machine).

.EXAMPLE
    .\New-ProjectBootstrap.ps1 -ProjectName "MyProject" `
        -Variables @{API_KEY='default-key'; API_URL='https://api.example.com'} `
        -OutputPath ".\scripts\Initialize-MyProject.ps1"

.NOTES
    Author: AI Agent
    Date: 2026-03-02
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectName,

    [Parameter(Mandatory = $true)]
    [hashtable]$Variables,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [ValidateSet('User', 'Machine')]
    [string]$DefaultScope = 'User'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Build parameter definitions
$paramDefinitions = @()
foreach ($entry in $Variables.GetEnumerator()) {
    $paramDefinitions += @"
    [Parameter(Mandatory = `$false)]
    [string]`$$($entry.Key) = '$($entry.Value)'
"@
}

$paramBlock = $paramDefinitions -join ",`n`n"

# Build variables hashtable
$varHashtable = @()
foreach ($key in $Variables.Keys) {
    $varHashtable += "        $key = `$$key"
}
$varHashtableStr = $varHashtable -join "`n"

# Generate script content
$scriptContent = @"
<#
.SYNOPSIS
    Initialize development environment for $ProjectName.

.DESCRIPTION
    Sets required environment variables for $ProjectName development.
    This is a generated wrapper around Bootstrap-DevEnvironment.ps1.

.NOTES
    Auto-generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    Project: $ProjectName
#>

[CmdletBinding()]
param(
$paramBlock,

    [Parameter(Mandatory = `$false)]
    [ValidateSet('User', 'Machine')]
    [string]`$PersistScope = '$DefaultScope',

    [Parameter(Mandatory = `$false)]
    [switch]`$DoNotUpdateCurrentSession
)

Set-StrictMode -Version Latest
`$ErrorActionPreference = 'Stop'

Write-Host "$ProjectName Environment Bootstrap" -ForegroundColor Cyan
Write-Host ("=" * 60)
Write-Host ""

# Find the generic bootstrap script
`$bootstrapScript = Join-Path (Split-Path `$PSScriptRoot -Parent) "tools\scripts\Bootstrap-DevEnvironment.ps1"

if (-not (Test-Path `$bootstrapScript)) {
    # Try relative to ai_agent repo
    `$bootstrapScript = Join-Path `$PSScriptRoot "..\..\ai_agent\ai_agent\tools\scripts\Bootstrap-DevEnvironment.ps1"
}

if (-not (Test-Path `$bootstrapScript)) {
    Write-Error "Bootstrap-DevEnvironment.ps1 not found. Ensure ai_agent library is available."
    exit 1
}

# Build variables hashtable
`$variables = @{
$varHashtableStr
}

# Call the generic bootstrap script
& `$bootstrapScript ``
    -Variables `$variables ``
    -PersistScope `$PersistScope ``
    -DoNotUpdateCurrentSession:`$DoNotUpdateCurrentSession.IsPresent

exit `$LASTEXITCODE
"@

# Write the script
$outputDir = Split-Path $OutputPath -Parent
if ($outputDir -and -not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

Set-Content -Path $OutputPath -Value $scriptContent -Encoding UTF8

Write-Host "Project bootstrap script generated:" -ForegroundColor Green
Write-Host "  $OutputPath"
Write-Host ""
Write-Host "Usage:" -ForegroundColor Cyan
Write-Host "  .\$(Split-Path $OutputPath -Leaf)"
Write-Host "  .\$(Split-Path $OutputPath -Leaf) -PersistScope Machine"

foreach ($key in $Variables.Keys) {
    Write-Host "  .\$(Split-Path $OutputPath -Leaf) -$key '<custom-value>'"
}
